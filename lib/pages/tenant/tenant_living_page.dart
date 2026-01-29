import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:oxy/models/service_provider.dart';
import 'package:oxy/models/community_post.dart';
import 'package:oxy/models/order.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/components/loading_indicator.dart';
import 'package:oxy/components/notification_badge.dart';

class TenantLivingPage extends StatefulWidget {
  const TenantLivingPage({super.key});

  @override
  State<TenantLivingPage> createState() => _TenantLivingPageState();
}

class _TenantLivingPageState extends State<TenantLivingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ServiceCategory? _selectedCategory;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<ServiceProvider> _searchResults = [];
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _currentTabIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final livingService = context.read<LivingService>();
    
    // Try to get location first
    if (!livingService.hasLocation) {
      await livingService.requestLocation();
    }
    
    // Always try to load data - uses fallback if no location
    if (livingService.hasLocation) {
      await livingService.loadNearbyProviders();
    } else {
      await livingService.loadAllProviders();
    }
    await livingService.loadCommunityPosts();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    
    setState(() => _isSearching = true);
    
    final livingService = context.read<LivingService>();
    final results = await livingService.searchProviders(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        title: const Text('Living'),
        actions: [
          // Cart icon with badge
          Consumer<LivingService>(
            builder: (context, livingService, _) {
              final cartCount = livingService.totalCartItems;
              return Stack(
                children: [
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedShoppingCart01,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Cart',
                    onPressed: () => context.push('/tenant/cart'),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const NotificationBadge(isTenantView: true),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedBookmark02,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Saved',
            onPressed: () => _showSavedProviders(context, context.read<LivingService>()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: Consumer<LivingService>(
        builder: (context, livingService, _) {
          if (!livingService.hasLocation && livingService.isLoadingLocation) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OxyLoader(size: 40),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Search bar
              Container(
                color: AppColors.primaryNavy,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services, shops, food...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: _search,
                  ),
                ),
              ),
              
              // Location indicator
              if (livingService.hasLocation || livingService.userLocationText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        color: AppColors.primaryNavy,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          livingService.userLocationText ?? 'Location available',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => livingService.requestLocation(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Update', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              
              // Content
              Expanded(
                child: _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDiscoverTab(livingService),
                          _buildCommunityTab(livingService),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _currentTabIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showCreatePostSheet(context),
              backgroundColor: AppColors.primaryNavy,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: OxyLoader(size: 32));
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: Colors.grey.shade300,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final provider = _searchResults[index];
        return _ProviderCard(
          provider: provider,
          onTap: () => _showProviderDetail(context, provider),
        );
      },
    );
  }

  Widget _buildDiscoverTab(LivingService livingService) {
    return RefreshIndicator(
      onRefresh: () async {
        await livingService.loadNearbyProviders();
      },
      child: CustomScrollView(
        slivers: [
          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ServiceCategory.values.length,
                      itemBuilder: (context, index) {
                        final category = ServiceCategory.values[index];
                        return _CategoryCard(
                          category: category,
                          isSelected: _selectedCategory == category,
                          onTap: () {
                            setState(() {
                              _selectedCategory = _selectedCategory == category ? null : category;
                            });
                            livingService.loadNearbyProviders(category: _selectedCategory);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Featured providers
          if (livingService.featuredProviders.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedStar,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Featured',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: livingService.featuredProviders.length,
                  itemBuilder: (context, index) {
                    final provider = livingService.featuredProviders[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _FeaturedProviderCard(
                        provider: provider,
                        onTap: () => _showProviderDetail(context, provider),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          
          // Nearby providers
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                _selectedCategory != null
                    ? '${_selectedCategory!.label} Nearby'
                    : 'Nearby',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          if (livingService.isLoadingProviders)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: OxyLoader(size: 32),
                ),
              ),
            )
          else if (livingService.nearbyProviders.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedStore01,
                        color: Colors.grey.shade300,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No services nearby',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to list your business!',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final provider = livingService.nearbyProviders[index];
                    return _ProviderCard(
                      provider: provider,
                      onTap: () => _showProviderDetail(context, provider),
                    );
                  },
                  childCount: livingService.nearbyProviders.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCommunityTab(LivingService livingService) {
    return RefreshIndicator(
      onRefresh: () async {
        await livingService.loadCommunityPosts();
      },
      child: livingService.isLoadingPosts
          ? const Center(child: OxyLoader(size: 32))
          : livingService.communityPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedComment02,
                        color: Colors.grey.shade300,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to share something!',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: livingService.communityPosts.length,
                  itemBuilder: (context, index) {
                    final post = livingService.communityPosts[index];
                    return _CommunityPostCard(
                      post: post,
                      onTap: () => _showPostDetail(context, post),
                      onReact: (reaction) => livingService.reactToPost(post.id, reaction),
                      onQuickLike: () => livingService.togglePostLike(post.id),
                    );
                  },
                ),
    );
  }

  void _showProviderDetail(BuildContext context, ServiceProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ProviderDetailPage(provider: provider),
      ),
    );
  }

  void _showPostDetail(BuildContext context, CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PostDetailPage(post: post),
      ),
    );
  }

  void _showSavedProviders(BuildContext context, LivingService livingService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SavedProvidersSheet(),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreatePostSheet(),
    );
  }
}

// ============================================
// CATEGORY ICONS MAPPING
// ============================================

IconData _getCategoryIcon(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.foodDining:
      return HugeIcons.strokeRoundedRestaurant01;
    case ServiceCategory.shopping:
      return HugeIcons.strokeRoundedShoppingBag02;
    case ServiceCategory.healthWellness:
      return HugeIcons.strokeRoundedMedicine02;
    case ServiceCategory.homeServices:
      return HugeIcons.strokeRoundedHome03;
    case ServiceCategory.professionalServices:
      return HugeIcons.strokeRoundedBriefcase01;
    case ServiceCategory.entertainment:
      return HugeIcons.strokeRoundedTicket02;
    case ServiceCategory.transport:
      return HugeIcons.strokeRoundedCar01;
    case ServiceCategory.education:
      return HugeIcons.strokeRoundedBook02;
    case ServiceCategory.beautySpa:
      return HugeIcons.strokeRoundedHairDryer;
    case ServiceCategory.fitness:
      return HugeIcons.strokeRoundedDumbbell01;
    case ServiceCategory.financial:
      return HugeIcons.strokeRoundedBank;
    case ServiceCategory.other:
      return HugeIcons.strokeRoundedMoreHorizontal;
  }
}

IconData _getPostTypeIcon(CommunityPostType type) {
  switch (type) {
    case CommunityPostType.announcement:
      return HugeIcons.strokeRoundedMegaphone01;
    case CommunityPostType.discussion:
      return HugeIcons.strokeRoundedComment02;
    case CommunityPostType.event:
      return HugeIcons.strokeRoundedCalendar03;
    case CommunityPostType.recommendation:
      return HugeIcons.strokeRoundedThumbsUp;
    case CommunityPostType.question:
      return HugeIcons.strokeRoundedHelpCircle;
    case CommunityPostType.offer:
      return HugeIcons.strokeRoundedTag01;
    case CommunityPostType.alert:
      return HugeIcons.strokeRoundedAlert02;
  }
}

// ============================================
// CATEGORY CARD
// ============================================

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: _getCategoryIcon(category),
              color: isSelected ? Colors.white : AppColors.primaryNavy,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              category.label.split(' ').first,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PROVIDER CARDS
// ============================================

class _FeaturedProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onTap;

  const _FeaturedProviderCard({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                child: provider.coverImageUrl != null
                    ? Image.network(provider.coverImageUrl!, fit: BoxFit.cover)
                    : Center(
                        child: HugeIcon(
                          icon: _getCategoryIcon(provider.category),
                          color: AppColors.primaryNavy,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (provider.isVerified)
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        provider.ratingLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      if (provider.distanceKm != null)
                        Text(
                          provider.distanceLabel,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo/Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: provider.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(provider.logoUrl!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: HugeIcon(
                        icon: _getCategoryIcon(provider.category),
                        color: AppColors.primaryNavy,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (provider.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 16, color: Colors.blue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.category.label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        provider.ratingAverage.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        ' (${provider.ratingCount})',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (provider.businessHours != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: provider.businessHours!.isOpenNow()
                                ? AppColors.success.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            provider.businessHours!.isOpenNow() ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: provider.businessHours!.isOpenNow()
                                  ? AppColors.success
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (provider.distanceKm != null)
                        Row(
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              color: AppColors.primaryNavy,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              provider.distanceLabel,
                              style: const TextStyle(fontSize: 12, color: AppColors.primaryNavy),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ============================================
// COMMUNITY POST CARD
// ============================================

class _CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final void Function(ReactionType) onReact;
  final VoidCallback onQuickLike;

  const _CommunityPostCard({
    required this.post,
    required this.onTap,
    required this.onReact,
    required this.onQuickLike,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                    backgroundImage: post.userAvatarUrl != null
                        ? NetworkImage(post.userAvatarUrl!)
                        : null,
                    child: post.userAvatarUrl == null
                        ? Text(
                            post.initials,
                            style: const TextStyle(
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: _getPostTypeIcon(post.postType),
                          color: AppColors.primaryNavy,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.postType.label,
                          style: const TextStyle(fontSize: 10, color: AppColors.primaryNavy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            if (post.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Text(
                  post.title!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            // Image preview
            if (post.firstImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.network(
                  post.firstImageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            
            // Event info
            if (post.isEvent && post.eventDateLabel != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.eventDateLabel!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Actions
            if (post.firstImageUrl == null)
              const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Reaction button with long press for picker
                  GestureDetector(
                    onLongPress: () => _showReactionPicker(context),
                    child: TextButton.icon(
                      onPressed: onQuickLike,
                      icon: Text(
                        post.myReaction?.emoji ?? '👍',
                        style: TextStyle(
                          fontSize: 18,
                          color: post.isLikedByMe ? null : Colors.grey.shade400,
                        ),
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show top reactions
                          if (post.topReactions.isNotEmpty) ...[
                            ...post.topReactions.take(3).map((r) => Text(
                              r.type.emoji,
                              style: const TextStyle(fontSize: 12),
                            )),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${post.totalReactions}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedComment02,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    label: Text(
                      '${post.commentsCount}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedShare01,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
  
  void _showReactionPicker(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero, ancestor: overlay);
    
    showMenu<ReactionType>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - 60,
        position.dx + 300,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      items: ReactionType.values.map((reaction) {
        return PopupMenuItem<ReactionType>(
          value: reaction,
          height: 48,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reaction.emoji, style: const TextStyle(fontSize: 28)),
              Text(reaction.label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    ).then((selectedReaction) {
      if (selectedReaction != null) {
        onReact(selectedReaction);
      }
    });
  }
}

// ============================================
// PROVIDER DETAIL PAGE
// ============================================

class _ProviderDetailPage extends StatefulWidget {
  final ServiceProvider provider;

  const _ProviderDetailPage({required this.provider});

  @override
  State<_ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<_ProviderDetailPage> {
  List<ServiceListing> _listings = [];
  List<ServiceReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final livingService = context.read<LivingService>();
    
    final listings = await livingService.getProviderListings(widget.provider.id);
    final reviews = await livingService.getProviderReviews(widget.provider.id);
    
    if (mounted) {
      setState(() {
        _listings = listings;
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  void _showWriteReviewSheet(BuildContext context) {
    int selectedRating = 0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Review ${widget.provider.businessName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Rating stars
                const Text(
                  'How would you rate this business?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => selectedRating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    selectedRating == 0
                        ? 'Tap to rate'
                        : selectedRating == 1
                            ? 'Poor'
                            : selectedRating == 2
                                ? 'Fair'
                                : selectedRating == 3
                                    ? 'Good'
                                    : selectedRating == 4
                                        ? 'Very Good'
                                        : 'Excellent',
                    style: TextStyle(
                      color: selectedRating == 0 ? Colors.grey : Colors.amber.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Comment
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Your Review (optional)',
                    hintText: 'Share your experience with this business...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedRating == 0 || isSubmitting
                        ? null
                        : () async {
                            setState(() => isSubmitting = true);
                            try {
                              final livingService = context.read<LivingService>();
                              await livingService.submitReview(
                                providerId: widget.provider.id,
                                rating: selectedRating,
                                comment: commentController.text.isEmpty
                                    ? null
                                    : commentController.text,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Review submitted successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                // Reload reviews
                                _loadData();
                              }
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryNavy,
            flexibleSpace: FlexibleSpaceBar(
              background: provider.coverImageUrl != null
                  ? Image.network(provider.coverImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primaryNavy,
                      child: Center(
                        child: HugeIcon(
                          icon: _getCategoryIcon(provider.category),
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 80,
                        ),
                      ),
                    ),
            ),
            actions: [
              Consumer<LivingService>(
                builder: (context, livingService, _) {
                  final isSaved = livingService.isProviderSaved(provider.id);
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                    onPressed: () => livingService.toggleSaveProvider(provider.id),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          
          // Business info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: provider.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(provider.logoUrl!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(provider.initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    provider.businessName,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (provider.isVerified)
                                  const Icon(Icons.verified, color: Colors.blue, size: 20),
                              ],
                            ),
                            Row(
                              children: [
                                HugeIcon(
                                  icon: _getCategoryIcon(provider.category),
                                  color: Colors.grey.shade600,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  provider.category.label,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating, distance & open status
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              provider.ratingLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedLocation01,
                                color: AppColors.primaryNavy,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                provider.distanceLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (provider.businessHours != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: provider.businessHours!.isOpenNow()
                                ? AppColors.success.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.businessHours!.isOpenNow()
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
                                color: provider.businessHours!.isOpenNow()
                                    ? AppColors.success
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                provider.businessHours!.isOpenNow()
                                    ? 'Open Now'
                                    : 'Closed',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: provider.businessHours!.isOpenNow()
                                      ? AppColors.success
                                      : Colors.red,
                                ),
                              ),
                              if (provider.businessHours!.getTodayHours() != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '• ${provider.businessHours!.getTodayHours()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  if (provider.businessDescription != null) ...[
                    const SizedBox(height: 16),
                    Text(provider.businessDescription!),
                  ],
                  
                  // Features
                  if (provider.features.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(f, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Contact buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                      label: const Text('Call', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (provider.whatsapp != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedWhatsapp,
                          color: Colors.green,
                          size: 18,
                        ),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Listings
          if (_listings.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Services & Products',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final listing = _listings[index];
                    return _ListingCard(listing: listing);
                  },
                  childCount: _listings.length,
                ),
              ),
            ),
          ],
          
          // Reviews
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showWriteReviewSheet(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Write Review'),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: OxyLoader(size: 32),
              )),
            )
          else if (_reviews.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final review = _reviews[index];
                    return _ReviewCard(review: review);
                  },
                  childCount: _reviews.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ServiceListing listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showListingDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - use Expanded to fill available space
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: listing.coverImageUrl != null
                      ? Image.network(listing.coverImageUrl!, fit: BoxFit.cover)
                      : Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
            // Content - compact
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.priceLabel,
                            style: const TextStyle(
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addToCart(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedAdd01,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    final livingService = context.read<LivingService>();
    livingService.addToCart(CartItem(
      listingId: listing.id,
      providerId: listing.providerId,
      title: listing.title,
      description: listing.description,
      price: listing.price ?? 0,
      priceUnit: listing.priceUnit,
      imageUrl: listing.coverImageUrl,
      quantity: 1,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${listing.title} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.push('/tenant/cart'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showListingDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ListingDetailSheet(listing: listing),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ServiceReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                child: Text(
                  (review.userName ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: const TextStyle(fontSize: 13)),
          ],
          if (review.providerResponse != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Response from business:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(review.providerResponse!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================
// POST DETAIL PAGE
// ============================================

class _PostDetailPage extends StatefulWidget {
  final CommunityPost post;

  const _PostDetailPage({required this.post});

  @override
  State<_PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<_PostDetailPage> {
  final _commentController = TextEditingController();
  List<CommunityComment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final livingService = context.read<LivingService>();
    final comments = await livingService.getPostComments(widget.post.id);
    
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    final livingService = context.read<LivingService>();
    final comment = await livingService.addComment(
      postId: widget.post.id,
      content: content,
    );
    
    if (comment != null && mounted) {
      setState(() => _comments.add(comment));
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        title: Text(post.postType.label),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post content
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                              backgroundImage: post.userAvatarUrl != null
                                  ? NetworkImage(post.userAvatarUrl!)
                                  : null,
                              child: post.userAvatarUrl == null
                                  ? Text(
                                      post.initials,
                                      style: const TextStyle(
                                        color: AppColors.primaryNavy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Row(
                                    children: [
                                      HugeIcon(
                                        icon: _getPostTypeIcon(post.postType),
                                        color: Colors.grey.shade600,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        post.postType.label,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        if (post.title != null)
                          Text(
                            post.title!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        
                        const SizedBox(height: 8),
                        Text(post.content),
                        
                        // Images
                        if (post.images.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              post.firstImageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Actions
                        Consumer<LivingService>(
                          builder: (context, livingService, _) {
                            // Get the current post state from service
                            final currentPost = livingService.communityPosts
                                .firstWhere((p) => p.id == post.id, orElse: () => post);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Reaction summary
                                if (currentPost.totalReactions > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        ...currentPost.topReactions.map((r) => Padding(
                                          padding: const EdgeInsets.only(right: 2),
                                          child: Text(r.type.emoji, style: const TextStyle(fontSize: 16)),
                                        )),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${currentPost.totalReactions}',
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // Action buttons
                                Row(
                                  children: [
                                    // Reaction button
                                    _ReactionButton(
                                      currentReaction: currentPost.myReaction,
                                      onReact: (reaction) => livingService.reactToPost(post.id, reaction),
                                      onQuickLike: () => livingService.togglePostLike(post.id),
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: HugeIcon(
                                        icon: HugeIcons.strokeRoundedComment02,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                      label: Text(
                                        '${_comments.length} comments',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Comments
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: OxyLoader(size: 32),
                    ))
                  else
                    Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Comments',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_comments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No comments yet. Be the first!',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            )
                          else
                            ..._comments.map((comment) => _CommentTile(comment: comment)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedSent,
                    color: AppColors.primaryNavy,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// REACTION BUTTON (Reusable)
// ============================================

class _ReactionButton extends StatelessWidget {
  final ReactionType? currentReaction;
  final void Function(ReactionType) onReact;
  final VoidCallback onQuickLike;

  const _ReactionButton({
    required this.currentReaction,
    required this.onReact,
    required this.onQuickLike,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showReactionPicker(context),
      child: TextButton.icon(
        onPressed: onQuickLike,
        icon: Text(
          currentReaction?.emoji ?? '👍',
          style: TextStyle(
            fontSize: 20,
            color: currentReaction != null ? null : Colors.grey.shade400,
          ),
        ),
        label: Text(
          currentReaction?.label ?? 'Like',
          style: TextStyle(
            color: currentReaction != null ? AppColors.primaryNavy : Colors.grey.shade600,
            fontWeight: currentReaction != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ReactionType.values.map((reaction) {
            final isSelected = currentReaction == reaction;
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onReact(reaction);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryNavy.withValues(alpha: 0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reaction.emoji,
                      style: TextStyle(fontSize: isSelected ? 32 : 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reaction.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.primaryNavy : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
            child: Text(
              comment.initials,
              style: const TextStyle(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ============================================
// SAVED PROVIDERS SHEET
// ============================================

class _SavedProvidersSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Saved',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ServiceProvider>>(
                  future: context.read<LivingService>().getSavedProviders(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: OxyLoader(size: 32));
                    }
                    
                    final providers = snapshot.data!;
                    
                    if (providers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedBookmark02,
                              color: Colors.grey.shade300,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved services',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: bottomPadding + 16,
                      ),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        return _ProviderCard(
                          provider: provider,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _ProviderDetailPage(provider: provider),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================
// CREATE POST SHEET
// ============================================

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  CommunityPostType _selectedType = CommunityPostType.discussion;
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(4 - _selectedImages.length)); // Max 4 images
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    final List<String> urls = [];
    
    for (final image in _selectedImages) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = image.path.split('.').last;
      final path = 'community-posts/$userId/$timestamp.$extension';
      
      final bytes = await image.readAsBytes();
      await supabase.storage.from('community').uploadBinary(path, bytes);
      
      final url = supabase.storage.from('community').getPublicUrl(path);
      urls.add(url);
    }
    
    return urls;
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;
    
    final livingService = context.read<LivingService>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    setState(() => _isLoading = true);
    
    try {
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }
      
      final post = await livingService.createPost(
        postType: _selectedType,
        title: title.isEmpty ? null : title,
        content: content,
        imageUrls: imageUrls,
      );
      
      if (mounted) {
        if (post != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      debugPrint('Error submitting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create Post',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Post type selector
            Text('Post Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CommunityPostType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  avatar: HugeIcon(
                    icon: _getPostTypeIcon(type),
                    color: isSelected ? Colors.white : AppColors.primaryNavy,
                    size: 16,
                  ),
                  label: Text(
                    type.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primaryNavy,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primaryNavy,
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryNavy : Colors.grey.shade300,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Title (optional)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Give your post a title...',
              ),
            ),
            const SizedBox(height: 16),
            
            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'What would you like to share?',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            
            // Image picker
            Row(
              children: [
                Text('Photos', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (_selectedImages.length < 4)
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedImage01,
                      color: AppColors.primaryNavy,
                      size: 20,
                    ),
                    label: const Text('Add'),
                  ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_selectedImages[index].path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const OxyDotsLoader(dotSize: 6, color: Colors.white)
                    : const Text('Post', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listing detail sheet with business hours and add to cart
class _ListingDetailSheet extends StatefulWidget {
  final ServiceListing listing;

  const _ListingDetailSheet({required this.listing});

  @override
  State<_ListingDetailSheet> createState() => _ListingDetailSheetState();
}

class _ListingDetailSheetState extends State<_ListingDetailSheet> {
  int _quantity = 1;
  ServiceProvider? _provider;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final livingService = context.read<LivingService>();
    // Try to find provider in cached data
    _provider = livingService.nearbyProviders.firstWhere(
      (p) => p.id == widget.listing.providerId,
      orElse: () => ServiceProvider(
        id: widget.listing.providerId,
        userId: '',
        businessName: 'Provider',
        category: ServiceCategory.other,
        phone: '',
        locationText: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Image gallery
                  if (listing.images.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: listing.images.length,
                        itemBuilder: (context, index) {
                          final image = listing.images[index];
                          final imageUrl = image is Map ? image['url'] as String? : image as String?;
                          if (imageUrl == null) return const SizedBox.shrink();
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Title and price
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.priceLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (listing.description != null && listing.description!.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(listing.description!),
                    const SizedBox(height: 16),
                  ],

                  // Provider info
                  if (_provider != null) ...[
                    const Text(
                      'Provider',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _provider!.logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(_provider!.logoUrl!, fit: BoxFit.cover),
                                  )
                                : const Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedStore01,
                                      color: AppColors.primaryNavy,
                                      size: 24,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _provider!.businessName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _provider!.category.label,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_provider!.ratingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.amber.shade700, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _provider!.ratingAverage.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Business hours
                    if (_provider!.businessHours != null) ...[
                      const Text(
                        'Business Hours',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _BusinessHoursCard(businessHours: _provider!.businessHours!),
                      const SizedBox(height: 16),
                    ],
                  ],

                  const SizedBox(height: 80), // Space for bottom bar
                ],
              ),
            ),

            // Bottom bar with quantity and add to cart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Quantity selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            icon: const Icon(Icons.remove, size: 20),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          Container(
                            width: 32,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add, size: 20),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Add to cart button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addToCart,
                        child: Text(
                          'Add to Cart • ${Formatters.currency((listing.price ?? 0) * _quantity)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    final livingService = context.read<LivingService>();
    final listing = widget.listing;
    
    livingService.addToCart(CartItem(
      listingId: listing.id,
      providerId: listing.providerId,
      title: listing.title,
      description: listing.description,
      price: listing.price ?? 0,
      priceUnit: listing.priceUnit,
      imageUrl: listing.coverImageUrl,
      quantity: _quantity,
    ));
    
    // Capture references before popping (context becomes invalid after pop)
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final title = listing.title;
    
    Navigator.pop(context);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('$title added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => router.push('/tenant/cart'),
        ),
      ),
    );
  }
}

/// Business hours display card
class _BusinessHoursCard extends StatelessWidget {
  final BusinessHours businessHours;

  const _BusinessHoursCard({required this.businessHours});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // 1 = Monday
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(7, (index) {
          final dayKey = days[index];
          final dayHours = businessHours.hours[dayKey];
          final isToday = today == index + 1;
          final isOpen = dayHours != null;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppColors.primaryNavy : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOpen
                        ? '${dayHours.open} - ${dayHours.close}'
                        : 'Closed',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                      color: isOpen
                          ? (isToday ? AppColors.primaryNavy : Colors.grey.shade800)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
