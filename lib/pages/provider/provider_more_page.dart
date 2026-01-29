import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oxy/auth/supabase_auth_manager.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/pages/provider/provider_dashboard_page.dart' show showEditProfileSheet, showBusinessHoursSheet, showPhotosSheet, showLocationSheet, showNotificationSettingsSheet, showHelpSupportSheet, showPrivacyPolicySheet;

/// More/Settings page for service providers
class ProviderMorePage extends StatelessWidget {
  const ProviderMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: Consumer<LivingService>(
        builder: (context, livingService, _) {
          final provider = livingService.myProvider;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile section
              if (provider != null) ...[
                _ProfileCard(provider: provider),
                const SizedBox(height: 24),
              ],

              // Business Settings
              _SectionHeader(title: 'Business Settings'),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedUser,
                title: 'Edit Profile',
                subtitle: 'Update business information',
                onTap: provider != null 
                    ? () => showEditProfileSheet(context, provider, livingService)
                    : null,
              ),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedClock03,
                title: 'Business Hours',
                subtitle: 'Set your operating hours',
                onTap: provider != null 
                    ? () => showBusinessHoursSheet(context, provider, livingService)
                    : null,
              ),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedImage01,
                title: 'Photos & Media',
                subtitle: 'Manage business photos',
                onTap: provider != null 
                    ? () => showPhotosSheet(context, provider, livingService)
                    : null,
              ),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedLocation01,
                title: 'Location',
                subtitle: 'Update your service area',
                onTap: provider != null 
                    ? () => showLocationSheet(context, provider, livingService)
                    : null,
              ),
              const SizedBox(height: 24),

              // Account
              _SectionHeader(title: 'Account'),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedNotification02,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () => showNotificationSettingsSheet(context),
              ),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedHelpCircle,
                title: 'Help & Support',
                subtitle: 'Get help with your account',
                onTap: () => showHelpSupportSheet(context),
              ),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedSecurityCheck,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () => showPrivacyPolicySheet(context),
              ),
              const SizedBox(height: 24),

              // Danger zone
              _SectionHeader(title: 'Account Actions'),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedHome03,
                title: 'Switch to Tenant View',
                subtitle: 'Browse as a regular user',
                onTap: () => context.go('/tenant/explore'),
              ),
              _SettingsTile(
                icon: HugeIcons.strokeRoundedLogout01,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                isDestructive: true,
                onTap: () => _confirmSignOut(context),
              ),
              const SizedBox(height: 32),

              // App version
              Center(
                child: Text(
                  'Oxy Provider v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseAuthManager().signOut();
              await AuthService().signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

}

class _ProfileCard extends StatelessWidget {
  final dynamic provider;

  const _ProfileCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: provider.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      provider.logoUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      provider.initials,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.businessName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      provider.category.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.category.label,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive ? AppColors.error : colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: ListTile(
        leading: HugeIcon(
          icon: icon,
          color: isDestructive ? AppColors.error : colorScheme.primary,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
