import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/property_enquiry.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/utils/icons.dart';
import 'package:oxy/components/loading_indicator.dart';
import 'package:oxy/components/notification_badge.dart';
import 'package:oxy/components/features_editor.dart';

class TenantExplorePage extends StatefulWidget {
  const TenantExplorePage({super.key});

  @override
  State<TenantExplorePage> createState() => _TenantExplorePageState();
}

class _TenantExplorePageState extends State<TenantExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<ListedProperty> _properties = [];
  List<String> _locations = [];
  String? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final tenantService = context.read<TenantService>();
    final properties = await tenantService.loadListedProperties(
      locationFilter: _selectedLocation,
    );
    final locations = await tenantService.getAvailableLocations();
    
    if (mounted) {
      setState(() {
        _properties = properties;
        _locations = locations;
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilter(String? location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });
    
    final tenantService = context.read<TenantService>();
    final properties = await tenantService.loadListedProperties(
      locationFilter: location,
    );
    
    if (mounted) {
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primaryTeal,
              expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryTeal,
                      AppColors.primaryTeal.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Your Next Home',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_properties.length} properties available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Explore',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              const NotificationBadge(isTenantView: true),
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMailOpen,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'My Enquiries',
                onPressed: () => context.push('/tenant/enquiries'),
              ),
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFilter,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => _showFilterSheet(),
              ),
            ],
          ),
          
          // Location filter chips
          if (_locations.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedLocation == null,
                        onTap: () => _applyFilter(null),
                      ),
                      ..._locations.map((loc) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: loc.length > 20 ? '${loc.substring(0, 20)}...' : loc,
                          isSelected: _selectedLocation == loc,
                          onTap: () => _applyFilter(loc),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: OxyLoadingOverlay(message: 'Finding properties...'),
            )
          else if (_properties.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: AppIcons.house,
                      color: Colors.grey.shade300,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No properties available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new listings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final property = _properties[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PropertyCard(
                        property: property,
                        onTap: () => _showPropertyDetail(property),
                      ),
                    );
                  },
                  childCount: _properties.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        locations: _locations,
        selectedLocation: _selectedLocation,
        onApply: (location) {
          Navigator.pop(context);
          _applyFilter(location);
        },
      ),
    );
  }

  void _showPropertyDetail(ListedProperty property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PropertyDetailPage(property: property),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.lightOnSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final ListedProperty property;
  final VoidCallback onTap;

  const _PropertyCard({
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  if (property.coverImageUrl != null)
                    Image.network(
                      property.coverImageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),
                  
                  // Type badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        property.typeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  // Units badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${property.availableUnits} unit${property.availableUnits > 1 ? 's' : ''} available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      HugeIcon(
                        icon: AppIcons.location,
                        color: AppColors.lightOnSurfaceVariant,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.locationText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (property.features.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    FeaturesDisplay(
                      features: property.features,
                      maxDisplay: 3,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        property.rentRangeLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: TextStyle(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            HugeIcon(
                              icon: AppIcons.chevronRight,
                              color: AppColors.primaryTeal,
                              size: 16,
                            ),
                          ],
                        ),
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

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: HugeIcon(
          icon: AppIcons.house,
          color: Colors.grey.shade400,
          size: 48,
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> locations;
  final String? selectedLocation;
  final Function(String?) onApply;

  const _FilterSheet({
    required this.locations,
    this.selectedLocation,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
            'Filter Properties',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All Locations',
                isSelected: _selectedLocation == null,
                onTap: () => setState(() => _selectedLocation = null),
              ),
              ...widget.locations.map((loc) => _FilterChip(
                label: loc,
                isSelected: _selectedLocation == loc,
                onTap: () => setState(() => _selectedLocation = loc),
              )),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_selectedLocation),
              child: const Text('Apply Filter', style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// Property Detail Page
class _PropertyDetailPage extends StatefulWidget {
  final ListedProperty property;

  const _PropertyDetailPage({required this.property});

  @override
  State<_PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<_PropertyDetailPage> {
  List<ListedUnit> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final tenantService = context.read<TenantService>();
    final units = await tenantService.loadListedUnitsForProperty(widget.property.id);
    
    if (mounted) {
      setState(() {
        _units = units;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primaryTeal,
            flexibleSpace: FlexibleSpaceBar(
              background: property.coverImageUrl != null
                  ? Image.network(
                      property.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.typeLabel,
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${property.availableUnits} units available',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    property.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      HugeIcon(
                        icon: AppIcons.location,
                        color: AppColors.lightOnSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          property.locationText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (property.listingDescription != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      property.listingDescription!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    property.rentRangeLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Features section
          if (property.features.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedStar,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Property Features',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: AppColors.primaryTeal),
                            const SizedBox(width: 6),
                            Text(
                              f,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Available Units',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: OxyLoader(size: 40),
              )),
            )
          else if (_units.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No units available',
                    style: TextStyle(color: AppColors.lightOnSurfaceVariant),
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
                    final unit = _units[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UnitCard(
                        unit: unit,
                        onEnquire: () => _showEnquirySheet(unit),
                      ),
                    );
                  },
                  childCount: _units.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: ElevatedButton(
            onPressed: () => _showEnquirySheet(null),
            child: const Text('Enquire About Property', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: HugeIcon(
          icon: AppIcons.house,
          color: Colors.grey.shade400,
          size: 64,
        ),
      ),
    );
  }

  void _showEnquirySheet(ListedUnit? unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnquirySheet(
        property: widget.property,
        unit: unit,
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final ListedUnit unit;
  final VoidCallback onEnquire;

  const _UnitCard({
    required this.unit,
    required this.onEnquire,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (unit.coverImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                unit.coverImageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        unit.unitLabel,
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (unit.unitType != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        unit.unitType!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.currency(unit.rentAmount),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          Text(
                            'per month',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(unit.depositAmount),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'deposit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (unit.amenities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: unit.amenities.take(4).map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onEnquire,
                    child: const Text('Enquire'),
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

class _EnquirySheet extends StatefulWidget {
  final ListedProperty property;
  final ListedUnit? unit;

  const _EnquirySheet({
    required this.property,
    this.unit,
  });

  @override
  State<_EnquirySheet> createState() => _EnquirySheetState();
}

class _EnquirySheetState extends State<_EnquirySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  EnquiryType _enquiryType = EnquiryType.viewing;
  DateTime? _preferredDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from current tenant profile if available
    final tenantService = context.read<TenantService>();
    if (tenantService.currentTenant != null) {
      _nameController.text = tenantService.currentTenant!.fullName;
      _phoneController.text = tenantService.currentTenant!.phone;
      _emailController.text = tenantService.currentTenant!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final tenantService = context.read<TenantService>();
      await tenantService.submitEnquiry(
        orgId: widget.property.orgId,
        propertyId: widget.property.id,
        unitId: widget.unit?.id,
        enquiryType: _enquiryType,
        contactName: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
        preferredDate: _preferredDate,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enquiry submitted successfully! The property manager will contact you.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
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
        child: Form(
          key: _formKey,
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
                widget.unit != null 
                    ? 'Enquire About ${widget.unit!.unitLabel}'
                    : 'Enquire About ${widget.property.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Enquiry Type
              Text('What would you like to do?', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EnquiryType.values.map((type) => ChoiceChip(
                  label: Text(type == EnquiryType.viewing ? 'Schedule Viewing' 
                      : type == EnquiryType.information ? 'Get Info' : 'Apply'),
                  selected: _enquiryType == type,
                  onSelected: (selected) {
                    if (selected) setState(() => _enquiryType = type);
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              // Email (optional)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              
              // Preferred date for viewing
              if (_enquiryType == EnquiryType.viewing) ...[
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setState(() => _preferredDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Preferred Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _preferredDate != null 
                          ? Formatters.date(_preferredDate!)
                          : 'Select a date',
                      style: TextStyle(
                        color: _preferredDate != null ? null : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Message
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                      ? const OxyDotsLoader(dotSize: 6, color: Colors.white)
                      : const Text('Submit Enquiry', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
