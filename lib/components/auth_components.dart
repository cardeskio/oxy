import 'package:flutter/material.dart';
import 'package:oxy/theme.dart';

/// Auth page layout with gradient header at top and adaptive content below
class AuthPageLayout extends StatelessWidget {
  final String subtitle;
  final Widget child;
  final Widget? headerExtra;

  const AuthPageLayout({
    super.key,
    required this.subtitle,
    required this.child,
    this.headerExtra,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0a1628),
                  Color(0xFF0d173d),
                  Color(0xFF142550),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  children: [
                    const Text(
                      'Oxy',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                    if (headerExtra != null) ...[
                      const SizedBox(height: 20),
                      headerExtra!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Content area - theme adaptive
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab toggle for switching between Sign Up and Login
class AuthTabToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AuthTabToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildTab('Sign Up', 0),
          _buildTab('Login', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme-adaptive text field for auth pages
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onFieldSubmitted;
  final TextCapitalization textCapitalization;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onFieldSubmitted: onFieldSubmitted != null ? (_) => onFieldSubmitted!() : null,
      validator: validator,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
      ),
      cursorColor: colorScheme.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark 
            ? Colors.white.withValues(alpha: 0.06) 
            : AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : AppColors.lightOutline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : AppColors.lightOutline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        errorStyle: TextStyle(
          color: colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Primary button for auth pages with accent color
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

/// Secondary outlined button for auth pages
class AuthSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

/// Link text for auth pages
class AuthLinkRow extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const AuthLinkRow({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
