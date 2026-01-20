import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/models/invoice.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/components/list_cards.dart';

class TenantDetailPage extends StatelessWidget {
  final String tenantId;
  const TenantDetailPage({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final tenant = dataService.getTenantById(tenantId);
        if (tenant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tenant Not Found')),
            body: const Center(child: Text('Tenant not found')),
          );
        }

        final lease = dataService.getActiveLeaseForTenant(tenantId);
        final unit = lease != null ? dataService.getUnitById(lease.unitId) : null;
        final property = lease != null ? dataService.getPropertyById(lease.propertyId) : null;
        final invoices = dataService.getInvoicesForTenant(tenantId)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final payments = dataService.getPaymentsForTenant(tenantId)
          ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
        final totalBalance = invoices
            .where((i) => i.status == InvoiceStatus.open)
            .fold<double>(0, (sum, i) => sum + i.balanceAmount);

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primaryTeal,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primaryDark, AppColors.primaryTeal],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              tenant.initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tenant.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.phone(tenant.phone),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.add_card,
                              label: 'Record Payment',
                              color: AppColors.success,
                              onTap: () => context.push('${AppRoutes.addPayment}?tenantId=$tenantId'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.build_outlined,
                              label: 'Create Ticket',
                              color: AppColors.warning,
                              onTap: unit != null 
                                  ? () => context.push('${AppRoutes.addTicket}?unitId=${unit.id}')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.phone_outlined,
                              label: 'Call',
                              color: AppColors.info,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Balance Card
                      if (totalBalance > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Outstanding Balance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    Text(
                                      Formatters.currency(totalBalance),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => context.push('${AppRoutes.addPayment}?tenantId=$tenantId'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Contact Info
                      _SectionCard(
                        title: 'Contact Information',
                        children: [
                          _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: Formatters.phone(tenant.phone)),
                          if (tenant.email != null) _InfoRow(icon: Icons.email_outlined, label: 'Email', value: tenant.email!),
                          if (tenant.idNumber != null) _InfoRow(icon: Icons.badge_outlined, label: 'ID Number', value: tenant.idNumber!),
                          if (tenant.nextOfKinName != null) ...[
                            const Divider(height: 24),
                            Text('Next of Kin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant)),
                            const SizedBox(height: 8),
                            _InfoRow(icon: Icons.person_outline, label: 'Name', value: tenant.nextOfKinName!),
                            if (tenant.nextOfKinPhone != null) _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: Formatters.phone(tenant.nextOfKinPhone!)),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Active Lease
                      if (lease != null && unit != null && property != null)
                        _SectionCard(
                          title: 'Active Lease',
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unit.unitLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${unit.unitType ?? "Unit"} • ${Formatters.currency(lease.rentAmount)}/mo',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.lightOnSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _LeaseInfo(label: 'Start Date', value: Formatters.shortDate(lease.startDate))),
                                Expanded(child: _LeaseInfo(label: 'Due Day', value: '${lease.dueDay}th')),
                                Expanded(child: _LeaseInfo(label: 'Deposit', value: Formatters.compactCurrency(lease.depositAmount))),
                              ],
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Invoices
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Invoices',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              if (invoices.isEmpty)
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
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No invoices yet'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 3 || index >= invoices.length) return null;
                      final invoice = invoices[index];
                      final invUnit = dataService.getUnitById(invoice.unitId);
                      final invProperty = dataService.getPropertyById(invoice.propertyId);
                      
                      return InvoiceCard(
                        invoice: invoice,
                        tenantName: tenant.fullName,
                        unitLabel: '${invProperty?.name ?? ""} - ${invUnit?.unitLabel ?? ""}',
                        onTap: () => context.push('/invoices/${invoice.id}'),
                      );
                    },
                    childCount: 3,
                  ),
                ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Payments',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (payments.isEmpty)
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
                          const Text('No payments yet'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 3 || index >= payments.length) return null;
                      final payment = payments[index];
                      
                      return PaymentCard(
                        payment: payment,
                        tenantName: tenant.fullName,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: onTap != null ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onTap != null ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.lightOnSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaseInfo extends StatelessWidget {
  final String label;
  final String value;

  const _LeaseInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.lightOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
