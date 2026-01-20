import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/utils/formatters.dart';

class TenantPaymentsPage extends StatelessWidget {
  const TenantPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final tenantId = authService.tenantLinks.isNotEmpty ? authService.tenantLinks.first.tenantId : null;

    if (tenantId == null) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          title: const Text('My Payments', style: TextStyle(color: Colors.white)),
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
        final payments = dataService.payments.where((p) => p.tenantId == tenantId).toList()
          ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('My Payments', style: TextStyle(color: Colors.white)),
          ),
          body: payments.isEmpty
              ? const EmptyState(
                  icon: Icons.payment,
                  title: 'No Payments',
                  message: 'You haven\'t made any payments yet.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PaymentCard(payment: payment),
                    );
                  },
                ),
        );
      },
    );
  }
}

class PaymentCard extends StatelessWidget {
  final Payment payment;

  const PaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getMethodIcon(payment.method),
                    color: AppColors.primaryTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.currency(payment.amount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.date(payment.paidAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(payment: payment),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.payment,
              label: 'Method',
              value: payment.methodLabel,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.receipt,
              label: 'Reference',
              value: payment.reference,
            ),
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.notes,
                label: 'Notes',
                value: payment.notes!,
              ),
            ],
            if (payment.status != PaymentStatus.allocated) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payment.status == PaymentStatus.unallocated
                            ? 'This payment has not been allocated to any invoice yet.'
                            : 'Unallocated: ${Formatters.currency(payment.unallocatedAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return Icons.phone_android;
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.bank:
        return Icons.account_balance;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final Payment payment;

  const _StatusBadge({required this.payment});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (payment.status) {
      case PaymentStatus.allocated:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case PaymentStatus.partiallyAllocated:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        icon = Icons.pending;
        break;
      case PaymentStatus.unallocated:
        backgroundColor = AppColors.lightOnSurfaceVariant.withValues(alpha: 0.1);
        textColor = AppColors.lightOnSurfaceVariant;
        icon = Icons.radio_button_unchecked;
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
            payment.statusLabel,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.lightOnSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.lightOnSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
