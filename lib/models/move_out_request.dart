enum MoveOutStatus { pending, approved, rejected, cancelled }

class MoveOutRequest {
  final String id;
  final String tenantId;
  final String leaseId;
  final String orgId;
  final DateTime requestedAt;
  final DateTime preferredMoveOutDate;
  final String? reason;
  final MoveOutStatus status;
  final String? adminNotes;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MoveOutRequest({
    required this.id,
    required this.tenantId,
    required this.leaseId,
    required this.orgId,
    required this.requestedAt,
    required this.preferredMoveOutDate,
    this.reason,
    required this.status,
    this.adminNotes,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == MoveOutStatus.pending;
  bool get isApproved => status == MoveOutStatus.approved;
  bool get isRejected => status == MoveOutStatus.rejected;
  bool get isCancelled => status == MoveOutStatus.cancelled;

  MoveOutRequest copyWith({
    String? id,
    String? tenantId,
    String? leaseId,
    String? orgId,
    DateTime? requestedAt,
    DateTime? preferredMoveOutDate,
    String? reason,
    MoveOutStatus? status,
    String? adminNotes,
    DateTime? respondedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MoveOutRequest(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    leaseId: leaseId ?? this.leaseId,
    orgId: orgId ?? this.orgId,
    requestedAt: requestedAt ?? this.requestedAt,
    preferredMoveOutDate: preferredMoveOutDate ?? this.preferredMoveOutDate,
    reason: reason ?? this.reason,
    status: status ?? this.status,
    adminNotes: adminNotes ?? this.adminNotes,
    respondedAt: respondedAt ?? this.respondedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'lease_id': leaseId,
    'org_id': orgId,
    'requested_at': requestedAt.toIso8601String(),
    'preferred_move_out_date': preferredMoveOutDate.toIso8601String(),
    'reason': reason,
    'status': status.name,
    'admin_notes': adminNotes,
    'responded_at': respondedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory MoveOutRequest.fromJson(Map<String, dynamic> json) => MoveOutRequest(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    leaseId: json['lease_id'] as String,
    orgId: json['org_id'] as String,
    requestedAt: DateTime.parse(json['requested_at'] as String),
    preferredMoveOutDate: DateTime.parse(json['preferred_move_out_date'] as String),
    reason: json['reason'] as String?,
    status: MoveOutStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => MoveOutStatus.pending,
    ),
    adminNotes: json['admin_notes'] as String?,
    respondedAt: json['responded_at'] != null 
        ? DateTime.parse(json['responded_at'] as String) 
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  String get statusLabel {
    switch (status) {
      case MoveOutStatus.pending:
        return 'Pending';
      case MoveOutStatus.approved:
        return 'Approved';
      case MoveOutStatus.rejected:
        return 'Rejected';
      case MoveOutStatus.cancelled:
        return 'Cancelled';
    }
  }
}
