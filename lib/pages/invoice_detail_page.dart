import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/utils/formatters.dart';

class InvoiceDetailPage extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final invoice = dataService.getInvoiceById(invoiceId);
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice Not Found')),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        final tenant = dataService.getTenantById(invoice.tenantId);
        final unit = dataService.getUnitById(invoice.unitId);
        final property = dataService.getPropertyById(invoice.propertyId);

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Invoice', style: TextStyle(color: Colors.white, fontSize: 18)),
                Text(
                  invoice.periodLabel,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              if (invoice.status == InvoiceStatus.open)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'void') {
                      _showVoidDialog(context, dataService, invoice);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'void',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Void Invoice'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getStatusColor(invoice.status).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(invoice.status),
                      color: _getStatusColor(invoice.status),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.statusLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(invoice.status),
                            ),
                          ),
                          if (invoice.isOverdue)
                            Text(
                              Formatters.daysUntil(invoice.dueDate),
                              style: const TextStyle(color: AppColors.error),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(invoice.totalAmount),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(invoice.status),
                          ),
                        ),
                        if (invoice.balanceAmount > 0 && invoice.balanceAmount < invoice.totalAmount)
                          Text(
                            'Bal: ${Formatters.currency(invoice.balanceAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Invoice Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(label: 'Tenant', value: tenant?.fullName ?? 'Unknown'),
                    _DetailRow(label: 'Property', value: property?.name ?? 'Unknown'),
                    _DetailRow(label: 'Unit', value: unit?.unitLabel ?? 'Unknown'),
                    _DetailRow(label: 'Period', value: '${Formatters.shortDate(invoice.periodStart)} - ${Formatters.shortDate(invoice.periodEnd)}'),
                    _DetailRow(label: 'Due Date', value: Formatters.date(invoice.dueDate)),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Line Items
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Line Items',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...invoice.lines.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getChargeIcon(line.chargeType),
                              size: 20,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.description,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  line.chargeType,
                                  style: TextStyle(
                                    fontSize: 12,
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
                                Formatters.currency(line.amount),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (line.balanceAmount > 0 && line.balanceAmount < line.amount)
                                Text(
                                  'Bal: ${Formatters.currency(line.balanceAmount)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          Formatters.currency(invoice.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (invoice.balanceAmount > 0 && invoice.balanceAmount < invoice.totalAmount) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Balance Due',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            Formatters.currency(invoice.balanceAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
          bottomNavigationBar: invoice.status == InvoiceStatus.open
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('${AppRoutes.addPayment}?tenantId=${invoice.tenantId}'),
                      icon: const Icon(Icons.add_card, color: Colors.white),
                      label: const Text('Record Payment', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.open: return AppColors.warning;
      case InvoiceStatus.paid: return AppColors.success;
      case InvoiceStatus.void_: return AppColors.lightOnSurfaceVariant;
    }
  }

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.open: return Icons.pending_outlined;
      case InvoiceStatus.paid: return Icons.check_circle_outlined;
      case InvoiceStatus.void_: return Icons.cancel_outlined;
    }
  }

  IconData _getChargeIcon(String chargeType) {
    switch (chargeType.toLowerCase()) {
      case 'rent': return Icons.home_outlined;
      case 'water': return Icons.water_drop_outlined;
      case 'garbage': return Icons.delete_outline;
      case 'electricity': return Icons.bolt_outlined;
      case 'parking': return Icons.local_parking_outlined;
      default: return Icons.receipt_outlined;
    }
  }

  void _showVoidDialog(BuildContext context, DataService dataService, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Invoice?'),
        content: const Text('This action cannot be undone. Are you sure you want to void this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final voided = invoice.copyWith(
                status: InvoiceStatus.void_,
                updatedAt: DateTime.now(),
              );
              await dataService.updateInvoice(voided);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice voided')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Void Invoice', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.lightOnSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
