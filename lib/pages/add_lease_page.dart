import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/lease.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/utils/formatters.dart';

class AddLeasePage extends StatefulWidget {
  final String? unitId;
  final String? tenantId;
  const AddLeasePage({super.key, this.unitId, this.tenantId});

  @override
  State<AddLeasePage> createState() => _AddLeasePageState();
}

class _AddLeasePageState extends State<AddLeasePage> {
  final _formKey = GlobalKey<FormState>();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _lateFeeController = TextEditingController();
  
  String? _selectedUnitId;
  String? _selectedTenantId;
  DateTime _startDate = DateTime.now();
  int _dueDay = 1;
  int _graceDays = 5;
  LateFeeType _lateFeeType = LateFeeType.none;
  LeaseStatus _status = LeaseStatus.active;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.unitId;
    _selectedTenantId = widget.tenantId;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedUnitId != null) {
        final dataService = context.read<DataService>();
        final unit = dataService.getUnitById(_selectedUnitId!);
        if (unit != null) {
          _rentController.text = unit.rentAmount.toStringAsFixed(0);
          _depositController.text = unit.depositAmount.toStringAsFixed(0);
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    _lateFeeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null || _selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select unit and tenant')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final dataService = context.read<DataService>();
      final unit = dataService.getUnitById(_selectedUnitId!);
      
      final orgId = dataService.currentOrgId ?? '';
      
      final lease = Lease(
        id: const Uuid().v4(),
        orgId: orgId,
        unitId: _selectedUnitId!,
        tenantId: _selectedTenantId!,
        propertyId: unit?.propertyId ?? '',
        startDate: _startDate,
        rentAmount: double.tryParse(_rentController.text) ?? 0,
        depositAmount: double.tryParse(_depositController.text) ?? 0,
        dueDay: _dueDay,
        graceDays: _graceDays,
        lateFeeType: _lateFeeType,
        lateFeeValue: _lateFeeType != LateFeeType.none ? double.tryParse(_lateFeeController.text) : null,
        status: _status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dataService.addLease(lease);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lease created successfully')),
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
        final vacantUnits = dataService.units.where((u) => u.status == UnitStatus.vacant).toList();
        final tenants = dataService.tenants;
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text('Create Lease', style: TextStyle(color: Colors.white)),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Unit & Tenant Selection
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
                        'Lease Assignment',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedUnitId,
                        decoration: const InputDecoration(labelText: 'Select Unit *'),
                        items: vacantUnits.map((unit) {
                          final property = dataService.getPropertyById(unit.propertyId);
                          return DropdownMenuItem(
                            value: unit.id,
                            child: Text('${property?.name ?? ""} - ${unit.unitLabel}'),
                          );
                        }).toList(),
                        onChanged: widget.unitId != null ? null : (value) {
                          setState(() => _selectedUnitId = value);
                          if (value != null) {
                            final unit = dataService.getUnitById(value);
                            if (unit != null) {
                              _rentController.text = unit.rentAmount.toStringAsFixed(0);
                              _depositController.text = unit.depositAmount.toStringAsFixed(0);
                            }
                          }
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedTenantId,
                        decoration: const InputDecoration(labelText: 'Select Tenant *'),
                        items: tenants.map((tenant) {
                          return DropdownMenuItem(
                            value: tenant.id,
                            child: Text(tenant.fullName),
                          );
                        }).toList(),
                        onChanged: widget.tenantId != null ? null : (value) {
                          setState(() => _selectedTenantId = value);
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lease Terms
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
                        'Lease Terms',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setState(() => _startDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(Formatters.date(_startDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rentController,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Rent *',
                                prefixText: 'KES ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _depositController,
                              decoration: const InputDecoration(
                                labelText: 'Deposit',
                                prefixText: 'KES ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _dueDay,
                              decoration: const InputDecoration(labelText: 'Due Day'),
                              items: List.generate(28, (i) => i + 1).map((day) {
                                return DropdownMenuItem(
                                  value: day,
                                  child: Text('${day}${_getDaySuffix(day)}'),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _dueDay = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _graceDays,
                              decoration: const InputDecoration(labelText: 'Grace Days'),
                              items: List.generate(15, (i) => i).map((day) {
                                return DropdownMenuItem(
                                  value: day,
                                  child: Text('$day days'),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _graceDays = value!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Late Fee
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
                        'Late Fee',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<LateFeeType>(
                        value: _lateFeeType,
                        decoration: const InputDecoration(labelText: 'Late Fee Type'),
                        items: const [
                          DropdownMenuItem(value: LateFeeType.none, child: Text('No Late Fee')),
                          DropdownMenuItem(value: LateFeeType.fixed, child: Text('Fixed Amount')),
                          DropdownMenuItem(value: LateFeeType.percent, child: Text('Percentage of Rent')),
                        ],
                        onChanged: (value) => setState(() => _lateFeeType = value!),
                      ),
                      if (_lateFeeType != LateFeeType.none) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lateFeeController,
                          decoration: InputDecoration(
                            labelText: 'Late Fee Value',
                            prefixText: _lateFeeType == LateFeeType.fixed ? 'KES ' : null,
                            suffixText: _lateFeeType == LateFeeType.percent ? '%' : null,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status
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
                        'Lease Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _status = LeaseStatus.draft),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _status == LeaseStatus.draft
                                      ? AppColors.warning.withValues(alpha: 0.1)
                                      : AppColors.lightSurfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: _status == LeaseStatus.draft
                                      ? Border.all(color: AppColors.warning)
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      color: _status == LeaseStatus.draft ? AppColors.warning : AppColors.lightOnSurfaceVariant,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Draft',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _status == LeaseStatus.draft ? AppColors.warning : AppColors.lightOnSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _status = LeaseStatus.active),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _status == LeaseStatus.active
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.lightSurfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: _status == LeaseStatus.active
                                      ? Border.all(color: AppColors.success)
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outlined,
                                      color: _status == LeaseStatus.active ? AppColors.success : AppColors.lightOnSurfaceVariant,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _status == LeaseStatus.active ? AppColors.success : AppColors.lightOnSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_status == LeaseStatus.active)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '⚡ Unit will be marked as occupied',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                            ),
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
                    : const Text('Create Lease', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}
