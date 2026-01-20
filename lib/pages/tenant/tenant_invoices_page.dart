import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/utils/formatters.dart';

class TenantInvoicesPage extends StatefulWidget {
  const TenantInvoicesPage({super.key});

  @override
  State<TenantInvoicesPage> createState() => _TenantInvoicesPageState();
}

class _TenantInvoicesPageState extends State<TenantInvoicesPage> {
  InvoiceStatus? _selectedStatus;

  String _getStatusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.open:
        return 'Open';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.void_:
        return 'Void';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final tenantId = authService.tenantLinks.isNotEmpty ? authService.tenantLinks.first.tenantId : null;

    if (tenantId == null) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          title: const Text('My Invoices', style: TextStyle(color: Colors.white)),
        ),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'No Tenant Access',
          message: 'You are not linked to any tenant account.',
        ),
      );
    }

    return Consumer<DataService>(
      builder: (context, dataService, _) {
        var filteredInvoices = dataService.invoices.where((i) => i.tenantId == tenantId).toList();

        if (_selectedStatus != null) {
          filteredInvoices = filteredInvoices.where((i) => i.status == _selectedStatus).toList();
        }

        filteredInvoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final openCount = dataService.invoices.where((i) => i.tenantId == tenantId && i.status == InvoiceStatus.open).length;
        final paidCount = dataService.invoices.where((i) => i.tenantId == tenantId && i.status == InvoiceStatus.paid).length;

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('My Invoices', style: TextStyle(color: Colors.white)),
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedStatus == null,
                        onTap: () => setState(() => _selectedStatus = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Open ($openCount)',
                        icon: Icons.pending_outlined,
                        isSelected: _selectedStatus == InvoiceStatus.open,
                        onTap: () => setState(() => _selectedStatus = InvoiceStatus.open),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Paid ($paidCount)',
                        icon: Icons.check_circle_outline,
                        isSelected: _selectedStatus == InvoiceStatus.paid,
                        onTap: () => setState(() => _selectedStatus = InvoiceStatus.paid),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filteredInvoices.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: _selectedStatus == null ? 'No Invoices' : 'No ${_getStatusLabel(_selectedStatus!)} Invoices',
                        message: _selectedStatus == null
                            ? 'You don\'t have any invoices yet.'
                            : 'You don\'t have any ${_getStatusLabel(_selectedStatus!).toLowerCase()} invoices.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InvoiceCard(invoice: invoice),
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

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const InvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/invoices/${invoice.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.periodLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusChip(invoice: invoice),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.payments, size: 16, color: AppColors.lightOnSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.currency(invoice.totalAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.lightOnSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${Formatters.date(invoice.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: invoice.isOverdue ? AppColors.error : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                  if (invoice.isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (invoice.balanceAmount > 0 && invoice.balanceAmount < invoice.totalAmount) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Balance: ${Formatters.currency(invoice.balanceAmount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Invoice invoice;

  const _StatusChip({required this.invoice});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (invoice.status) {
      case InvoiceStatus.open:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        icon = Icons.pending;
        break;
      case InvoiceStatus.paid:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case InvoiceStatus.void_:
        backgroundColor = AppColors.lightOnSurfaceVariant.withValues(alpha: 0.1);
        textColor = AppColors.lightOnSurfaceVariant;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            invoice.statusLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.lightOnSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.lightOnSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
