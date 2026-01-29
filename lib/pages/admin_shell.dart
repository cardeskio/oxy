import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oxy/nav.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/icons.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/properties')) return 1;
    if (location.startsWith('/tenants')) return 2;
    if (location.startsWith('/invoices')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.properties);
        break;
      case 2:
        context.go(AppRoutes.tenants);
        break;
      case 3:
        context.go(AppRoutes.invoices);
        break;
      case 4:
        context.go(AppRoutes.more);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: AppIcons.dashboard,
                  label: 'Dashboard',
                  isSelected: _getCurrentIndex(context) == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _NavItem(
                  icon: AppIcons.properties,
                  label: 'Properties',
                  isSelected: _getCurrentIndex(context) == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _NavItem(
                  icon: AppIcons.tenants,
                  label: 'Tenants',
                  isSelected: _getCurrentIndex(context) == 2,
                  onTap: () => _onItemTapped(2),
                ),
                _NavItem(
                  icon: AppIcons.invoices,
                  label: 'Invoices',
                  isSelected: _getCurrentIndex(context) == 3,
                  onTap: () => _onItemTapped(3),
                ),
                _NavItem(
                  icon: AppIcons.more,
                  label: 'More',
                  isSelected: _getCurrentIndex(context) == 4,
                  onTap: () => _onItemTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              color: isSelected ? AppColors.primaryTeal : AppColors.lightOnSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryTeal : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
