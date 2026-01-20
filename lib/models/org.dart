/// Organization model for multi-tenant isolation
class Org {
  final String id;
  final String name;
  final String country;
  final DateTime createdAt;
  final DateTime updatedAt;

  Org({
    required this.id,
    required this.name,
    this.country = 'KE',
    required this.createdAt,
    required this.updatedAt,
  });

  Org copyWith({
    String? id,
    String? name,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Org(
    id: id ?? this.id,
    name: name ?? this.name,
    country: country ?? this.country,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Org.fromJson(Map<String, dynamic> json) => Org(
    id: json['id'] as String,
    name: json['name'] as String,
    country: json['country'] as String? ?? 'KE',
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : DateTime.now(),
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String) 
        : DateTime.now(),
  );
}

/// Organization member role
enum OrgRole { owner, manager, accountant, caretaker, tenantAdmin }

extension OrgRoleExtension on OrgRole {
  String get value {
    switch (this) {
      case OrgRole.owner: return 'owner';
      case OrgRole.manager: return 'manager';
      case OrgRole.accountant: return 'accountant';
      case OrgRole.caretaker: return 'caretaker';
      case OrgRole.tenantAdmin: return 'tenant_admin';
    }
  }
  
  String get label {
    switch (this) {
      case OrgRole.owner: return 'Owner';
      case OrgRole.manager: return 'Manager';
      case OrgRole.accountant: return 'Accountant';
      case OrgRole.caretaker: return 'Caretaker';
      case OrgRole.tenantAdmin: return 'Tenant Admin';
    }
  }
  
  static OrgRole fromString(String value) {
    switch (value) {
      case 'owner': return OrgRole.owner;
      case 'manager': return OrgRole.manager;
      case 'accountant': return OrgRole.accountant;
      case 'caretaker': return OrgRole.caretaker;
      case 'tenant_admin': return OrgRole.tenantAdmin;
      default: return OrgRole.caretaker;
    }
  }
}

/// Organization member model
class OrgMember {
  final String id;
  final String orgId;
  final String userId;
  final OrgRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrgMember({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  OrgMember copyWith({
    String? id,
    String? orgId,
    String? userId,
    OrgRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OrgMember(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'user_id': userId,
    'role': role.value,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory OrgMember.fromJson(Map<String, dynamic> json) => OrgMember(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String,
    userId: json['user_id'] as String? ?? json['userId'] as String,
    role: OrgRoleExtension.fromString(json['role'] as String),
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : DateTime.now(),
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String) 
        : DateTime.now(),
  );
  
  /// Check if member can perform manager-level actions
  bool get canManage => role == OrgRole.owner || role == OrgRole.manager;
  
  /// Check if member can perform financial actions
  bool get canManageFinances => role == OrgRole.owner || role == OrgRole.manager || role == OrgRole.accountant;
  
  /// Check if member is org owner
  bool get isOwner => role == OrgRole.owner;
}
