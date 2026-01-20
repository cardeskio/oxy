import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/org_service.dart';
import 'package:oxy/models/org.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final orgService = context.watch<OrgService>();
    final currentUser = authService.currentUser;
    final currentMember = orgService.currentMember;
    
    return Consumer<DataService>(
      builder: (context, dataService, _) {
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('More', style: TextStyle(color: Colors.white)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User profile section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                      child: Text(
                        currentUser?.initials ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.fullName ?? 'User',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orgService.currentOrg?.name ?? 'No Organization',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentMember?.role.label ?? 'Member',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Menu sections
              _MenuSection(
                title: 'MANAGEMENT',
                items: [
                  _MenuItem(
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.success,
                    title: 'Payments',
                    subtitle: '${dataService.payments.length} transactions',
                    onTap: () => context.push(AppRoutes.payments),
                  ),
                  _MenuItem(
                    icon: Icons.build_outlined,
                    iconColor: AppColors.warning,
                    title: 'Maintenance',
                    subtitle: '${dataService.openTicketsCount} open tickets',
                    badge: dataService.openTicketsCount > 0 ? '${dataService.openTicketsCount}' : null,
                    onTap: () => context.push(AppRoutes.maintenance),
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.info,
                    title: 'Leases',
                    subtitle: '${dataService.leases.where((l) => l.isActive).length} active leases',
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _MenuSection(
                title: 'QUICK ACTIONS',
                items: [
                  _MenuItem(
                    icon: Icons.add_home_outlined,
                    iconColor: Colors.purple,
                    title: 'Add Property',
                    onTap: () => context.push(AppRoutes.addProperty),
                  ),
                  _MenuItem(
                    icon: Icons.person_add_outlined,
                    iconColor: AppColors.info,
                    title: 'Add Tenant',
                    onTap: () => context.push(AppRoutes.addTenant),
                  ),
                  _MenuItem(
                    icon: Icons.link_outlined,
                    iconColor: AppColors.primaryTeal,
                    title: 'Link Tenant Account',
                    subtitle: 'Connect tenant\'s app to their profile',
                    onTap: () => context.push(AppRoutes.linkTenant),
                  ),
                  _MenuItem(
                    icon: Icons.add_card_outlined,
                    iconColor: AppColors.success,
                    title: 'Record Payment',
                    onTap: () => context.push(AppRoutes.addPayment),
                  ),
                  _MenuItem(
                    icon: Icons.add_task_outlined,
                    iconColor: AppColors.warning,
                    title: 'Create Ticket',
                    onTap: () => context.push(AppRoutes.addTicket),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _MenuSection(
                title: 'REPORTS',
                items: [
                  _MenuItem(
                    icon: Icons.analytics_outlined,
                    iconColor: AppColors.primaryTeal,
                    title: 'Collection Report',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.warning_amber_outlined,
                    iconColor: AppColors.error,
                    title: 'Arrears Report',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.home_work_outlined,
                    iconColor: AppColors.info,
                    title: 'Occupancy Report',
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _MenuSection(
                title: 'SETTINGS',
                items: [
                  _MenuItem(
                    icon: Icons.business_outlined,
                    iconColor: AppColors.lightOnSurfaceVariant,
                    title: 'Organization',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.people_outline,
                    iconColor: AppColors.lightOnSurfaceVariant,
                    title: 'Team Members',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.lightOnSurfaceVariant,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    iconColor: AppColors.lightOnSurfaceVariant,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Sign out section
              _MenuSection(
                title: 'ACCOUNT',
                items: [
                  _MenuItem(
                    icon: Icons.logout,
                    iconColor: AppColors.error,
                    title: 'Sign Out',
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true && context.mounted) {
                        await authService.signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // App info
              Center(
                child: Column(
                  children: [
                    Text(
                      'PropManager KE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.lightOutline,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
      onTap: onTap,
    );
  }
}
