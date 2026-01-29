import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/unit_charge.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/org_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/formatters.dart';

class ChargesManagementPage extends StatefulWidget {
  const ChargesManagementPage({super.key});

  @override
  State<ChargesManagementPage> createState() => _ChargesManagementPageState();
}

class _ChargesManagementPageState extends State<ChargesManagementPage> {
  String? _selectedPropertyId;
  bool _isGenerating = false;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 5));
  
  // Controllers for each cell: unitId -> chargeTypeId -> controller
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Map<String, Map<String, bool>> _pendingSaves = {};
  
  @override
  void dispose() {
    for (final unitControllers in _controllers.values) {
      for (final controller in unitControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  TextEditingController _getController(UnitChargeSummary summary, UnitChargeEntry entry) {
    _controllers[summary.unitId] ??= {};
    if (!_controllers[summary.unitId]!.containsKey(entry.chargeTypeId)) {
      final controller = TextEditingController(text: entry.amount.toStringAsFixed(0));
      _controllers[summary.unitId]![entry.chargeTypeId] = controller;
    }
    return _controllers[summary.unitId]![entry.chargeTypeId]!;
  }

  void _markPendingSave(String unitId, String chargeTypeId, bool pending) {
    _pendingSaves[unitId] ??= {};
    _pendingSaves[unitId]![chargeTypeId] = pending;
    setState(() {});
  }

  bool _isPendingSave(String unitId, String chargeTypeId) {
    return _pendingSaves[unitId]?[chargeTypeId] ?? false;
  }

  Future<void> _saveCharge(UnitChargeSummary summary, UnitChargeEntry entry, double newAmount) async {
    final dataService = context.read<DataService>();
    _markPendingSave(summary.unitId, entry.chargeTypeId, true);
    
    try {
      await dataService.upsertUnitCharge(
        unitId: summary.unitId,
        chargeTypeId: entry.chargeTypeId,
        amount: newAmount,
        isEnabled: entry.isEnabled,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      _markPendingSave(summary.unitId, entry.chargeTypeId, false);
    }
  }

  Future<void> _generateInvoices() async {
    final dataService = context.read<DataService>();
    
    setState(() => _isGenerating = true);
    
    try {
      final invoices = await dataService.generateBulkInvoices(
        dueDate: _selectedDueDate,
        propertyId: _selectedPropertyId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${invoices.length} invoices'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final orgService = context.watch<OrgService>();
    final summaries = dataService.getUnitChargeSummaries(propertyId: _selectedPropertyId);
    final chargeTypes = orgService.chargeTypes.where((c) => c.isRecurring && c.name.toLowerCase() != 'rent').toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Charges Management', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => dataService.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Actions Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedPropertyId,
                        decoration: const InputDecoration(
                          labelText: 'Property',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Properties')),
                          ...dataService.properties.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          )),
                        ],
                        onChanged: (value) => setState(() => _selectedPropertyId = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _selectDueDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text('Due: ${Formatters.date(_selectedDueDate)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${summaries.length} units with active tenants',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: summaries.isEmpty || _isGenerating ? null : _generateInvoices,
                      icon: _isGenerating 
                          ? const SizedBox(
                              width: 18, 
                              height: 18, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.receipt_long, size: 18),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate Invoices'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Spreadsheet-like table
          Expanded(
            child: summaries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work_outlined, size: 64, color: AppColors.lightOnSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No occupied units',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add tenants with active leases to manage charges',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 12,
                        horizontalMargin: 16,
                        headingRowColor: WidgetStateProperty.all(AppColors.lightSurfaceVariant),
                        columns: [
                          const DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Tenant', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataColumn(
                            label: Text('Rent', style: TextStyle(fontWeight: FontWeight.bold)),
                            numeric: true,
                          ),
                          ...chargeTypes.map((ct) => DataColumn(
                            label: Text(ct.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            numeric: true,
                          )),
                          const DataColumn(
                            label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                            numeric: true,
                          ),
                        ],
                        rows: summaries.map((summary) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      summary.unitLabel,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      summary.propertyName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.lightOnSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  summary.tenantName ?? '-',
                                  style: TextStyle(
                                    color: summary.tenantName != null ? null : AppColors.lightOnSurfaceVariant,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  Formatters.compactCurrency(summary.rentAmount),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              ...chargeTypes.map((ct) {
                                final entry = summary.charges[ct.id];
                                if (entry == null) {
                                  return const DataCell(Text('-'));
                                }
                                
                                final controller = _getController(summary, entry);
                                final isPending = _isPendingSave(summary.unitId, entry.chargeTypeId);
                                
                                return DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: TextStyle(
                                        fontWeight: entry.isCustom ? FontWeight.bold : FontWeight.normal,
                                        color: entry.isCustom ? AppColors.primaryTeal : null,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                            color: entry.isCustom ? AppColors.primaryTeal.withAlpha(100) : Colors.grey.shade300,
                                          ),
                                        ),
                                        suffixIcon: isPending
                                            ? const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        final newAmount = double.tryParse(value) ?? 0;
                                        if (newAmount != entry.amount) {
                                          // Debounce save
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            if (controller.text == value) {
                                              _saveCharge(summary, entry, newAmount);
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    Formatters.compactCurrency(summary.totalCharges),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
