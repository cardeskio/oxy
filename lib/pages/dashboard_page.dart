import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/utils/icons.dart';
import 'package:oxy/components/stat_card.dart';
import 'package:oxy/components/list_cards.dart';
import 'package:oxy/components/loading_indicator.dart';
import 'package:oxy/components/notification_badge.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        if (dataService.isLoading) {
          return const Scaffold(
            body: OxyLoadingOverlay(message: 'Loading dashboard...'),
          );
        }
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            elevation: 0,
            centerTitle: false,
            title: Text(
              'Oxy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: const [
              NotificationBadge(),
              SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Expected Rent',
                    value: Formatters.compactCurrency(dataService.totalExpectedRent),
                    icon: AppIcons.trending,
                    iconColor: AppColors.primaryTeal,
                  ),
                  StatCard(
                    title: 'Collected',
                    value: Formatters.compactCurrency(dataService.totalCollected),
                    icon: AppIcons.wallet,
                    iconColor: AppColors.success,
                    subtitle: 'This month',
                  ),
                  StatCard(
                    title: 'Arrears',
                    value: Formatters.compactCurrency(dataService.totalArrears),
                    icon: AppIcons.warning,
                    iconColor: AppColors.error,
                    onTap: () => context.go(AppRoutes.invoices),
                  ),
                  StatCard(
                    title: 'Occupancy',
                    value: '${dataService.occupancyRate.toStringAsFixed(0)}%',
                    icon: AppIcons.property,
                    iconColor: AppColors.info,
                    subtitle: '${dataService.units.where((u) => u.status == UnitStatus.occupied).length}/${dataService.units.length} units',
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickActionCard(
                      title: 'Add Payment',
                      icon: AppIcons.payment,
                      color: AppColors.success,
                      onTap: () => context.push(AppRoutes.addPayment),
                    ),
                    const SizedBox(width: 12),
                    QuickActionCard(
                      title: 'New Tenant',
                      icon: AppIcons.person,
                      color: AppColors.info,
                      onTap: () => context.push(AppRoutes.addTenant),
                    ),
                    const SizedBox(width: 12),
                    QuickActionCard(
                      title: 'Maintenance',
                      icon: AppIcons.maintenance,
                      color: AppColors.warning,
                      onTap: () => context.push(AppRoutes.addTicket),
                    ),
                    const SizedBox(width: 12),
                    QuickActionCard(
                      title: 'Add Property',
                      icon: AppIcons.property,
                      color: Colors.purple,
                      onTap: () => context.push(AppRoutes.addProperty),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Recent Payments Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Payments',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.payments),
                    child: const Text('View All'),
                  ),
                ],
              ),
              
              // Recent payments list
              if (dataService.payments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      HugeIcon(icon: AppIcons.payment, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No payments yet',
                        style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                ...() {
                  final payments = dataService.payments.toList()
                    ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
                  return payments.take(5).map((payment) {
                    final tenant = dataService.getTenantById(payment.tenantId ?? '');
                    return PaymentCard(
                      payment: payment,
                      tenantName: tenant?.fullName ?? 'Unknown',
                      onTap: () {},
                    );
                  }).toList();
                }(),
              
              const SizedBox(height: 16),
              
              // Open Tickets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Open Tickets',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (dataService.openTicketsCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${dataService.openTicketsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.maintenance),
                    child: const Text('View All'),
                  ),
                ],
              ),
              
              // Open tickets list
              if (dataService.tickets.where((t) => t.status != TicketStatus.approved && t.status != TicketStatus.rejected).isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      HugeIcon(icon: AppIcons.success, size: 48, color: AppColors.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No open tickets',
                        style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                ...() {
                  final openTickets = dataService.tickets
                      .where((t) => 
                        t.status == TicketStatus.new_ || 
                        t.status == TicketStatus.assigned || 
                        t.status == TicketStatus.inProgress
                      )
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  return openTickets.take(3).map((ticket) {
                    final unit = dataService.getUnitById(ticket.unitId);
                    return TicketCard(
                      ticket: ticket,
                      unitLabel: unit?.unitLabel ?? 'Unknown',
                      onTap: () => context.push(AppRoutes.maintenance),
                    );
                  }).toList();
                }(),
            ],
          ),
        );
      },
    );
  }
}
