import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/unit.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/components/stat_card.dart';
import 'package:oxy/components/list_cards.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        if (dataService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryTeal,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PropManager',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        Formatters.monthYear(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          StatCard(
                            title: 'Expected Rent',
                            value: Formatters.compactCurrency(dataService.totalExpectedRent),
                            icon: Icons.trending_up,
                            iconColor: AppColors.primaryTeal,
                          ),
                          StatCard(
                            title: 'Collected',
                            value: Formatters.compactCurrency(dataService.totalCollected),
                            icon: Icons.account_balance_wallet,
                            iconColor: AppColors.success,
                            subtitle: 'This month',
                          ),
                          StatCard(
                            title: 'Arrears',
                            value: Formatters.compactCurrency(dataService.totalArrears),
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.error,
                            onTap: () => context.go(AppRoutes.invoices),
                          ),
                          StatCard(
                            title: 'Occupancy',
                            value: '${dataService.occupancyRate.toStringAsFixed(0)}%',
                            icon: Icons.home_work,
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
                              icon: Icons.add_card,
                              color: AppColors.success,
                              onTap: () => context.push(AppRoutes.addPayment),
                            ),
                            const SizedBox(width: 12),
                            QuickActionCard(
                              title: 'New Tenant',
                              icon: Icons.person_add,
                              color: AppColors.info,
                              onTap: () => context.push(AppRoutes.addTenant),
                            ),
                            const SizedBox(width: 12),
                            QuickActionCard(
                              title: 'Maintenance',
                              icon: Icons.build,
                              color: AppColors.warning,
                              onTap: () => context.push(AppRoutes.addTicket),
                            ),
                            const SizedBox(width: 12),
                            QuickActionCard(
                              title: 'Add Property',
                              icon: Icons.apartment,
                              color: Colors.purple,
                              onTap: () => context.push(AppRoutes.addProperty),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Activity
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
                    ],
                  ),
                ),
              ),
              
              // Recent payments list
              if (dataService.payments.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.payment, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No payments yet',
                            style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final payments = dataService.payments.toList()
                        ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
                      if (index >= 5 || index >= payments.length) return null;
                      
                      final payment = payments[index];
                      final tenant = dataService.getTenantById(payment.tenantId ?? '');
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == 4 ? 16 : 0),
                        child: PaymentCard(
                          payment: payment,
                          tenantName: tenant?.fullName ?? 'Unknown',
                          onTap: () {},
                        ),
                      );
                    },
                    childCount: 5,
                  ),
                ),
              
              // Open Tickets Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
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
                ),
              ),
              
              if (dataService.tickets.where((t) => t.status != TicketStatus.approved && t.status != TicketStatus.rejected).isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, size: 48, color: AppColors.success.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No open tickets',
                            style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final openTickets = dataService.tickets
                          .where((t) => t.status != TicketStatus.approved && t.status != TicketStatus.rejected)
                          .toList()
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      
                      if (index >= 3 || index >= openTickets.length) return null;
                      
                      final ticket = openTickets[index];
                      final unit = dataService.getUnitById(ticket.unitId);
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == 2 ? 100 : 0),
                        child: TicketCard(
                          ticket: ticket,
                          unitLabel: unit?.unitLabel ?? 'Unknown',
                          onTap: () => context.push(AppRoutes.maintenance),
                        ),
                      );
                    },
                    childCount: 3,
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}
