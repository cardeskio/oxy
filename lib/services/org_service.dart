import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:oxy/models/org.dart';
import 'package:oxy/models/user.dart';
import 'package:oxy/models/vendor.dart';
import 'package:oxy/models/charge_type.dart';
import 'package:oxy/supabase/supabase_config.dart';

const _uuid = Uuid();

/// Service for organization management
class OrgService extends ChangeNotifier {
  static final OrgService _instance = OrgService._internal();
  factory OrgService() => _instance;
  OrgService._internal();

  Org? _currentOrg;
  OrgMember? _currentMember;
  List<Org> _userOrgs = [];
  List<OrgMember> _orgMembers = [];
  List<Vendor> _vendors = [];
  List<ChargeType> _chargeTypes = [];
  bool _isLoading = false;

  Org? get currentOrg => _currentOrg;
  OrgMember? get currentMember => _currentMember;
  List<Org> get userOrgs => _userOrgs;
  List<OrgMember> get orgMembers => _orgMembers;
  List<Vendor> get vendors => _vendors;
  List<ChargeType> get chargeTypes => _chargeTypes;
  bool get isLoading => _isLoading;
  String? get currentOrgId => _currentOrg?.id;

  /// Initialize org service for a user
  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get all orgs the user belongs to
      final memberships = await SupabaseService.select(
        'org_members',
        filters: {'user_id': userId},
      );

      if (memberships.isEmpty) {
        _userOrgs = [];
        _currentOrg = null;
        _currentMember = null;
      } else {
        // Get org details for each membership
        final orgIds = memberships.map((m) => m['org_id'] as String).toList();
        final orgsData = await SupabaseConfig.client
            .from('orgs')
            .select()
            .inFilter('id', orgIds);
        
        _userOrgs = orgsData.map((o) => Org.fromJson(o)).toList();
        
        // Set first org as current if not already set
        if (_currentOrg == null && _userOrgs.isNotEmpty) {
          await selectOrg(_userOrgs.first.id, userId);
        }
      }
    } catch (e) {
      debugPrint('Error initializing org service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select an organization as current
  Future<void> selectOrg(String orgId, String userId) async {
    try {
      final orgData = await SupabaseService.selectSingle(
        'orgs',
        filters: {'id': orgId},
      );
      
      if (orgData != null) {
        _currentOrg = Org.fromJson(orgData);
        
        // Get member info
        final memberData = await SupabaseService.selectSingle(
          'org_members',
          filters: {'org_id': orgId, 'user_id': userId},
        );
        
        if (memberData != null) {
          _currentMember = OrgMember.fromJson(memberData);
        }
        
        // Load org-specific data
        await _loadOrgData(orgId);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error selecting org: $e');
    }
  }

  /// Load organization-specific data (vendors, charge types, members)
  Future<void> _loadOrgData(String orgId) async {
    try {
      // Load vendors
      final vendorsData = await SupabaseService.select(
        'vendors',
        filters: {'org_id': orgId},
        orderBy: 'name',
      );
      _vendors = vendorsData.map((v) => Vendor.fromJson(v)).toList();

      // Load charge types
      final chargeTypesData = await SupabaseService.select(
        'charge_types',
        filters: {'org_id': orgId},
        orderBy: 'name',
      );
      _chargeTypes = chargeTypesData.map((c) => ChargeType.fromJson(c)).toList();

      // Load org members
      final membersData = await SupabaseService.select(
        'org_members',
        filters: {'org_id': orgId},
      );
      _orgMembers = membersData.map((m) => OrgMember.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Error loading org data: $e');
    }
  }

  /// Create a new organization
  Future<Org?> createOrg(String name, String userId, {String country = 'KE'}) async {
    try {
      final now = DateTime.now();
      final orgId = _generateUuid();
      
      // Create org
      final orgData = {
        'id': orgId,
        'name': name,
        'country': country,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      await SupabaseService.insert('orgs', orgData);
      
      // Add creator as owner
      final memberData = {
        'id': _generateUuid(),
        'org_id': orgId,
        'user_id': userId,
        'role': 'owner',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      await SupabaseService.insert('org_members', memberData);
      
      // Create default charge types
      await _createDefaultChargeTypes(orgId);
      
      final org = Org.fromJson(orgData);
      _userOrgs.add(org);
      await selectOrg(orgId, userId);
      
      notifyListeners();
      return org;
    } catch (e) {
      debugPrint('Error creating org: $e');
      return null;
    }
  }

  /// Create default charge types for a new org
  Future<void> _createDefaultChargeTypes(String orgId) async {
    final now = DateTime.now();
    final defaultTypes = [
      {'name': 'Rent', 'is_recurring': true},
      {'name': 'Water', 'is_recurring': true},
      {'name': 'Garbage', 'is_recurring': true},
      {'name': 'Service Charge', 'is_recurring': true},
      {'name': 'Parking', 'is_recurring': true},
      {'name': 'Electricity', 'is_recurring': false},
      {'name': 'Security', 'is_recurring': true},
      {'name': 'Penalty', 'is_recurring': false},
      {'name': 'Deposit', 'is_recurring': false},
    ];
    
    for (final type in defaultTypes) {
      await SupabaseService.insert('charge_types', {
        'id': _generateUuid(),
        'org_id': orgId,
        'name': type['name'],
        'is_recurring': type['is_recurring'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }

  /// Add a member to the organization
  Future<OrgMember?> addMember(String userId, OrgRole role) async {
    if (_currentOrg == null) return null;
    
    try {
      final now = DateTime.now();
      final data = {
        'id': _generateUuid(),
        'org_id': _currentOrg!.id,
        'user_id': userId,
        'role': role.value,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      await SupabaseService.insert('org_members', data);
      
      final member = OrgMember.fromJson(data);
      _orgMembers.add(member);
      notifyListeners();
      return member;
    } catch (e) {
      debugPrint('Error adding member: $e');
      return null;
    }
  }

  /// Update member role
  Future<void> updateMemberRole(String memberId, OrgRole newRole) async {
    try {
      await SupabaseService.update(
        'org_members',
        {'role': newRole.value, 'updated_at': DateTime.now().toIso8601String()},
        filters: {'id': memberId},
      );
      
      final index = _orgMembers.indexWhere((m) => m.id == memberId);
      if (index != -1) {
        _orgMembers[index] = _orgMembers[index].copyWith(role: newRole);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating member role: $e');
    }
  }

  /// Remove member from organization
  Future<void> removeMember(String memberId) async {
    try {
      await SupabaseService.delete('org_members', filters: {'id': memberId});
      _orgMembers.removeWhere((m) => m.id == memberId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing member: $e');
    }
  }

  // Vendor CRUD
  Future<Vendor?> addVendor(Vendor vendor) async {
    if (_currentOrg == null) return null;
    
    try {
      final data = vendor.toJson();
      await SupabaseService.insert('vendors', data);
      _vendors.add(vendor);
      notifyListeners();
      return vendor;
    } catch (e) {
      debugPrint('Error adding vendor: $e');
      return null;
    }
  }

  Future<void> updateVendor(Vendor vendor) async {
    try {
      await SupabaseService.update(
        'vendors',
        vendor.toJson(),
        filters: {'id': vendor.id},
      );
      
      final index = _vendors.indexWhere((v) => v.id == vendor.id);
      if (index != -1) {
        _vendors[index] = vendor;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating vendor: $e');
    }
  }

  Future<void> deleteVendor(String vendorId) async {
    try {
      await SupabaseService.delete('vendors', filters: {'id': vendorId});
      _vendors.removeWhere((v) => v.id == vendorId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting vendor: $e');
    }
  }

  Vendor? getVendorById(String id) => 
      _vendors.cast<Vendor?>().firstWhere((v) => v?.id == id, orElse: () => null);

  // Charge Type CRUD
  Future<ChargeType?> addChargeType(ChargeType chargeType) async {
    if (_currentOrg == null) return null;
    
    try {
      final data = chargeType.toJson();
      await SupabaseService.insert('charge_types', data);
      _chargeTypes.add(chargeType);
      notifyListeners();
      return chargeType;
    } catch (e) {
      debugPrint('Error adding charge type: $e');
      return null;
    }
  }

  Future<void> updateChargeType(ChargeType chargeType) async {
    try {
      await SupabaseService.update(
        'charge_types',
        chargeType.toJson(),
        filters: {'id': chargeType.id},
      );
      
      final index = _chargeTypes.indexWhere((c) => c.id == chargeType.id);
      if (index != -1) {
        _chargeTypes[index] = chargeType;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating charge type: $e');
    }
  }

  Future<void> deleteChargeType(String chargeTypeId) async {
    try {
      await SupabaseService.delete('charge_types', filters: {'id': chargeTypeId});
      _chargeTypes.removeWhere((c) => c.id == chargeTypeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting charge type: $e');
    }
  }

  ChargeType? getChargeTypeById(String id) => 
      _chargeTypes.cast<ChargeType?>().firstWhere((c) => c?.id == id, orElse: () => null);

  /// Clear service state (on logout)
  void clear() {
    _currentOrg = null;
    _currentMember = null;
    _userOrgs = [];
    _orgMembers = [];
    _vendors = [];
    _chargeTypes = [];
    notifyListeners();
  }

  String _generateUuid() => _uuid.v4();
}
