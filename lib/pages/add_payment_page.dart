import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/utils/formatters.dart';

class AddPaymentPage extends StatefulWidget {
  final String? tenantId;
  const AddPaymentPage({super.key, this.tenantId});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedTenantId;
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  DateTime _paidAt = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTenantId = widget.tenantId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tenant')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final dataService = context.read<DataService>();
      final lease = dataService.getActiveLeaseForTenant(_selectedTenantId!);
      
      final orgId = dataService.currentOrgId ?? '';
      
      final payment = Payment(
        id: const Uuid().v4(),
        orgId: orgId,
        tenantId: _selectedTenantId,
        leaseId: lease?.id,
        unitId: lease?.unitId,
        amount: double.tryParse(_amountController.text) ?? 0,
        method: _selectedMethod,
        reference: _referenceController.text.trim().isEmpty 
            ? '${_selectedMethod.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}'
            : _referenceController.text.trim(),
        paidAt: _paidAt,
        capturedBy: 'Manager',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: PaymentStatus.unallocated,
        allocations: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dataService.addPayment(payment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment of ${Formatters.currency(payment.amount)} recorded')),
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
        final tenants = dataService.tenants;
        List<Invoice> openInvoices = [];
        if (_selectedTenantId != null) {
          openInvoices = dataService.getInvoicesForTenant(_selectedTenantId!)
              .where((i) => i.status == InvoiceStatus.open)
              .toList();
        }
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text('Record Payment', style: TextStyle(color: Colors.white)),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                        'Payment Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          prefixText: 'KES ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if ((double.tryParse(value!) ?? 0) <= 0) return 'Invalid amount';
                          return null;
                        },
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Open Invoices
                if (_selectedTenantId != null && openInvoices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(
                              'Open Invoices',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...openInvoices.take(3).map((invoice) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(invoice.periodLabel),
                              Text(
                                Formatters.currency(invoice.balanceAmount),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Outstanding', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              Formatters.currency(openInvoices.fold(0.0, (sum, i) => sum + i.balanceAmount)),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Payment Method
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
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _MethodChip(
                            label: 'M-Pesa',
                            icon: Icons.phone_android,
                            isSelected: _selectedMethod == PaymentMethod.mpesa,
                            onTap: () => setState(() => _selectedMethod = PaymentMethod.mpesa),
                          ),
                          const SizedBox(width: 12),
                          _MethodChip(
                            label: 'Cash',
                            icon: Icons.payments_outlined,
                            isSelected: _selectedMethod == PaymentMethod.cash,
                            onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
                          ),
                          const SizedBox(width: 12),
                          _MethodChip(
                            label: 'Bank',
                            icon: Icons.account_balance_outlined,
                            isSelected: _selectedMethod == PaymentMethod.bank,
                            onTap: () => setState(() => _selectedMethod = PaymentMethod.bank),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: _selectedMethod == PaymentMethod.mpesa 
                              ? 'M-Pesa Code *' 
                              : 'Reference',
                          hintText: _selectedMethod == PaymentMethod.mpesa 
                              ? 'e.g., RAH4K7N9M2' 
                              : 'Receipt number',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (_selectedMethod == PaymentMethod.mpesa && (value?.isEmpty ?? true)) {
                            return 'M-Pesa code required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _paidAt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _paidAt = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(Formatters.date(_paidAt)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                        ),
                        maxLines: 2,
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
                    : const Text('Record Payment', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.icon,
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
            color: isSelected ? AppColors.primaryTeal.withValues(alpha: 0.1) : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: AppColors.primaryTeal) : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryTeal : AppColors.lightOnSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primaryTeal : AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
