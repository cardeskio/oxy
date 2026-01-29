import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/utils/formatters.dart';

class TenantPaymentsPage extends StatelessWidget {
  const TenantPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantService>(
      builder: (context, tenantService, _) {
        if (tenantService.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: AppColors.primaryTeal,
              title: const Text('My Payments', style: TextStyle(color: Colors.white)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (tenantService.currentTenant == null) {
          return Scaffold(
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: AppColors.primaryTeal,
              title: const Text('My Payments', style: TextStyle(color: Colors.white)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 24),
                    Text(
                      'Not Linked Yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ll have access to payment history once you\'re linked to a property. Browse available properties or share your claim code with a property manager.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/tenant/explore'),
                      icon: const Icon(Icons.search),
                      label: const Text('Explore Properties'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final payments = tenantService.payments.toList()
          ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('My Payments', style: TextStyle(color: Colors.white)),
          ),
          body: RefreshIndicator(
            onRefresh: () => tenantService.refresh(),
            child: payments.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: EmptyState(
                        icon: Icons.payment,
                        title: 'No Payments',
                        message: 'You haven\'t made any payments yet.',
                      ),
                    ),
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
