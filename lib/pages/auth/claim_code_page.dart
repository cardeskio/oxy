import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:oxy/components/auth_components.dart';
import 'package:oxy/services/auth_service.dart';
import 'package:oxy/theme.dart';

/// Page shown to tenants after signup - displays their unique claim code
class ClaimCodePage extends StatefulWidget {
  const ClaimCodePage({super.key});

  @override
  State<ClaimCodePage> createState() => _ClaimCodePageState();
}

class _ClaimCodePageState extends State<ClaimCodePage> {
  final _authService = AuthService();
  bool _isLoading = true;
  TenantClaimCode? _claimCode;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateCode();
  }

  Future<void> _loadOrGenerateCode() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.refresh();
      
      if (_authService.claimCode == null) {
        final code = await _authService.generateClaimCode();
        _claimCode = code;
      } else {
        _claimCode = _authService.claimCode;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyCode() {
    if (_claimCode == null) return;
    
    Clipboard.setData(ClipboardData(text: _claimCode!.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AuthPageLayout(
      subtitle: 'Share your claim code with your\nproperty owner to link your profile',
      headerExtra: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, colorScheme, isDark),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme, bool isDark) {
    if (_claimCode == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to generate code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Try Again',
                onPressed: _loadOrGenerateCode,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Claim code display
            Text(
              'Your Claim Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.06) 
                    : colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _claimCode!.code,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      fontFamily: 'monospace',
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'Copy code',
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Expiry info
            Text(
              'Valid until ${_formatDate(_claimCode!.expiresAt)}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Steps
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
                    'What happens next?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    context: context,
                    number: '1',
                    title: 'Share Your Code',
                    description: 'Give this code to your property owner or manager',
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    context: context,
                    number: '2',
                    title: 'Owner Links Your Profile',
                    description: 'They will enter your code to link your rental unit',
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    context: context,
                    number: '3',
                    title: 'Access Your Portal',
                    description: 'Once linked, you can view invoices, payments & more',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (_claimCode!.isClaimed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your profile has been linked! You can now access your tenant portal.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Go to Tenant Portal',
                onPressed: () => context.go('/tenant'),
              ),
            ] else ...[
              AuthSecondaryButton(
                label: 'Sign Out',
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) context.go('/login');
                },
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadOrGenerateCode,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: const Text('Refresh Status'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required BuildContext context,
    required String number,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
