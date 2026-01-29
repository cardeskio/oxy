import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/utils/icons.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/image_gallery.dart';
import 'package:oxy/components/features_editor.dart';

class PropertyDetailPage extends StatelessWidget {
  final String propertyId;
  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final property = dataService.getPropertyById(propertyId);
        if (property == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Property Not Found')),
            body: const Center(child: Text('Property not found')),
          );
        }

        final units = dataService.getUnitsForProperty(propertyId);
        final occupiedCount = units.where((u) => u.status == UnitStatus.occupied).length;
        final vacantCount = units.where((u) => u.status == UnitStatus.vacant).length;
        final maintenanceCount = units.where((u) => u.status == UnitStatus.maintenance).length;

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Text(property.name, style: const TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => _showEditPropertySheet(context, dataService, property),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Property Images
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Property Photos',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (property.images.isNotEmpty)
                            Text(
                              '${property.images.length} photos',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.lightOnSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ImageGallery(
                      images: property.images,
                      canEdit: true,
                      onAddImages: (filePaths) => dataService.uploadPropertyImages(property.id, filePaths),
                      onRemoveImage: (url) => dataService.removePropertyImage(property.id, url),
                      height: 180,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Property Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              property.typeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: AppColors.lightOnSurfaceVariant),
                          const SizedBox(width: 8),
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
                      if (property.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          property.notes!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatBox(value: '${units.length}', label: 'Total', color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    _StatBox(value: '$occupiedCount', label: 'Occupied', color: AppColors.info),
                    const SizedBox(width: 12),
                    _StatBox(value: '$vacantCount', label: 'Vacant', color: AppColors.success),
                    const SizedBox(width: 12),
                    _StatBox(value: '$maintenanceCount', label: 'Maint.', color: AppColors.warning),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Units Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Units',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddUnitSheet(context, dataService, property),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Unit'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Units List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: units.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.door_back_door_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No units yet'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _showAddUnitSheet(context, dataService, property),
                              child: const Text('Add First Unit', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: units.map((unit) {
                          final lease = dataService.getActiveLeaseForUnit(unit.id);
                          final tenant = lease != null ? dataService.getTenantById(lease.tenantId) : null;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: UnitCard(
                              unit: unit,
                              tenantName: tenant?.fullName,
                              fallbackImageUrl: property.coverImageUrl,
                              onTap: () => _showUnitDetails(context, dataService, property, unit, lease, tenant),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddUnitSheet(context, dataService, property),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showEditPropertySheet(BuildContext context, DataService dataService, Property property) {
    final nameController = TextEditingController(text: property.name);
    final locationController = TextEditingController(text: property.locationText);
    final notesController = TextEditingController(text: property.notes ?? '');
    PropertyType selectedType = property.type;
    bool isListed = property.isListed;
    List<String> features = List<String>.from(property.features);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
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
                  'Edit Property',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Property Name *',
                    hintText: 'e.g., Sunrise Apartments',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PropertyType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Property Type'),
                  items: PropertyType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t == PropertyType.residential ? 'Residential' 
                        : t == PropertyType.commercial ? 'Commercial' 
                        : 'Mixed Use'),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    hintText: 'e.g., 123 Main St, Nairobi',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional property details...',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Features Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FeaturesEditor(
                    features: features,
                    onChanged: (newFeatures) => setState(() => features = newFeatures),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Marketing Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HugeIcon(
                            icon: AppIcons.marketing,
                            color: AppColors.primaryTeal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Marketing',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('List on Explore Page'),
                        subtitle: Text(
                          isListed 
                              ? 'Property is visible to potential tenants'
                              : 'Property is hidden from explore',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: isListed,
                        onChanged: (value) => setState(() => isListed = value),
                        activeColor: AppColors.primaryTeal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty || locationController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields')),
                            );
                            return;
                          }
                          
                          final updatedProperty = property.copyWith(
                            name: nameController.text,
                            type: selectedType,
                            locationText: locationController.text,
                            notes: notesController.text.isEmpty ? null : notesController.text,
                            features: features,
                            isListed: isListed,
                            updatedAt: DateTime.now(),
                          );
                          
                          await dataService.updateProperty(updatedProperty);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Property updated')),
                            );
                          }
                        },
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddUnitSheet(BuildContext context, DataService dataService, Property property) {
    final labelController = TextEditingController();
    final rentController = TextEditingController();
    final depositController = TextEditingController();
    String selectedType = 'Bedsitter';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
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
                  'Add New Unit',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Label *',
                    hintText: 'e.g., A1, B2, Shop-1',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Unit Type'),
                  items: ['Bedsitter', '1 Bedroom', '2 Bedroom', '3 Bedroom', 'Shop', 'Office']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Rent *',
                    prefixText: 'KES ',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: depositController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Deposit Amount',
                    prefixText: 'KES ',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (labelController.text.isEmpty || rentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill required fields')),
                        );
                        return;
                      }
                      
                      final unit = Unit(
                        id: const Uuid().v4(),
                        orgId: property.orgId,
                        propertyId: property.id,
                        unitLabel: labelController.text,
                        unitType: selectedType,
                        rentAmount: double.tryParse(rentController.text) ?? 0,
                        depositAmount: double.tryParse(depositController.text) ?? 0,
                        status: UnitStatus.vacant,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      
                      await dataService.addUnit(unit);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unit ${unit.unitLabel} added')),
                        );
                      }
                    },
                    child: const Text('Add Unit', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnitDetails(BuildContext context, DataService dataService, Property property, Unit unit, Lease? lease, dynamic tenant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Consumer<DataService>(
          builder: (context, ds, child) {
            // Get updated unit from service
            final currentUnit = ds.units.firstWhere(
              (u) => u.id == unit.id,
              orElse: () => unit,
            );
            final currentLease = ds.getActiveLeaseForUnit(currentUnit.id);
            final currentTenant = currentLease != null 
                ? ds.getTenantById(currentLease.tenantId)
                : null;
            
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
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
                  
                  // Unit Images
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Unit Photos',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (currentUnit.images.isNotEmpty)
                          Text(
                            '${currentUnit.images.length} photos',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ImageGallery(
                    images: currentUnit.images,
                    canEdit: true,
                    onAddImages: (filePaths) => ds.uploadUnitImages(currentUnit.id, filePaths),
                    onRemoveImage: (url) => ds.removeUnitImage(currentUnit.id, url),
                    height: 150,
                  ),
              
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentUnit.unitLabel,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUnit.unitType ?? 'Unit',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${Formatters.currency(currentUnit.rentAmount)}/month',
                                    style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: currentUnit.status == UnitStatus.vacant 
                                    ? AppColors.success.withAlpha(30)
                                    : currentUnit.status == UnitStatus.occupied
                                        ? AppColors.info.withAlpha(30)
                                        : AppColors.warning.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentUnit.statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: currentUnit.status == UnitStatus.vacant 
                                      ? AppColors.success
                                      : currentUnit.status == UnitStatus.occupied
                                          ? AppColors.info
                                          : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (currentLease != null && currentTenant != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lightSurfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                                  child: Text(
                                    currentTenant.initials,
                                    style: const TextStyle(color: AppColors.primaryTeal),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentTenant.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Since ${Formatters.shortDate(currentLease.startDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.lightOnSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push('${AppRoutes.addTicket}?unitId=${currentUnit.id}');
                                },
                                icon: const Icon(Icons.build_outlined),
                                label: const Text('Create Ticket'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (currentLease == null) {
                                    context.push('${AppRoutes.addLease}?unitId=${currentUnit.id}');
                                  } else {
                                    context.push('/tenants/${currentTenant?.id}');
                                  }
                                },
                                icon: Icon(
                                  currentLease == null ? Icons.add : Icons.person,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  currentLease == null ? 'Create Lease' : 'View Tenant',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Marketing Section for Unit
                        Builder(
                          builder: (context) {
                            // Get current property state to check if it's listed
                            final currentProperty = ds.getPropertyById(property.id) ?? property;
                            final willAppearInExplore = currentUnit.isListed && 
                                currentProperty.isListed && 
                                currentUnit.status == UnitStatus.vacant;
                            
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      HugeIcon(
                                        icon: AppIcons.marketing,
                                        color: AppColors.primaryTeal,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Marketing',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('List on Explore Page'),
                                    subtitle: Text(
                                      currentUnit.isListed 
                                          ? willAppearInExplore
                                              ? 'Unit is visible to potential tenants'
                                              : 'Listing enabled but unit won\'t appear (see below)'
                                          : 'Unit is hidden from explore',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: currentUnit.isListed && !willAppearInExplore 
                                            ? AppColors.warning 
                                            : null,
                                      ),
                                    ),
                                    value: currentUnit.isListed,
                                    onChanged: (value) async {
                                      final updatedUnit = currentUnit.copyWith(
                                        isListed: value,
                                        updatedAt: DateTime.now(),
                                      );
                                      await ds.updateUnit(updatedUnit);
                                    },
                                    activeColor: AppColors.primaryTeal,
                                  ),
                                  // Show warnings if unit won't appear
                                  if (currentUnit.isListed && !willAppearInExplore) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Unit won\'t appear in Explore because:',
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (!currentProperty.isListed)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8, top: 2),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.close, size: 14, color: AppColors.error),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'Property is not listed (enable in property settings)',
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (currentUnit.status != UnitStatus.vacant)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8, top: 2),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.close, size: 14, color: AppColors.error),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'Unit is not vacant (status: ${currentUnit.statusLabel})',
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
