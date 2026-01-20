import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:oxy/models/user.dart' as app;
import 'package:oxy/models/org.dart';
import 'package:oxy/auth/supabase_auth_manager.dart';
import 'package:oxy/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User type enumeration
enum UserType { admin, tenant, unknown }

/// Tenant claim code model
class TenantClaimCode {
  final String id;
  final String code;
  final String userId;
  final String? orgId;
  final String? tenantId;
  final DateTime? claimedAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  TenantClaimCode({
    required this.id,
    required this.code,
    required this.userId,
    this.orgId,
    this.tenantId,
    this.claimedAt,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isClaimed => claimedAt != null;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isClaimed && !isExpired;

  factory TenantClaimCode.fromJson(Map<String, dynamic> json) => TenantClaimCode(
    id: json['id'] as String,
    code: json['code'] as String,
    userId: json['user_id'] as String,
    orgId: json['org_id'] as String?,
    tenantId: json['tenant_id'] as String?,
    claimedAt: json['claimed_at'] != null ? DateTime.parse(json['claimed_at'] as String) : null,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'user_id': userId,
    'org_id': orgId,
    'tenant_id': tenantId,
    'claimed_at': claimedAt?.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}

/// Tenant user link model
class TenantUserLink {
  final String id;
  final String userId;
  final String tenantId;
  final String orgId;
  final DateTime createdAt;

  TenantUserLink({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.orgId,
    required this.createdAt,
  });

  factory TenantUserLink.fromJson(Map<String, dynamic> json) => TenantUserLink(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    tenantId: json['tenant_id'] as String,
    orgId: json['org_id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// Auth service for managing authentication state and tenant linking
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseAuthManager _authManager = SupabaseAuthManager();
  
  app.User? _currentUser;
  UserType _userType = UserType.unknown;
  TenantClaimCode? _claimCode;
  List<TenantUserLink> _tenantLinks = [];
  List<OrgMember> _orgMemberships = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  app.User? get currentUser => _currentUser;
  UserType get userType => _userType;
  TenantClaimCode? get claimCode => _claimCode;
  List<TenantUserLink> get tenantLinks => _tenantLinks;
  List<OrgMember> get orgMemberships => _orgMemberships;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authManager.isAuthenticated;
  String? get currentUserId => _authManager.currentUserId;

  /// Initialize auth service and determine user type
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final userId = currentUserId;
      if (userId == null) {
        _userType = UserType.unknown;
        _isInitialized = true;
        return;
      }

      // Load user profile
      _currentUser = _authManager.currentUser;

      // Check org memberships (admin roles)
      final memberships = await SupabaseConfig.client
          .from('org_members')
          .select()
          .eq('user_id', userId);
      
      _orgMemberships = memberships.map((m) => OrgMember.fromJson(m)).toList();

      // Check tenant links
      final links = await SupabaseConfig.client
          .from('tenant_user_links')
          .select()
          .eq('user_id', userId);
      
      _tenantLinks = links.map((l) => TenantUserLink.fromJson(l)).toList();

      // Load claim code if exists
      final claimCodes = await SupabaseConfig.client
          .from('tenant_claim_codes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      
      if (claimCodes.isNotEmpty) {
        _claimCode = TenantClaimCode.fromJson(claimCodes.first);
      }

      // Determine user type
      if (_orgMemberships.isNotEmpty) {
        _userType = UserType.admin;
      } else if (_tenantLinks.isNotEmpty) {
        _userType = UserType.tenant;
      } else {
        _userType = UserType.unknown;
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate a unique claim code for a new tenant user
  Future<TenantClaimCode?> generateClaimCode() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // Check if user already has an active claim code
      if (_claimCode != null && _claimCode!.isValid) {
        return _claimCode;
      }

      // Generate unique 6-character code
      final code = _generateUniqueCode();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30)); // Code valid for 30 days

      final data = {
        'code': code,
        'user_id': userId,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      };

      final result = await SupabaseConfig.client
          .from('tenant_claim_codes')
          .insert(data)
          .select()
          .single();

      _claimCode = TenantClaimCode.fromJson(result);
      notifyListeners();
      return _claimCode;
    } catch (e) {
      debugPrint('Error generating claim code: $e');
      return null;
    }
  }

  /// Generate unique 6-character alphanumeric code
  String _generateUniqueCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding similar chars (0, O, 1, I)
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Look up a claim code (for property owners)
  Future<Map<String, dynamic>?> lookupClaimCode(String code) async {
    try {
      final result = await SupabaseConfig.client
          .from('tenant_claim_codes')
          .select('*, profiles!tenant_claim_codes_user_id_fkey(*)')
          .eq('code', code.toUpperCase())
          .maybeSingle();
      
      return result;
    } catch (e) {
      debugPrint('Error looking up claim code: $e');
      return null;
    }
  }

  /// Claim a tenant profile (link tenant record to user via claim code)
  Future<bool> claimTenantProfile({
    required String code,
    required String tenantId,
    required String orgId,
  }) async {
    try {
      // Look up the claim code
      final claimData = await lookupClaimCode(code);
      if (claimData == null) {
        debugPrint('Claim code not found');
        return false;
      }

      final claimCode = TenantClaimCode.fromJson(claimData);
      
      if (!claimCode.isValid) {
        debugPrint('Claim code is invalid or expired');
        return false;
      }

      // Update claim code with org and tenant info
      await SupabaseConfig.client
          .from('tenant_claim_codes')
          .update({
            'org_id': orgId,
            'tenant_id': tenantId,
            'claimed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', claimCode.id);

      // Create tenant user link
      await SupabaseConfig.client
          .from('tenant_user_links')
          .insert({
            'user_id': claimCode.userId,
            'tenant_id': tenantId,
            'org_id': orgId,
            'created_at': DateTime.now().toIso8601String(),
          });

      // Update tenant record with user_id
      await SupabaseConfig.client
          .from('tenants')
          .update({'user_id': claimCode.userId})
          .eq('id', tenantId);

      return true;
    } catch (e) {
      debugPrint('Error claiming tenant profile: $e');
      return false;
    }
  }

  /// Sign out and clear state
  Future<void> signOut() async {
    await _authManager.signOut();
    _currentUser = null;
    _userType = UserType.unknown;
    _claimCode = null;
    _tenantLinks = [];
    _orgMemberships = [];
    _isInitialized = false;
    notifyListeners();
  }

  /// Refresh user state
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  /// Check if user has admin access to any org
  bool get hasAdminAccess => _orgMemberships.isNotEmpty;

  /// Check if user has tenant access
  bool get hasTenantAccess => _tenantLinks.isNotEmpty;

  /// Get the first org the user has admin access to
  String? get primaryOrgId {
    if (_orgMemberships.isNotEmpty) {
      return _orgMemberships.first.orgId;
    }
    if (_tenantLinks.isNotEmpty) {
      return _tenantLinks.first.orgId;
    }
    return null;
  }

  /// Get the user's role in an org
  OrgRole? getRoleInOrg(String orgId) {
    final membership = _orgMemberships.cast<OrgMember?>().firstWhere(
      (m) => m?.orgId == orgId,
      orElse: () => null,
    );
    return membership?.role;
  }

  /// Check if user can manage a specific org
  bool canManageOrg(String orgId) {
    final role = getRoleInOrg(orgId);
    return role == OrgRole.owner || role == OrgRole.manager;
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _authManager.authStateChanges;
}
