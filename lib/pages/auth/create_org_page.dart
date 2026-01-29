import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oxy/services/org_service.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/auth/supabase_auth_manager.dart';
import 'package:oxy/components/auth_components.dart';
import 'package:oxy/theme.dart';

/// Page for property owners to create their organization after signup
class CreateOrgPage extends StatefulWidget {
  const CreateOrgPage({super.key});

  @override
  State<CreateOrgPage> createState() => _CreateOrgPageState();
}

class _CreateOrgPageState extends State<CreateOrgPage> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _orgService = OrgService();
  final _authService = AuthService();
  final _dataService = DataService();
  final _authManager = SupabaseAuthManager();
  bool _isLoading = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  Future<void> _createOrg() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _authManager.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again'),
          backgroundColor: AppColors.error,
        ),
      );
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final org = await _orgService.createOrg(
        _orgNameController.text.trim(),
        userId,
      );

      if (org != null && mounted) {
        await _authService.refresh();
        // Initialize data service for the new org
        await _dataService.initializeForOrg(org.id);
        context.go('/');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AuthPageLayout(
      subtitle: 'Create your organization',
      headerExtra: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // Organization name
                AuthTextField(
                  controller: _orgNameController,
                  label: 'Organization Name',
                  prefixIcon: Icons.business_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: _createOrg,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your organization name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What is an Organization?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your organization is your property management business. All your properties, tenants, and team members will be organized under this.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Features list
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.04) 
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You\'ll be able to:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context: context,
                        icon: Icons.apartment,
                        text: 'Add properties and units',
                      ),
                      _buildFeatureItem(
                        context: context,
                        icon: Icons.people,
                        text: 'Manage tenants and leases',
                      ),
                      _buildFeatureItem(
                        context: context,
                        icon: Icons.receipt_long,
                        text: 'Generate invoices and track payments',
                      ),
                      _buildFeatureItem(
                        context: context,
                        icon: Icons.build,
                        text: 'Handle maintenance requests',
                      ),
                      _buildFeatureItem(
                        context: context,
                        icon: Icons.group_add,
                        text: 'Invite team members',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Create button
                AuthPrimaryButton(
                  label: 'Create Organization',
                  onPressed: _createOrg,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Sign out option
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) context.go('/login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
