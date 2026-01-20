import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/components/list_cards.dart';

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
                onPressed: () {},
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Property Info Card
              Container(
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
              
              const SizedBox(height: 16),
              
              // Stats Row
              Row(
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
              
              const SizedBox(height: 24),
              
              // Units Header
              Row(
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
              
              const SizedBox(height: 8),
              
              // Units List
              if (units.isEmpty)
                Container(
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
              else
                ...units.map((unit) {
                  final lease = dataService.getActiveLeaseForUnit(unit.id);
                  final tenant = lease != null ? dataService.getTenantById(lease.tenantId) : null;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: UnitCard(
                      unit: unit,
                      tenantName: tenant?.fullName,
                      onTap: () => _showUnitDetails(context, dataService, unit, lease, tenant),
                    ),
                  );
                }),
              
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

  void _showUnitDetails(BuildContext context, DataService dataService, Unit unit, Lease? lease, dynamic tenant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                          unit.unitLabel,
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
                              unit.unitType ?? 'Unit',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              Formatters.currency(unit.rentAmount) + '/month',
                              style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (lease != null && tenant != null) ...[
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
                              tenant.initials,
                              style: const TextStyle(color: AppColors.primaryTeal),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Since ${Formatters.shortDate(lease.startDate)}',
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
                            context.push('${AppRoutes.addTicket}?unitId=${unit.id}');
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
                            if (lease == null) {
                              context.push('${AppRoutes.addLease}?unitId=${unit.id}');
                            } else {
                              context.push('/tenants/${tenant.id}');
                            }
                          },
                          icon: Icon(
                            lease == null ? Icons.add : Icons.person,
                            color: Colors.white,
                          ),
                          label: Text(
                            lease == null ? 'Create Lease' : 'View Tenant',
                            style: const TextStyle(color: Colors.white),
                          ),
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
