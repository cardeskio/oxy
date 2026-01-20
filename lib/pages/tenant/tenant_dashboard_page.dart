import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/components/stat_card.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/models/payment.dart';
import 'package:oxy/models/lease.dart';

class TenantDashboardPage extends StatelessWidget {
  const TenantDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final dataService = context.watch<DataService>();

    if (authService.tenantLinks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('No tenant account linked')),
      );
    }

    final tenantLink = authService.tenantLinks.first;
    final tenant = dataService.getTenantById(tenantLink.tenantId);
    final activeLease = dataService.getActiveLeaseForTenant(tenantLink.tenantId);
    
    if (tenant == null || activeLease == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('No active lease found')),
      );
    }

    final property = dataService.getPropertyById(activeLease.propertyId);
    final unit = dataService.getUnitById(activeLease.unitId);
    final tenantInvoices = dataService.getInvoicesForTenant(tenant.id);
    final tenantPayments = dataService.getPaymentsForTenant(tenant.id);

    final openInvoices = tenantInvoices.where((i) => i.status == InvoiceStatus.open).toList();
    final totalBalance = openInvoices.fold(0.0, (sum, i) => sum + i.balanceAmount);
    
    final nextDueInvoice = openInvoices.isNotEmpty
        ? openInvoices.reduce((a, b) => a.dueDate.isBefore(b.dueDate) ? a : b)
        : null;

    final recentActivity = _getRecentActivity(tenantInvoices, tenantPayments);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Rental'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dataService.refresh(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRentalSummaryCard(context, property?.name ?? 'Unknown Property', unit?.unitLabel ?? 'Unknown Unit', activeLease.rentAmount),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Balance Due',
                      value: Formatters.currency(totalBalance),
                      icon: Icons.account_balance_wallet,
                      iconColor: totalBalance > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: nextDueInvoice != null ? 'Next Due' : 'No Pending Bills',
                      value: nextDueInvoice != null ? Formatters.shortDate(nextDueInvoice.dueDate) : '-',
                      icon: Icons.calendar_today,
                      iconColor: AppColors.info,
                      subtitle: nextDueInvoice != null ? Formatters.daysUntil(nextDueInvoice.dueDate) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  QuickActionCard(
                    title: 'View Invoices',
                    icon: Icons.receipt_long,
                    color: AppColors.primaryTeal,
                    onTap: () {},
                  ),
                  QuickActionCard(
                    title: 'View Payments',
                    icon: Icons.payment,
                    color: AppColors.success,
                    onTap: () {},
                  ),
                  QuickActionCard(
                    title: 'Report Issue',
                    icon: Icons.build,
                    color: AppColors.warning,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (recentActivity.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...recentActivity.map((activity) => _buildActivityItem(context, activity)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRentalSummaryCard(BuildContext context, String propertyName, String unitName, double rentAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryTeal, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            propertyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unitName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Monthly Rent:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.currency(rentAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getRecentActivity(List<Invoice> invoices, List<Payment> payments) {
    final activities = <Map<String, dynamic>>[];
    
    for (final invoice in invoices) {
      activities.add({
        'type': 'invoice',
        'date': invoice.createdAt,
        'data': invoice,
      });
    }
    
    for (final payment in payments) {
      activities.add({
        'type': 'payment',
        'date': payment.paidAt,
        'data': payment,
      });
    }
    
    activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return activities.take(3).toList();
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final date = activity['date'] as DateTime;
    
    final IconData icon;
    final Color iconColor;
    final String title;
    final String subtitle;
    final String amount;
    
    if (type == 'invoice') {
      final invoice = activity['data'] as Invoice;
      icon = Icons.receipt_long;
      iconColor = invoice.status == InvoiceStatus.paid ? AppColors.success : AppColors.warning;
      title = 'Invoice ${invoice.periodLabel}';
      subtitle = invoice.statusLabel;
      amount = Formatters.currency(invoice.totalAmount);
    } else {
      final payment = activity['data'] as Payment;
      icon = Icons.payment;
      iconColor = AppColors.success;
      title = 'Payment Received';
      subtitle = Formatters.relativeDate(date);
      amount = Formatters.currency(payment.amount);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: type == 'payment' ? AppColors.success : AppColors.lightOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}
