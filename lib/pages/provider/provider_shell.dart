import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oxy/theme.dart';

/// Shell widget for service provider pages with bottom navigation
class ProviderShell extends StatelessWidget {
  final Widget child;

  const ProviderShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/provider' || location == '/provider/dashboard') return 0;
    if (location == '/provider/listings') return 1;
    if (location == '/provider/orders') return 2;
    if (location == '/provider/reviews') return 3;
    if (location == '/provider/more') return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/provider');
        break;
      case 1:
        context.go('/provider/listings');
        break;
      case 2:
        context.go('/provider/orders');
        break;
      case 3:
        context.go('/provider/reviews');
        break;
      case 4:
        context.go('/provider/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome03,
              color: AppColors.lightOnSurfaceVariant,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome03,
              color: AppColors.primaryNavy,
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingBag02,
              color: AppColors.lightOnSurfaceVariant,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingBag02,
              color: AppColors.primaryNavy,
              size: 24,
            ),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingCart01,
              color: AppColors.lightOnSurfaceVariant,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingCart01,
              color: AppColors.primaryNavy,
              size: 24,
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedStar,
              color: AppColors.lightOnSurfaceVariant,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedStar,
              color: AppColors.primaryNavy,
              size: 24,
            ),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMenu02,
              color: AppColors.lightOnSurfaceVariant,
              size: 24,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedMenu02,
              color: AppColors.primaryNavy,
              size: 24,
            ),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
