import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/services/auth_service.dart';

class TenantMorePage extends StatelessWidget {
  const TenantMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            title: const Text('More', style: TextStyle(color: Colors.white)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // My Unit Section
              _MenuSection(
                title: 'MY UNIT',
                items: [
                  _MenuItem(
                    icon: Icons.home_outlined,
                    iconColor: AppColors.primaryTeal,
                    title: 'View Unit Details',
                    onTap: () {
                      // Navigate to unit details if available
                    },
                  ),
                  _MenuItem(
                    icon: Icons.build_outlined,
                    iconColor: AppColors.warning,
                    title: 'Maintenance Requests',
                    onTap: () => context.push('/tenant/maintenance'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Account Section
              _MenuSection(
                title: 'ACCOUNT',
                items: [
                  _MenuItem(
                    icon: Icons.person_outline,
                    iconColor: AppColors.info,
                    title: 'Profile',
                    onTap: () {
                      // Navigate to profile page
                    },
                  ),
                  _MenuItem(
                    icon: Icons.logout,
                    iconColor: AppColors.error,
                    title: 'Sign Out',
                    onTap: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        context.go('/login');
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
                      'PropManager KE - Tenant Portal',
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
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
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
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
