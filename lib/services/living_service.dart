import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oxy/models/service_provider.dart';
import 'package:oxy/models/community_post.dart';
import 'package:oxy/models/order.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for managing Living feature data (service providers, community, etc.)
class LivingService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  // User's current location
  double? _userLatitude;
  double? _userLongitude;
  String? _userLocationText;
  
  // Cached data
  List<ServiceProvider> _nearbyProviders = [];
  List<ServiceProvider> _featuredProviders = [];
  List<CommunityPost> _communityPosts = [];
  Map<ServiceCategory, List<ServiceProvider>> _providersByCategory = {};
  
  // Orders
  List<Order> _customerOrders = [];
  List<Order> _providerOrders = [];
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _customerOrdersChannel;
  
  // Cart (local state, grouped by provider)
  final Map<String, List<CartItem>> _cart = {};
  
  // Delivery settings
  UserDeliverySettings? _deliverySettings;
  
  // Service provider profile (if user is a provider)
  ServiceProvider? _myProvider;
  List<ServiceListing> _myListings = [];
  
  // Saved providers
  Set<String> _savedProviderIds = {};
  
  // Loading states
  bool _isLoadingProviders = false;
  bool _isLoadingPosts = false;
  bool _isLoadingLocation = false;
  
  // Realtime subscriptions
  RealtimeChannel? _likesChannel;
  
  // Getters
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String? get userLocationText => _userLocationText;
  bool get hasLocation => _userLatitude != null && _userLongitude != null;
  
  List<ServiceProvider> get nearbyProviders => _nearbyProviders;
  List<ServiceProvider> get featuredProviders => _featuredProviders;
  List<CommunityPost> get communityPosts => _communityPosts;
  Map<ServiceCategory, List<ServiceProvider>> get providersByCategory => _providersByCategory;
  
  ServiceProvider? get myProvider => _myProvider;
  List<ServiceListing> get myListings => _myListings;
  bool get isServiceProvider => _myProvider != null;
  
  Set<String> get savedProviderIds => _savedProviderIds;
  
  bool get isLoadingProviders => _isLoadingProviders;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingLocation => _isLoadingLocation;

  String get userId => _supabase.auth.currentUser?.id ?? '';
  
  // Orders getters
  List<Order> get customerOrders => _customerOrders;
  List<Order> get providerOrders => _providerOrders;
  UserDeliverySettings? get deliverySettings => _deliverySettings;
  
  // Cart getters
  Map<String, List<CartItem>> get cart => _cart;
  bool get hasItemsInCart => _cart.values.any((items) => items.isNotEmpty);
  int get totalCartItems => _cart.values.fold(0, (sum, items) => sum + items.fold(0, (s, i) => s + i.quantity));
  double get cartSubtotal => _cart.values.fold(0.0, (sum, items) => sum + items.fold(0.0, (s, i) => s + i.totalPrice));
  List<String> get cartProviderIds => _cart.keys.where((k) => _cart[k]!.isNotEmpty).toList();

  /// Initialize the service
  Future<void> initialize() async {
    await _loadSavedProviders();
    await _loadMyProviderProfile();
    
    // Try to get location, but don't block on failure
    final hasLoc = await requestLocation();
    
    // Always load data even without location (uses fallback queries)
    if (!hasLoc) {
      await loadAllProviders();
      await loadCommunityPosts();
    }
    
    _setupRealtimeSubscriptions();
  }
  
  void _setupRealtimeSubscriptions() {
    // Subscribe to likes changes for realtime updates
    _likesChannel = _supabase
        .channel('community_likes_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_likes',
          callback: (payload) => _handleLikeChange(payload),
        )
        .subscribe();
  }
  
  void _handleLikeChange(PostgresChangePayload payload) {
    final postId = payload.newRecord['post_id'] as String? ??
        payload.oldRecord['post_id'] as String?;
    if (postId == null) return;
    
    final index = _communityPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    
    // Reload reactions for this post
    _refreshPostReactions(postId);
  }
  
  Future<void> _refreshPostReactions(String postId) async {
    final index = _communityPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    
    try {
      // Get updated reaction counts
      final countsResponse = await _supabase
          .from('community_likes')
          .select('reaction')
          .eq('post_id', postId);
      
      final counts = <ReactionType, int>{};
      for (final row in countsResponse as List) {
        final reaction = ReactionType.fromValue(row['reaction'] as String? ?? 'like');
        counts[reaction] = (counts[reaction] ?? 0) + 1;
      }
      
      // Get user's reaction
      final userReactionResponse = await _supabase
          .from('community_likes')
          .select('reaction')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      
      final myReaction = userReactionResponse != null
          ? ReactionType.fromValue(userReactionResponse['reaction'] as String? ?? 'like')
          : null;
      
      final totalReactions = counts.values.fold(0, (a, b) => a + b);
      
      _communityPosts[index] = _communityPosts[index].copyWith(
        myReaction: myReaction,
        clearMyReaction: myReaction == null,
        reactionCounts: counts,
        likesCount: totalReactions,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing post reactions: $e');
    }
  }
  
  @override
  void dispose() {
    _likesChannel?.unsubscribe();
    super.dispose();
  }

  /// Request and update user's location
  Future<bool> requestLocation() async {
    _isLoadingLocation = true;
    notifyListeners();
    
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      _userLatitude = position.latitude;
      _userLongitude = position.longitude;
      
      // Get locality name from coordinates
      await _reverseGeocodeLocation(position.latitude, position.longitude);
      
      // Update profile with location
      await _updateProfileLocation();
      
      // Load nearby data
      await loadNearbyProviders();
      await loadCommunityPosts();
      
      return true;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Reverse geocode coordinates to get locality name
  /// Returns formatted location: most specific → least specific (e.g., "Westlands, Nairobi, Nairobi County")
  Future<void> _reverseGeocodeLocation(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        
        // Build from most specific to least specific
        // Sublocality (neighborhood/area) - most specific
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          parts.add(p.subLocality!);
        }
        
        // Locality (city)
        if (p.locality != null && p.locality!.isNotEmpty) {
          // Only add if different from what we already have
          if (parts.isEmpty || parts.last != p.locality) {
            parts.add(p.locality!);
          }
        }
        
        // Administrative area (state/county) - least specific
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          if (parts.isEmpty || parts.last != p.administrativeArea) {
            parts.add(p.administrativeArea!);
          }
        }
        
        _userLocationText = parts.isNotEmpty ? parts.join(', ') : null;
        debugPrint('Reverse geocoded location: $_userLocationText');
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      // Don't fail the whole location request if geocoding fails
      _userLocationText = null;
    }
  }

  /// Set location manually (for testing or manual entry)
  Future<void> setLocation(double latitude, double longitude, {String? locationText}) async {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _userLocationText = locationText;
    
    await _updateProfileLocation();
    await loadNearbyProviders();
    await loadCommunityPosts();
  }

  Future<void> _updateProfileLocation() async {
    if (!hasLocation) return;
    
    try {
      await _supabase.from('profiles').update({
        'latitude': _userLatitude,
        'longitude': _userLongitude,
        'location_text': _userLocationText,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating profile location: $e');
    }
  }

  /// Load nearby service providers
  Future<void> loadNearbyProviders({
    double radiusKm = 10,
    ServiceCategory? category,
    int limit = 50,
  }) async {
    if (!hasLocation) {
      debugPrint('No location available for nearby search');
      return;
    }
    
    _isLoadingProviders = true;
    notifyListeners();
    
    try {
      final response = await _supabase.rpc(
        'get_nearby_providers',
        params: {
          'p_user_lat': _userLatitude,
          'p_user_lng': _userLongitude,
          'p_radius_km': radiusKm,
          'p_category_filter': category?.value,
          'p_limit_count': limit,
        },
      );
      
      _nearbyProviders = (response as List)
          .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Separate featured
      _featuredProviders = _nearbyProviders.where((p) => p.isFeatured).toList();
      
      // Group by category
      _providersByCategory = {};
      for (final provider in _nearbyProviders) {
        _providersByCategory[provider.category] ??= [];
        _providersByCategory[provider.category]!.add(provider);
      }
    } catch (e) {
      debugPrint('Error loading nearby providers: $e');
    } finally {
      _isLoadingProviders = false;
      notifyListeners();
    }
  }

  /// Load all active service providers (no location required)
  Future<void> loadAllProviders({
    ServiceCategory? category,
    int limit = 50,
  }) async {
    _isLoadingProviders = true;
    notifyListeners();
    
    try {
      var query = _supabase
          .from('service_providers')
          .select()
          .eq('status', 'active');
      
      if (category != null) {
        query = query.eq('category', category.value);
      }
      
      final response = await query
          .order('is_featured', ascending: false)
          .order('rating_average', ascending: false)
          .limit(limit);
      
      _nearbyProviders = (response as List)
          .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Separate featured
      _featuredProviders = _nearbyProviders.where((p) => p.isFeatured).toList();
      
      // Group by category
      _providersByCategory = {};
      for (final provider in _nearbyProviders) {
        _providersByCategory[provider.category] ??= [];
        _providersByCategory[provider.category]!.add(provider);
      }
    } catch (e) {
      debugPrint('Error loading all providers: $e');
    } finally {
      _isLoadingProviders = false;
      notifyListeners();
    }
  }

  /// Load providers by category
  Future<List<ServiceProvider>> loadProvidersByCategory(
    ServiceCategory category, {
    double radiusKm = 20,
    int limit = 100,
  }) async {
    if (!hasLocation) return [];
    
    try {
      final response = await _supabase.rpc(
        'get_nearby_providers',
        params: {
          'p_user_lat': _userLatitude,
          'p_user_lng': _userLongitude,
          'p_radius_km': radiusKm,
          'p_category_filter': category.value,
          'p_limit_count': limit,
        },
      );
      
      return (response as List)
          .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading providers by category: $e');
      return [];
    }
  }

  /// Search providers
  Future<List<ServiceProvider>> searchProviders(String query) async {
    try {
      final response = await _supabase
          .from('service_providers')
          .select()
          .eq('status', 'active')
          .or('business_name.ilike.%$query%,business_description.ilike.%$query%,tags.cs.{$query}')
          .limit(50);
      
      return (response as List)
          .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching providers: $e');
      return [];
    }
  }

  /// Get provider details
  Future<ServiceProvider?> getProviderDetails(String providerId) async {
    try {
      final response = await _supabase
          .from('service_providers')
          .select()
          .eq('id', providerId)
          .single();
      
      return ServiceProvider.fromJson(response);
    } catch (e) {
      debugPrint('Error getting provider details: $e');
      return null;
    }
  }

  /// Get provider listings
  Future<List<ServiceListing>> getProviderListings(String providerId) async {
    try {
      final response = await _supabase
          .from('service_listings')
          .select()
          .eq('provider_id', providerId)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => ServiceListing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting provider listings: $e');
      return [];
    }
  }

  /// Get provider reviews
  Future<List<ServiceReview>> getProviderReviews(String providerId) async {
    try {
      final response = await _supabase
          .from('service_reviews')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => ServiceReview.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting provider reviews: $e');
      return [];
    }
  }

  /// Submit a review
  Future<void> submitReview({
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    await _supabase.from('service_reviews').upsert({
      'provider_id': providerId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'provider_id,user_id');
  }

  // ============================================
  // SAVED PROVIDERS
  // ============================================

  Future<void> _loadSavedProviders() async {
    try {
      final response = await _supabase
          .from('saved_providers')
          .select('provider_id')
          .eq('user_id', userId);
      
      _savedProviderIds = (response as List)
          .map((r) => r['provider_id'] as String)
          .toSet();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved providers: $e');
    }
  }

  bool isProviderSaved(String providerId) => _savedProviderIds.contains(providerId);

  Future<void> toggleSaveProvider(String providerId) async {
    try {
      if (isProviderSaved(providerId)) {
        await _supabase
            .from('saved_providers')
            .delete()
            .eq('user_id', userId)
            .eq('provider_id', providerId);
        _savedProviderIds.remove(providerId);
      } else {
        await _supabase.from('saved_providers').insert({
          'user_id': userId,
          'provider_id': providerId,
        });
        _savedProviderIds.add(providerId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling saved provider: $e');
    }
  }

  Future<List<ServiceProvider>> getSavedProviders() async {
    if (_savedProviderIds.isEmpty) return [];
    
    try {
      final response = await _supabase
          .from('service_providers')
          .select()
          .inFilter('id', _savedProviderIds.toList());
      
      return (response as List)
          .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting saved providers: $e');
      return [];
    }
  }

  // ============================================
  // COMMUNITY POSTS
  // ============================================

  /// Load community posts
  Future<void> loadCommunityPosts({
    double radiusKm = 10,
    CommunityPostType? postType,
    int limit = 50,
  }) async {
    _isLoadingPosts = true;
    notifyListeners();
    
    try {
      List<dynamic> response;
      
      if (hasLocation) {
        response = await _supabase.rpc(
          'get_nearby_posts',
          params: {
            'p_user_lat': _userLatitude,
            'p_user_lng': _userLongitude,
            'p_radius_km': radiusKm,
            'p_post_type_filter': postType?.value,
            'p_limit_count': limit,
          },
        );
      } else {
        // Fallback to regular query if no location
        var query = _supabase
            .from('community_posts')
            .select()
            .eq('is_hidden', false);
        
        if (postType != null) {
          query = query.eq('post_type', postType.value);
        }
        
        final rawResponse = await query
            .order('is_pinned', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit);
        
        // Fetch profile info for post authors
        final userIds = (rawResponse as List)
            .map((r) => r['user_id'] as String)
            .toSet()
            .toList();
        
        final profilesResponse = userIds.isNotEmpty
            ? await _supabase
                .from('profiles')
                .select('id, full_name, avatar_url')
                .inFilter('id', userIds)
            : [];
        
        final profilesMap = <String, Map<String, dynamic>>{
          for (final p in profilesResponse)
            p['id'] as String: p
        };
        
        // Transform to match RPC response format
        response = rawResponse.map((row) {
          final profile = profilesMap[row['user_id']];
          return <String, dynamic>{
            ...row,
            'user_name': profile?['full_name'],
            'user_avatar_url': profile?['avatar_url'],
          };
        }).toList();
      }
      
      // Get user's likes
      // Get user's reactions and all reaction counts
      final userReactions = await _getUserReactions();
      final reactionCounts = await _getPostReactionCounts(
        response.map((j) => j['id'] as String).toList(),
      );
      
      _communityPosts = response
          .map((json) {
            final postId = json['id'] as String;
            return CommunityPost.fromJson(
              json as Map<String, dynamic>,
              myReaction: userReactions[postId],
              reactionCounts: reactionCounts[postId] ?? {},
            );
          })
          .toList();
    } catch (e) {
      debugPrint('Error loading community posts: $e');
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<Map<String, ReactionType>> _getUserReactions() async {
    try {
      final response = await _supabase
          .from('community_likes')
          .select('post_id, reaction')
          .eq('user_id', userId)
          .not('post_id', 'is', null);
      
      return Map.fromEntries(
        (response as List).map((r) => MapEntry(
          r['post_id'] as String,
          ReactionType.fromValue(r['reaction'] as String? ?? 'like'),
        )),
      );
    } catch (e) {
      return {};
    }
  }
  
  Future<Map<String, Map<ReactionType, int>>> _getPostReactionCounts(List<String> postIds) async {
    if (postIds.isEmpty) return {};
    
    try {
      final response = await _supabase
          .from('community_likes')
          .select('post_id, reaction')
          .inFilter('post_id', postIds);
      
      final counts = <String, Map<ReactionType, int>>{};
      for (final row in response as List) {
        final postId = row['post_id'] as String;
        final reaction = ReactionType.fromValue(row['reaction'] as String? ?? 'like');
        counts.putIfAbsent(postId, () => {});
        counts[postId]![reaction] = (counts[postId]![reaction] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      return {};
    }
  }

  /// Create a community post
  Future<CommunityPost?> createPost({
    required CommunityPostType postType,
    String? title,
    required String content,
    List<String>? imageUrls,
    DateTime? eventDate,
    DateTime? eventEndDate,
    String? eventLocation,
  }) async {
    try {
      // Get current user's profile for the post
      final profile = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      final data = {
        'user_id': userId,
        'post_type': postType.value,
        'title': title,
        'content': content,
        'images': imageUrls?.map((url) => {'url': url}).toList() ?? [],
        'latitude': _userLatitude,
        'longitude': _userLongitude,
        'location_text': _userLocationText,
        'event_date': eventDate?.toIso8601String(),
        'event_end_date': eventEndDate?.toIso8601String(),
        'event_location': eventLocation,
      };
      
      final response = await _supabase
          .from('community_posts')
          .insert(data)
          .select()
          .single();
      
      // Add profile data to response for proper parsing
      final postData = {
        ...response,
        'user_name': profile?['full_name'],
        'user_avatar_url': profile?['avatar_url'],
      };
      
      final post = CommunityPost.fromJson(postData);
      _communityPosts.insert(0, post);
      notifyListeners();
      
      return post;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  /// Like/unlike a post
  /// React to a post. If already reacted with same type, removes reaction.
  /// If reacted with different type, updates to new type.
  Future<void> reactToPost(String postId, ReactionType reaction) async {
    final index = _communityPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    
    final post = _communityPosts[index];
    final currentReaction = post.myReaction;
    
    try {
      if (currentReaction == reaction) {
        // Remove reaction
        await _supabase
            .from('community_likes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
        
        final newCounts = Map<ReactionType, int>.from(post.reactionCounts);
        newCounts[reaction] = (newCounts[reaction] ?? 1) - 1;
        if (newCounts[reaction] == 0) newCounts.remove(reaction);
        
        _communityPosts[index] = post.copyWith(
          clearMyReaction: true,
          likesCount: post.likesCount - 1,
          reactionCounts: newCounts,
        );
      } else if (currentReaction != null) {
        // Change reaction type
        await _supabase
            .from('community_likes')
            .update({'reaction': reaction.value})
            .eq('user_id', userId)
            .eq('post_id', postId);
        
        final newCounts = Map<ReactionType, int>.from(post.reactionCounts);
        newCounts[currentReaction] = (newCounts[currentReaction] ?? 1) - 1;
        if (newCounts[currentReaction] == 0) newCounts.remove(currentReaction);
        newCounts[reaction] = (newCounts[reaction] ?? 0) + 1;
        
        _communityPosts[index] = post.copyWith(
          myReaction: reaction,
          reactionCounts: newCounts,
        );
      } else {
        // Add new reaction
        await _supabase.from('community_likes').insert({
          'user_id': userId,
          'post_id': postId,
          'reaction': reaction.value,
        });
        
        final newCounts = Map<ReactionType, int>.from(post.reactionCounts);
        newCounts[reaction] = (newCounts[reaction] ?? 0) + 1;
        
        _communityPosts[index] = post.copyWith(
          myReaction: reaction,
          likesCount: post.likesCount + 1,
          reactionCounts: newCounts,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error reacting to post: $e');
    }
  }
  
  /// Quick like (default reaction)
  Future<void> togglePostLike(String postId) async {
    final index = _communityPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    
    final post = _communityPosts[index];
    if (post.myReaction != null) {
      // Remove any reaction
      await reactToPost(postId, post.myReaction!);
    } else {
      // Add like reaction
      await reactToPost(postId, ReactionType.like);
    }
  }

  /// Get comments for a post
  Future<List<CommunityComment>> getPostComments(String postId) async {
    try {
      final response = await _supabase
          .from('community_comments')
          .select()
          .eq('post_id', postId)
          .isFilter('parent_id', null) // Top-level comments only
          .order('created_at', ascending: true);
      
      final comments = response as List;
      if (comments.isEmpty) return [];
      
      // Get unique user IDs
      final userIds = comments.map((c) => c['user_id'] as String).toSet().toList();
      
      // Fetch profiles for all comment authors
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds);
      
      final profiles = Map<String, Map<String, dynamic>>.fromEntries(
        (profilesResponse as List).map((p) => MapEntry(p['id'] as String, p as Map<String, dynamic>)),
      );
      
      return comments.map((json) {
        final commentUserId = json['user_id'] as String;
        final profile = profiles[commentUserId];
        return CommunityComment.fromJson({
          ...json as Map<String, dynamic>,
          'profiles': profile,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting post comments: $e');
      return [];
    }
  }

  /// Add a comment to a post
  Future<CommunityComment?> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      // Get current user's profile for the comment
      final profile = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      final response = await _supabase
          .from('community_comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
            'parent_id': parentId,
          })
          .select()
          .single();
      
      // Update comment count in local list
      final postIndex = _communityPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _communityPosts[postIndex] = _communityPosts[postIndex].copyWith(
          commentsCount: _communityPosts[postIndex].commentsCount + 1,
        );
        notifyListeners();
      }
      
      // Add profile data to response for proper parsing
      final commentData = {
        ...response,
        'profiles': profile,
      };
      
      return CommunityComment.fromJson(commentData);
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  // ============================================
  // SERVICE PROVIDER PROFILE MANAGEMENT
  // ============================================

  Future<void> _loadMyProviderProfile() async {
    try {
      final response = await _supabase
          .from('service_providers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        _myProvider = ServiceProvider.fromJson(response);
        await _loadMyListings();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading my provider profile: $e');
    }
  }

  Future<void> _loadMyListings() async {
    if (_myProvider == null) return;
    
    try {
      final response = await _supabase
          .from('service_listings')
          .select()
          .eq('provider_id', _myProvider!.id)
          .order('created_at', ascending: false);
      
      _myListings = (response as List)
          .map((json) => ServiceListing.fromJson(json as Map<String, dynamic>))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading my listings: $e');
    }
  }

  /// Register as a service provider
  Future<ServiceProvider?> registerAsProvider({
    required String businessName,
    String? businessDescription,
    required ServiceCategory category,
    required String phone,
    String? email,
    String? website,
    String? whatsapp,
    required String locationText,
    double? latitude,
    double? longitude,
    List<String>? features,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'business_name': businessName,
        'business_description': businessDescription,
        'category': category.value,
        'phone': phone,
        'email': email,
        'website': website,
        'whatsapp': whatsapp,
        'location_text': locationText,
        'latitude': latitude ?? _userLatitude,
        'longitude': longitude ?? _userLongitude,
        'features': features ?? [],
        'status': 'active', // Auto-approve for now
      };
      
      final response = await _supabase
          .from('service_providers')
          .insert(data)
          .select()
          .single();
      
      _myProvider = ServiceProvider.fromJson(response);
      notifyListeners();
      
      return _myProvider;
    } catch (e) {
      debugPrint('Error registering as provider: $e');
      return null;
    }
  }

  /// Update service provider profile
  Future<void> updateProviderProfile(ServiceProvider provider) async {
    try {
      await _supabase
          .from('service_providers')
          .update(provider.toJson()..['updated_at'] = DateTime.now().toIso8601String())
          .eq('id', provider.id);
      
      _myProvider = provider;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating provider profile: $e');
      rethrow;
    }
  }

  /// Add a service listing
  Future<ServiceListing?> addListing({
    required String title,
    String? description,
    double? price,
    String? priceUnit,
    List<String>? imageUrls,
  }) async {
    if (_myProvider == null) return null;
    
    try {
      final data = {
        'provider_id': _myProvider!.id,
        'title': title,
        'description': description,
        'price': price,
        'price_unit': priceUnit,
        'images': imageUrls?.map((url) => {'url': url}).toList() ?? [],
      };
      
      final response = await _supabase
          .from('service_listings')
          .insert(data)
          .select()
          .single();
      
      final listing = ServiceListing.fromJson(response);
      _myListings.insert(0, listing);
      notifyListeners();
      
      return listing;
    } catch (e) {
      debugPrint('Error adding listing: $e');
      return null;
    }
  }

  /// Update a listing
  Future<void> updateListing(ServiceListing listing) async {
    try {
      await _supabase
          .from('service_listings')
          .update(listing.toJson()..['updated_at'] = DateTime.now().toIso8601String())
          .eq('id', listing.id);
      
      final index = _myListings.indexWhere((l) => l.id == listing.id);
      if (index != -1) {
        _myListings[index] = listing;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating listing: $e');
      rethrow;
    }
  }

  /// Delete a listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _supabase.from('service_listings').delete().eq('id', listingId);
      _myListings.removeWhere((l) => l.id == listingId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting listing: $e');
      rethrow;
    }
  }

  /// Respond to a review
  Future<void> respondToReview(String reviewId, String response) async {
    try {
      await _supabase.from('service_reviews').update({
        'provider_response': response,
        'provider_response_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
    } catch (e) {
      debugPrint('Error responding to review: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CART MANAGEMENT
  // ============================================================================

  /// Add item to cart
  void addToCart(CartItem item) {
    _cart[item.providerId] ??= [];
    
    // Check if item already exists
    final existingIndex = _cart[item.providerId]!.indexWhere(
      (i) => i.listingId == item.listingId,
    );
    
    if (existingIndex != -1) {
      _cart[item.providerId]![existingIndex].quantity += item.quantity;
    } else {
      _cart[item.providerId]!.add(item);
    }
    
    notifyListeners();
  }

  /// Update cart item quantity
  void updateCartItemQuantity(String providerId, String listingId, int quantity) {
    final items = _cart[providerId];
    if (items == null) return;
    
    final index = items.indexWhere((i) => i.listingId == listingId);
    if (index == -1) return;
    
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index].quantity = quantity;
    }
    
    // Clean up empty provider carts
    if (items.isEmpty) {
      _cart.remove(providerId);
    }
    
    notifyListeners();
  }

  /// Remove item from cart
  void removeFromCart(String providerId, String listingId) {
    _cart[providerId]?.removeWhere((i) => i.listingId == listingId);
    if (_cart[providerId]?.isEmpty ?? false) {
      _cart.remove(providerId);
    }
    notifyListeners();
  }

  /// Clear cart for a provider
  void clearProviderCart(String providerId) {
    _cart.remove(providerId);
    notifyListeners();
  }

  /// Clear entire cart
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Get cart items for a specific provider
  List<CartItem> getProviderCart(String providerId) {
    return _cart[providerId] ?? [];
  }

  /// Get cart subtotal for a provider
  double getProviderCartSubtotal(String providerId) {
    final items = _cart[providerId];
    if (items == null || items.isEmpty) return 0.0;
    return items.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
  }

  // ============================================================================
  // DELIVERY SETTINGS
  // ============================================================================

  /// Load user's delivery settings
  Future<void> loadDeliverySettings() async {
    try {
      final response = await _supabase
          .from('user_delivery_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        _deliverySettings = UserDeliverySettings.fromJson(response);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading delivery settings: $e');
    }
  }

  /// Save/update delivery settings
  Future<void> saveDeliverySettings({
    required String name,
    required String phone,
    String? address,
    String? apartment,
    String? unit,
    String? instructions,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'default_name': name,
        'default_phone': phone,
        'default_address': address,
        'default_apartment': apartment,
        'default_unit': unit,
        'default_instructions': instructions,
        'latitude': latitude ?? _userLatitude,
        'longitude': longitude ?? _userLongitude,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from('user_delivery_settings')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();
      
      _deliverySettings = UserDeliverySettings.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving delivery settings: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ORDERS - CUSTOMER
  // ============================================================================

  /// Place an order
  Future<Order?> placeOrder({
    required String providerId,
    required List<CartItem> items,
    required DeliveryType deliveryType,
    required String deliveryName,
    required String deliveryPhone,
    String? deliveryAddress,
    String? deliveryApartment,
    String? deliveryUnit,
    String? deliveryInstructions,
    String? customerNotes,
    DateTime? requestedTime,
    double? deliveryLatitude,
    double? deliveryLongitude,
  }) async {
    try {
      final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final deliveryFee = deliveryType == DeliveryType.delivery ? 100.0 : 0.0; // Default delivery fee
      
      final orderData = {
        'customer_id': userId,
        'provider_id': providerId,
        'items': items.map((i) => i.toOrderItem().toJson()).toList(),
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total_amount': subtotal + deliveryFee,
        'delivery_type': deliveryType.value,
        'delivery_name': deliveryName,
        'delivery_phone': deliveryPhone,
        'delivery_address': deliveryAddress,
        'delivery_apartment': deliveryApartment,
        'delivery_unit': deliveryUnit,
        'delivery_instructions': deliveryInstructions,
        'delivery_latitude': deliveryLatitude ?? _userLatitude,
        'delivery_longitude': deliveryLongitude ?? _userLongitude,
        'customer_notes': customerNotes,
        'requested_time': requestedTime?.toIso8601String(),
      };
      
      final response = await _supabase
          .from('orders')
          .insert(orderData)
          .select('*, service_providers(business_name, logo_url)')
          .single();
      
      final order = Order.fromJson(response);
      _customerOrders.insert(0, order);
      
      // Clear the cart for this provider
      clearProviderCart(providerId);
      
      notifyListeners();
      return order;
    } catch (e) {
      debugPrint('Error placing order: $e');
      rethrow;
    }
  }

  /// Load customer's orders
  Future<void> loadCustomerOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, service_providers(business_name, logo_url)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      
      _customerOrders = (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading customer orders: $e');
    }
  }

  /// Cancel order (customer)
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _supabase.from('orders').update({
        'status': 'cancelled',
        'cancellation_reason': reason ?? 'Cancelled by customer',
      }).eq('id', orderId).eq('customer_id', userId);
      
      final index = _customerOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _customerOrders[index] = _customerOrders[index].copyWith(
          status: OrderStatus.cancelled,
          cancellationReason: reason ?? 'Cancelled by customer',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ORDERS - PROVIDER
  // ============================================================================

  /// Load provider's orders
  Future<void> loadProviderOrders() async {
    if (_myProvider == null) return;
    
    try {
      final response = await _supabase
          .from('orders')
          .select('*, profiles:customer_id(full_name)')
          .eq('provider_id', _myProvider!.id)
          .order('created_at', ascending: false);
      
      _providerOrders = (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading provider orders: $e');
    }
  }

  /// Update order status (provider)
  Future<void> updateOrderStatus(String orderId, OrderStatus status, {String? notes}) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.value,
      };
      
      if (notes != null) {
        updateData['provider_notes'] = notes;
      }
      
      await _supabase.from('orders').update(updateData).eq('id', orderId);
      
      final index = _providerOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _providerOrders[index] = _providerOrders[index].copyWith(
          status: status,
          providerNotes: notes ?? _providerOrders[index].providerNotes,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  /// Setup realtime subscription for provider orders
  void setupProviderOrdersRealtime() {
    if (_myProvider == null) return;
    
    _ordersChannel?.unsubscribe();
    _ordersChannel = _supabase
        .channel('provider_orders_${_myProvider!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: _myProvider!.id,
          ),
          callback: (payload) => _handleOrderChange(payload),
        )
        .subscribe();
  }

  void _handleOrderChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert) {
      // Reload to get full order with joins
      loadProviderOrders();
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final orderId = payload.newRecord['id'] as String?;
      if (orderId != null) {
        final index = _providerOrders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          // Update local order
          _providerOrders[index] = _providerOrders[index].copyWith(
            status: OrderStatus.fromValue(payload.newRecord['status'] as String),
          );
          notifyListeners();
        }
      }
    }
  }

  /// Setup realtime subscription for customer orders
  void setupCustomerOrdersRealtime() {
    if (userId.isEmpty) return;
    
    _customerOrdersChannel?.unsubscribe();
    _customerOrdersChannel = _supabase
        .channel('customer_orders_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (payload) => _handleCustomerOrderChange(payload),
        )
        .subscribe();
  }

  void _handleCustomerOrderChange(PostgresChangePayload payload) {
    final orderId = payload.newRecord['id'] as String?;
    if (orderId != null) {
      final index = _customerOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        // Update local order with new status
        _customerOrders[index] = _customerOrders[index].copyWith(
          status: OrderStatus.fromValue(payload.newRecord['status'] as String),
          confirmedAt: payload.newRecord['confirmed_at'] != null 
              ? DateTime.parse(payload.newRecord['confirmed_at'] as String)
              : _customerOrders[index].confirmedAt,
          completedAt: payload.newRecord['completed_at'] != null 
              ? DateTime.parse(payload.newRecord['completed_at'] as String)
              : _customerOrders[index].completedAt,
          cancellationReason: payload.newRecord['cancellation_reason'] as String?,
        );
        notifyListeners();
      }
    }
  }

  // ============================================================================
  // LISTINGS - PAGINATION & FILTERING
  // ============================================================================

  /// Load listings with pagination and category filter
  Future<List<ServiceListing>> loadListings({
    ServiceCategory? category,
    String? providerId,
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from('service_listings')
          .select('*, service_providers(business_name, logo_url)')
          .eq('status', 'active');
      
      if (providerId != null) {
        query = query.eq('provider_id', providerId);
      }
      
      if (category != null) {
        // First get provider IDs with this category
        final providerIds = await _supabase
            .from('service_providers')
            .select('id')
            .eq('category', category.value)
            .eq('status', 'active');
        
        final ids = (providerIds as List).map((p) => p['id'] as String).toList();
        if (ids.isEmpty) return [];
        
        query = query.inFilter('provider_id', ids);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      
      return (response as List)
          .map((json) => ServiceListing.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading listings: $e');
      return [];
    }
  }

  /// Load all listings grouped by category
  Future<Map<ServiceCategory, List<ServiceListing>>> loadListingsByCategory() async {
    try {
      final response = await _supabase
          .from('service_listings')
          .select('*, service_providers!inner(category, business_name, logo_url)')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(100);
      
      final result = <ServiceCategory, List<ServiceListing>>{};
      
      for (final json in response as List) {
        final providerData = json['service_providers'] as Map<String, dynamic>?;
        if (providerData != null) {
          final category = ServiceCategory.fromValue(providerData['category'] as String);
          result[category] ??= [];
          result[category]!.add(ServiceListing.fromJson(json));
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error loading listings by category: $e');
      return {};
    }
  }
}
