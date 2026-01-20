/// Audit log model for tracking critical actions
class AuditLog {
  final String id;
  final String orgId;
  final String? actorUserId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.orgId,
    this.actorUserId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'actor_user_id': actorUserId,
    'action': action,
    'entity_type': entityType,
    'entity_id': entityId,
    'metadata_json': metadata,
    'created_at': createdAt.toIso8601String(),
  };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String,
    actorUserId: json['actor_user_id'] as String? ?? json['actorUserId'] as String?,
    action: json['action'] as String,
    entityType: json['entity_type'] as String? ?? json['entityType'] as String,
    entityId: json['entity_id'] as String? ?? json['entityId'] as String,
    metadata: json['metadata_json'] as Map<String, dynamic>? ?? json['metadata'] as Map<String, dynamic>?,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : DateTime.now(),
  );

  /// Common audit actions
  static const String createLease = 'CREATE_LEASE';
  static const String activateLease = 'ACTIVATE_LEASE';
  static const String endLease = 'END_LEASE';
  static const String createInvoice = 'CREATE_INVOICE';
  static const String voidInvoice = 'VOID_INVOICE';
  static const String createPayment = 'CREATE_PAYMENT';
  static const String allocatePayment = 'ALLOCATE_PAYMENT';
  static const String editPayment = 'EDIT_PAYMENT';
  static const String deletePayment = 'DELETE_PAYMENT';
  static const String createTenant = 'CREATE_TENANT';
  static const String deleteTenant = 'DELETE_TENANT';
  static const String updateTenant = 'UPDATE_TENANT';
  static const String createProperty = 'CREATE_PROPERTY';
  static const String deleteProperty = 'DELETE_PROPERTY';
}
