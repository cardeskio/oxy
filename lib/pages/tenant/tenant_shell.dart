import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/icons.dart';
import 'package:oxy/services/auth_service.dart';

class TenantShell extends StatefulWidget {
  final Widget child;
  const TenantShell({super.key, required this.child});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _getCurrentIndex(BuildContext context, bool hasUnit) {
    final location = GoRouterState.of(context).uri.path;
    
    if (hasUnit) {
      // Full nav: Home, Explore, Living, Invoices, More
      if (location.startsWith('/tenant/explore') || location.startsWith('/tenant/enquiries')) return 1;
      if (location.startsWith('/tenant/living')) return 2;
      if (location.startsWith('/tenant/invoices') || location.startsWith('/tenant/payments')) return 3;
      if (location.startsWith('/tenant/more')) return 4;
      return 0;
    } else {
      // Simplified nav: Explore, Living, Enquiries, More
      if (location.startsWith('/tenant/living')) return 1;
      if (location.startsWith('/tenant/enquiries')) return 2;
      if (location.startsWith('/tenant/more')) return 3;
      return 0; // Explore is home for users without units
    }
  }

  void _onItemTapped(int index, bool hasUnit) {
    if (hasUnit) {
      switch (index) {
        case 0:
          context.go('/tenant');
          break;
        case 1:
          context.go('/tenant/explore');
          break;
        case 2:
          context.go('/tenant/living');
          break;
        case 3:
          context.go('/tenant/invoices');
          break;
        case 4:
          context.go('/tenant/more');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/tenant/explore');
          break;
        case 1:
          context.go('/tenant/living');
          break;
        case 2:
          context.go('/tenant/enquiries');
          break;
        case 3:
          context.go('/tenant/more');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final hasUnit = authService.tenantLinks.isNotEmpty;
        final currentIndex = _getCurrentIndex(context, hasUnit);
        
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
                  children: hasUnit 
                    ? _buildFullNav(currentIndex, hasUnit)
                    : _buildExploreNav(currentIndex, hasUnit),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFullNav(int currentIndex, bool hasUnit) {
    return [
      _NavItem(
        icon: AppIcons.dashboard,
        label: 'Home',
        isSelected: currentIndex == 0,
        onTap: () => _onItemTapped(0, hasUnit),
      ),
      _NavItem(
        icon: HugeIcons.strokeRoundedSearch01,
        label: 'Explore',
        isSelected: currentIndex == 1,
        onTap: () => _onItemTapped(1, hasUnit),
      ),
      _NavItem(
        icon: HugeIcons.strokeRoundedStore01,
        label: 'Living',
        isSelected: currentIndex == 2,
        onTap: () => _onItemTapped(2, hasUnit),
      ),
      _NavItem(
        icon: AppIcons.invoices,
        label: 'Invoices',
        isSelected: currentIndex == 3,
        onTap: () => _onItemTapped(3, hasUnit),
      ),
      _NavItem(
        icon: AppIcons.more,
        label: 'More',
        isSelected: currentIndex == 4,
        onTap: () => _onItemTapped(4, hasUnit),
      ),
    ];
  }

  List<Widget> _buildExploreNav(int currentIndex, bool hasUnit) {
    return [
      _NavItem(
        icon: HugeIcons.strokeRoundedSearch01,
        label: 'Explore',
        isSelected: currentIndex == 0,
        onTap: () => _onItemTapped(0, hasUnit),
      ),
      _NavItem(
        icon: HugeIcons.strokeRoundedStore01,
        label: 'Living',
        isSelected: currentIndex == 1,
        onTap: () => _onItemTapped(1, hasUnit),
      ),
      _NavItem(
        icon: HugeIcons.strokeRoundedMail01,
        label: 'Enquiries',
        isSelected: currentIndex == 2,
        onTap: () => _onItemTapped(2, hasUnit),
      ),
      _NavItem(
        icon: AppIcons.more,
        label: 'More',
        isSelected: currentIndex == 3,
        onTap: () => _onItemTapped(3, hasUnit),
      ),
    ];
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
