import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/empty_state.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  String _searchQuery = '';
  PaymentMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        var filteredPayments = dataService.payments.toList();
        
        if (_selectedMethod != null) {
          filteredPayments = filteredPayments.where((p) => p.method == _selectedMethod).toList();
        }
        
        if (_searchQuery.isNotEmpty) {
          filteredPayments = filteredPayments.where((p) {
            final tenant = dataService.getTenantById(p.tenantId ?? '');
            return (tenant?.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                   p.reference.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
        
        filteredPayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text('Payments', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => context.push(AppRoutes.addPayment),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search by tenant or reference...',
                        prefixIcon: Icon(Icons.search, color: AppColors.lightOnSurfaceVariant),
                        filled: true,
                        fillColor: AppColors.lightSurfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            isSelected: _selectedMethod == null,
                            onTap: () => setState(() => _selectedMethod = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'M-Pesa',
                            icon: Icons.phone_android,
                            isSelected: _selectedMethod == PaymentMethod.mpesa,
                            onTap: () => setState(() => _selectedMethod = PaymentMethod.mpesa),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Cash',
                            icon: Icons.payments_outlined,
                            isSelected: _selectedMethod == PaymentMethod.cash,
                            onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Bank',
                            icon: Icons.account_balance_outlined,
                            isSelected: _selectedMethod == PaymentMethod.bank,
                            onTap: () => setState(() => _selectedMethod = PaymentMethod.bank),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredPayments.isEmpty
                    ? EmptyState(
                        icon: Icons.payment,
                        title: 'No Payments',
                        message: _searchQuery.isEmpty && _selectedMethod == null
                            ? 'Record your first payment'
                            : 'Try different filters',
                        actionLabel: _searchQuery.isEmpty ? 'Record Payment' : null,
                        onAction: () => context.push(AppRoutes.addPayment),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = filteredPayments[index];
                          final tenant = dataService.getTenantById(payment.tenantId ?? '');
                          return PaymentCard(
                            payment: payment,
                            tenantName: tenant?.fullName ?? 'Unknown',
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.addPayment),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.lightOnSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
