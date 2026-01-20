import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oxy/auth/supabase_auth_manager.dart';
import 'package:oxy/components/auth_components.dart';
import 'package:oxy/theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authManager = SupabaseAuthManager();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authManager.resetPassword(
        email: _emailController.text.trim(),
        context: context,
      );
      if (mounted) {
        setState(() => _emailSent = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_emailSent) {
      return _buildSuccessScreen(context, colorScheme, isDark);
    }
    
    return AuthPageLayout(
      subtitle: 'Reset your password',
      headerExtra: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.08) 
                          : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: _resetPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    
                    AuthPrimaryButton(
                      label: 'Send Reset Link',
                      onPressed: _resetPassword,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Back to login
              AuthLinkRow(
                text: 'Remember your password? ',
                linkText: 'Sign In',
                onTap: () => context.go('/login'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return AuthPageLayout(
      subtitle: "We've sent a reset link to\n${_emailController.text}",
      headerExtra: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            AuthPrimaryButton(
              label: 'Back to Sign In',
              onPressed: () => context.go('/login'),
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => setState(() => _emailSent = false),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: const Text(
                'Try a different email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
