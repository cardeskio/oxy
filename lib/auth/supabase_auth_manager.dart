import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:oxy/models/user.dart' as app;
import 'package:oxy/auth/auth_manager.dart';
import 'package:oxy/supabase/supabase_config.dart';

/// Supabase authentication manager implementation
class SupabaseAuthManager extends AuthManager 
    with EmailSignInManager, PhoneSignInManager {
  
  static final SupabaseAuthManager _instance = SupabaseAuthManager._internal();
  factory SupabaseAuthManager() => _instance;
  SupabaseAuthManager._internal();

  GoTrueClient get _auth => SupabaseConfig.auth;
  SupabaseClient get _client => SupabaseConfig.client;

  String? _verificationId;
  
  /// Get current user
  app.User? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return app.User(
      id: user.id,
      fullName: user.userMetadata?['full_name'] as String? ?? '',
      phone: user.phone,
      email: user.email,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.parse(user.createdAt),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.id;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
  
  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  @override
  Future<app.User?> signInWithEmail(
    BuildContext context, 
    String email, 
    String password,
  ) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return await _getOrCreateProfile(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      _showError(context, e.message);
      return null;
    } catch (e) {
      debugPrint('Sign in error: $e');
      _showError(context, 'Failed to sign in');
      return null;
    }
  }

  @override
  Future<app.User?> createAccountWithEmail(
    BuildContext context, 
    String email, 
    String password,
  ) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return await _getOrCreateProfile(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      _showError(context, e.message);
      return null;
    } catch (e) {
      debugPrint('Sign up error: $e');
      _showError(context, 'Failed to create account');
      return null;
    }
  }

  @override
  Future<void> beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  }) async {
    try {
      await _auth.signInWithOtp(
        phone: phoneNumber,
      );
      _verificationId = phoneNumber;
      onCodeSent(context);
    } on AuthException catch (e) {
      debugPrint('Phone auth error: ${e.message}');
      _showError(context, e.message);
    } catch (e) {
      debugPrint('Phone auth error: $e');
      _showError(context, 'Failed to send verification code');
    }
  }

  @override
  Future verifySmsCode({
    required BuildContext context,
    required String smsCode,
  }) async {
    try {
      if (_verificationId == null) {
        _showError(context, 'Please request a new verification code');
        return null;
      }
      
      final response = await _auth.verifyOTP(
        phone: _verificationId!,
        token: smsCode,
        type: OtpType.sms,
      );
      
      if (response.user != null) {
        return await _getOrCreateProfile(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      debugPrint('OTP verification error: ${e.message}');
      _showError(context, e.message);
      return null;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      _showError(context, 'Failed to verify code');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    // User deletion requires admin SDK in edge function
    _showError(context, 'Please contact support to delete your account');
  }

  @override
  Future<void> updateEmail({
    required String email, 
    required BuildContext context,
  }) async {
    try {
      await _auth.updateUser(UserAttributes(email: email));
      _showSuccess(context, 'Email updated successfully');
    } on AuthException catch (e) {
      _showError(context, e.message);
    } catch (e) {
      _showError(context, 'Failed to update email');
    }
  }

  @override
  Future<void> resetPassword({
    required String email, 
    required BuildContext context,
  }) async {
    try {
      await _auth.resetPasswordForEmail(email);
      _showSuccess(context, 'Password reset email sent');
    } on AuthException catch (e) {
      _showError(context, e.message);
    } catch (e) {
      _showError(context, 'Failed to send reset email');
    }
  }

  /// Update user profile
  Future<app.User?> updateProfile({
    required BuildContext context,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      
      await _client.from('profiles').update(updates).eq('id', userId);
      
      // Also update user metadata
      await _auth.updateUser(UserAttributes(
        data: {
          if (fullName != null) 'full_name': fullName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      ));
      
      return await _getProfile(userId);
    } catch (e) {
      debugPrint('Update profile error: $e');
      _showError(context, 'Failed to update profile');
      return null;
    }
  }

  /// Get or create user profile
  Future<app.User?> _getOrCreateProfile(User supabaseUser) async {
    try {
      // Try to get existing profile
      final existing = await _client
          .from('profiles')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();
      
      if (existing != null) {
        return app.User.fromJson(existing);
      }
      
      // Create new profile
      final profile = {
        'id': supabaseUser.id,
        'full_name': supabaseUser.userMetadata?['full_name'] ?? 
                     supabaseUser.email?.split('@').first ?? 
                     'User',
        'phone': supabaseUser.phone,
        'email': supabaseUser.email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _client.from('profiles').insert(profile);
      return app.User.fromJson(profile);
    } catch (e) {
      debugPrint('Get/create profile error: $e');
      return null;
    }
  }

  Future<app.User?> _getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return data != null ? app.User.fromJson(data) : null;
    } catch (e) {
      debugPrint('Get profile error: $e');
      return null;
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }
}
