import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oxy/theme.dart';

class TenantShell extends StatefulWidget {
  final Widget child;
  const TenantShell({super.key, required this.child});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/tenant/invoices')) return 1;
    if (location.startsWith('/tenant/payments')) return 2;
    if (location.startsWith('/tenant/more')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/tenant');
        break;
      case 1:
        context.go('/tenant/invoices');
        break;
      case 2:
        context.go('/tenant/payments');
        break;
      case 3:
        context.go('/tenant/more');
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Dashboard',
                  isSelected: _getCurrentIndex(context) == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Invoices',
                  isSelected: _getCurrentIndex(context) == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _NavItem(
                  icon: Icons.payment_outlined,
                  activeIcon: Icons.payment,
                  label: 'Payments',
                  isSelected: _getCurrentIndex(context) == 2,
                  onTap: () => _onItemTapped(2),
                ),
                _NavItem(
                  icon: Icons.more_horiz_outlined,
                  activeIcon: Icons.more_horiz,
                  label: 'More',
                  isSelected: _getCurrentIndex(context) == 3,
                  onTap: () => _onItemTapped(3),
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
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primaryTeal : AppColors.lightOnSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
