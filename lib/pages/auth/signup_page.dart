import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oxy/auth/supabase_auth_manager.dart';
import 'package:oxy/components/auth_components.dart';
import 'package:oxy/theme.dart';

enum SignupType { propertyOwner, tenant, serviceProvider }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authManager = SupabaseAuthManager();

  SignupType _signupType = SignupType.propertyOwner;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the terms and privacy policy'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authManager.createAccountWithEmail(
        context,
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Update profile with name
        final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
        await _authManager.updateProfile(
          context: context,
          fullName: fullName,
        );

        if (_signupType == SignupType.tenant) {
          // Navigate to claim code page - it will handle code generation/display
          if (mounted) context.go('/claim-code');
        } else if (_signupType == SignupType.serviceProvider) {
          // Navigate to service provider onboarding
          if (mounted) context.go('/provider-onboarding');
        } else {
          // Redirect to create organization for property owners
          if (mounted) context.go('/create-org');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AuthPageLayout(
      subtitle: 'Create your account',
      headerExtra: AuthTabToggle(
        selectedIndex: 0,
        onChanged: (index) {
          if (index == 1) context.go('/login');
        },
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              // Account type selector
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AccountTypeChip(
                          icon: Icons.business_rounded,
                          label: 'Property Owner',
                          isSelected: _signupType == SignupType.propertyOwner,
                          onTap: () => setState(() => _signupType = SignupType.propertyOwner),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccountTypeChip(
                          icon: Icons.home_rounded,
                          label: 'Tenant',
                          isSelected: _signupType == SignupType.tenant,
                          onTap: () => setState(() => _signupType = SignupType.tenant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AccountTypeChip(
                    icon: Icons.storefront_rounded,
                    label: 'Service Provider',
                    isSelected: _signupType == SignupType.serviceProvider,
                    onTap: () => setState(() => _signupType = SignupType.serviceProvider),
                    subtitle: 'List your business on Oxy',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Create Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: _signUp,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    
                    // Terms checkbox
                    GestureDetector(
                      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _agreeToTerms ? colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _agreeToTerms ? colorScheme.primary : colorScheme.outline,
                                width: 1.5,
                              ),
                            ),
                            child: _agreeToTerms
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I certify that I am 18 years or older, and Agree to all ',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'user agreement',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'privacy policy',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Sign up button
                    AuthPrimaryButton(
                      label: 'Sign Up',
                      onPressed: _signUp,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Login link
              AuthLinkRow(
                text: 'Already have an account? ',
                linkText: 'Sign In',
                onTap: () => context.go('/login'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;

  const _AccountTypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: subtitle != null ? 12 : 14,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withValues(alpha: 0.12) 
              : isDark 
                  ? Colors.white.withValues(alpha: 0.06) 
                  : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected 
                            ? colorScheme.primary.withValues(alpha: 0.7) 
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
