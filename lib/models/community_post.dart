/// Community post types
enum CommunityPostType {
  announcement('announcement', 'Announcement', '📢'),
  discussion('discussion', 'Discussion', '💬'),
  event('event', 'Event', '📅'),
  recommendation('recommendation', 'Recommendation', '⭐'),
  question('question', 'Question', '❓'),
  offer('offer', 'Offer/Deal', '🏷️'),
  alert('alert', 'Alert', '⚠️');

  final String value;
  final String label;
  final String emoji;
  
  const CommunityPostType(this.value, this.label, this.emoji);
  
  static CommunityPostType fromValue(String value) {
    return CommunityPostType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => CommunityPostType.discussion,
    );
  }
}

/// Reaction types for posts and comments
enum ReactionType {
  like('like', '👍', 'Like'),
  love('love', '❤️', 'Love'),
  celebrate('celebrate', '🎉', 'Celebrate'),
  support('support', '🙏', 'Support'),
  insightful('insightful', '💡', 'Insightful'),
  funny('funny', '😂', 'Funny');

  final String value;
  final String emoji;
  final String label;
  
  const ReactionType(this.value, this.emoji, this.label);
  
  static ReactionType fromValue(String value) {
    return ReactionType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => ReactionType.like,
    );
  }
}

/// Reaction count for a specific reaction type
class ReactionCount {
  final ReactionType type;
  final int count;
  
  const ReactionCount(this.type, this.count);
}

/// Community Post model
class CommunityPost {
  final String id;
  final String userId;
  
  // Content
  final CommunityPostType postType;
  final String? title;
  final String content;
  final List<dynamic> images;
  
  // Location
  final String? locationText;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  
  // Engagement
  final int likesCount;
  final int commentsCount;
  
  // Visibility
  final bool isPinned;
  final bool isHidden;
  
  // Event fields
  final DateTime? eventDate;
  final DateTime? eventEndDate;
  final String? eventLocation;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed
  final double? distanceKm;
  
  // Joined from profiles
  final String? userName;
  final String? userAvatarUrl;
  
  // State (for UI)
  final ReactionType? myReaction;
  final Map<ReactionType, int> reactionCounts;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.postType,
    this.title,
    required this.content,
    this.images = const [],
    this.locationText,
    this.latitude,
    this.longitude,
    this.radiusKm = 5,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isPinned = false,
    this.isHidden = false,
    this.eventDate,
    this.eventEndDate,
    this.eventLocation,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
    this.userName,
    this.userAvatarUrl,
    this.myReaction,
    this.reactionCounts = const {},
  });
  
  bool get isLikedByMe => myReaction != null;

  factory CommunityPost.fromJson(
    Map<String, dynamic> json, {
    ReactionType? myReaction,
    Map<ReactionType, int>? reactionCounts,
  }) {
    // Handle joined profile data (from regular query) or direct fields (from RPC)
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    // Try to get user name/avatar from either nested profile or direct fields
    String? userName = profile?['full_name'] as String?;
    String? userAvatarUrl = profile?['avatar_url'] as String?;
    
    // RPC results return these as direct fields
    if (userName == null && json['user_name'] != null) {
      userName = json['user_name'] as String?;
    }
    if (userAvatarUrl == null && json['user_avatar_url'] != null) {
      userAvatarUrl = json['user_avatar_url'] as String?;
    }
    
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postType: CommunityPostType.fromValue(json['post_type'] as String? ?? 'discussion'),
      title: json['title'] as String?,
      content: json['content'] as String,
      images: json['images'] as List<dynamic>? ?? [],
      locationText: json['location_text'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 5,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
      eventEndDate: json['event_end_date'] != null
          ? DateTime.parse(json['event_end_date'] as String)
          : null,
      eventLocation: json['event_location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      myReaction: myReaction,
      reactionCounts: reactionCounts ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'post_type': postType.value,
    'title': title,
    'content': content,
    'images': images,
    'location_text': locationText,
    'latitude': latitude,
    'longitude': longitude,
    'radius_km': radiusKm,
    'is_pinned': isPinned,
    'is_hidden': isHidden,
    'event_date': eventDate?.toIso8601String(),
    'event_end_date': eventEndDate?.toIso8601String(),
    'event_location': eventLocation,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  CommunityPost copyWith({
    String? id,
    String? userId,
    CommunityPostType? postType,
    String? title,
    String? content,
    List<dynamic>? images,
    String? locationText,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? likesCount,
    int? commentsCount,
    bool? isPinned,
    bool? isHidden,
    DateTime? eventDate,
    DateTime? eventEndDate,
    String? eventLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distanceKm,
    String? userName,
    String? userAvatarUrl,
    ReactionType? myReaction,
    bool clearMyReaction = false,
    Map<ReactionType, int>? reactionCounts,
  }) => CommunityPost(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    postType: postType ?? this.postType,
    title: title ?? this.title,
    content: content ?? this.content,
    images: images ?? this.images,
    locationText: locationText ?? this.locationText,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusKm: radiusKm ?? this.radiusKm,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    isPinned: isPinned ?? this.isPinned,
    isHidden: isHidden ?? this.isHidden,
    eventDate: eventDate ?? this.eventDate,
    eventEndDate: eventEndDate ?? this.eventEndDate,
    eventLocation: eventLocation ?? this.eventLocation,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    distanceKm: distanceKm ?? this.distanceKm,
    userName: userName ?? this.userName,
    userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
    reactionCounts: reactionCounts ?? this.reactionCounts,
  );
  
  /// Get the top reactions sorted by count
  List<ReactionCount> get topReactions {
    final sorted = reactionCounts.entries
        .where((e) => e.value > 0)
        .map((e) => ReactionCount(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return sorted.take(3).toList();
  }
  
  /// Total reactions count
  int get totalReactions => reactionCounts.values.fold(0, (a, b) => a + b);

  String? get firstImageUrl {
    if (images.isEmpty) return null;
    final first = images.first;
    if (first is Map) return first['url'] as String?;
    if (first is String) return first;
    return null;
  }

  String get displayName => userName ?? 'Anonymous';
  
  String get initials {
    if (userName == null || userName!.isEmpty) return '?';
    final words = userName!.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return userName!.substring(0, userName!.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get isEvent => postType == CommunityPostType.event;
  
  String? get eventDateLabel {
    if (eventDate == null) return null;
    final now = DateTime.now();
    final diff = eventDate!.difference(now);
    
    if (diff.isNegative) {
      return 'Past event';
    } else if (diff.inDays == 0) {
      return 'Today at ${_formatTime(eventDate!)}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow at ${_formatTime(eventDate!)}';
    } else if (diff.inDays < 7) {
      return '${_dayName(eventDate!.weekday)} at ${_formatTime(eventDate!)}';
    } else {
      return '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}';
    }
  }
  
  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
  
  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

/// Community Comment model
class CommunityComment {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String content;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined from profiles
  final String? userName;
  final String? userAvatarUrl;
  
  // For nested replies
  final List<CommunityComment> replies;
  
  // State
  final bool isLikedByMe;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    this.likesCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
    this.replies = const [],
    this.isLikedByMe = false,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json, {bool isLiked = false}) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    return CommunityComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: profile?['full_name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
      isLikedByMe: isLiked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'user_id': userId,
    'parent_id': parentId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  CommunityComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? parentId,
    String? content,
    int? likesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
    List<CommunityComment>? replies,
    bool? isLikedByMe,
  }) => CommunityComment(
    id: id ?? this.id,
    postId: postId ?? this.postId,
    userId: userId ?? this.userId,
    parentId: parentId ?? this.parentId,
    content: content ?? this.content,
    likesCount: likesCount ?? this.likesCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userName: userName ?? this.userName,
    userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    replies: replies ?? this.replies,
    isLikedByMe: isLikedByMe ?? this.isLikedByMe,
  );

  String get displayName => userName ?? 'Anonymous';
  
  String get initials {
    if (userName == null || userName!.isEmpty) return '?';
    final words = userName!.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return userName!.substring(0, userName!.length >= 2 ? 2 : 1).toUpperCase();
  }
}
