import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/models/unit.dart';

class AddTicketPage extends StatefulWidget {
  final String? unitId;
  const AddTicketPage({super.key, this.unitId});

  @override
  State<AddTicketPage> createState() => _AddTicketPageState();
}

class _AddTicketPageState extends State<AddTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vendorNameController = TextEditingController();
  
  String? _selectedPropertyId;
  String? _selectedUnitId;
  TicketPriority _priority = TicketPriority.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.unitId;
    
    if (widget.unitId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dataService = context.read<DataService>();
        final unit = dataService.getUnitById(widget.unitId!);
        if (unit != null) {
          setState(() => _selectedPropertyId = unit.propertyId);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _vendorNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unit')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final dataService = context.read<DataService>();
      final unit = dataService.getUnitById(_selectedUnitId!);
      final lease = dataService.getActiveLeaseForUnit(_selectedUnitId!);
      
      final orgId = dataService.currentOrgId ?? '';
      
      final ticket = MaintenanceTicket(
        id: const Uuid().v4(),
        orgId: orgId,
        propertyId: unit?.propertyId ?? _selectedPropertyId ?? '',
        unitId: _selectedUnitId!,
        tenantId: lease?.tenantId,
        leaseId: lease?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        status: TicketStatus.new_,
        vendorName: _vendorNameController.text.trim().isEmpty ? null : _vendorNameController.text.trim(),
        costs: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dataService.addTicket(ticket);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final properties = dataService.properties;
        final units = _selectedPropertyId != null
            ? dataService.getUnitsForProperty(_selectedPropertyId!)
            : <Unit>[];
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text('Create Ticket', style: TextStyle(color: Colors.white)),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Location
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedPropertyId,
                        decoration: const InputDecoration(labelText: 'Select Property *'),
                        items: properties.map((property) {
                          return DropdownMenuItem(
                            value: property.id,
                            child: Text(property.name),
                          );
                        }).toList(),
                        onChanged: widget.unitId != null ? null : (value) {
                          setState(() {
                            _selectedPropertyId = value;
                            _selectedUnitId = null;
                          });
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedUnitId,
                        decoration: const InputDecoration(labelText: 'Select Unit *'),
                        items: units.map((unit) {
                          return DropdownMenuItem(
                            value: unit.id,
                            child: Text('${unit.unitLabel} - ${unit.unitType ?? "Unit"}'),
                          );
                        }).toList(),
                        onChanged: widget.unitId != null ? null : (value) {
                          setState(() => _selectedUnitId = value);
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Ticket Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g., Leaking tap in bathroom',
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Describe the issue in detail...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Priority
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _PriorityChip(
                            label: 'Low',
                            color: AppColors.success,
                            isSelected: _priority == TicketPriority.low,
                            onTap: () => setState(() => _priority = TicketPriority.low),
                          ),
                          const SizedBox(width: 12),
                          _PriorityChip(
                            label: 'Medium',
                            color: AppColors.warning,
                            isSelected: _priority == TicketPriority.medium,
                            onTap: () => setState(() => _priority = TicketPriority.medium),
                          ),
                          const SizedBox(width: 12),
                          _PriorityChip(
                            label: 'High',
                            color: AppColors.error,
                            isSelected: _priority == TicketPriority.high,
                            onTap: () => setState(() => _priority = TicketPriority.high),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Vendor Assignment (Optional)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor Assignment (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _vendorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor Name',
                          hintText: 'e.g., Musa Plumbing',
                          prefixIcon: Icon(Icons.handyman_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Ticket', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
