enum LeaseStatus { draft, active, ended }
enum LateFeeType { none, fixed, percent }

class Lease {
  final String id;
  final String orgId;
  final String unitId;
  final String tenantId;
  final String propertyId;
  final DateTime startDate;
  final DateTime? endDate;
  final double rentAmount;
  final double depositAmount;
  final int dueDay;
  final int graceDays;
  final LateFeeType lateFeeType;
  final double? lateFeeValue;
  final LeaseStatus status;
  final String? moveInNotes;
  final String? moveOutNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lease({
    required this.id,
    required this.orgId,
    required this.unitId,
    required this.tenantId,
    required this.propertyId,
    required this.startDate,
    this.endDate,
    required this.rentAmount,
    required this.depositAmount,
    required this.dueDay,
    required this.graceDays,
    required this.lateFeeType,
    this.lateFeeValue,
    required this.status,
    this.moveInNotes,
    this.moveOutNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  Lease copyWith({
    String? id,
    String? orgId,
    String? unitId,
    String? tenantId,
    String? propertyId,
    DateTime? startDate,
    DateTime? endDate,
    double? rentAmount,
    double? depositAmount,
    int? dueDay,
    int? graceDays,
    LateFeeType? lateFeeType,
    double? lateFeeValue,
    LeaseStatus? status,
    String? moveInNotes,
    String? moveOutNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Lease(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    unitId: unitId ?? this.unitId,
    tenantId: tenantId ?? this.tenantId,
    propertyId: propertyId ?? this.propertyId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    rentAmount: rentAmount ?? this.rentAmount,
    depositAmount: depositAmount ?? this.depositAmount,
    dueDay: dueDay ?? this.dueDay,
    graceDays: graceDays ?? this.graceDays,
    lateFeeType: lateFeeType ?? this.lateFeeType,
    lateFeeValue: lateFeeValue ?? this.lateFeeValue,
    status: status ?? this.status,
    moveInNotes: moveInNotes ?? this.moveInNotes,
    moveOutNotes: moveOutNotes ?? this.moveOutNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'unit_id': unitId,
    'tenant_id': tenantId,
    'property_id': propertyId,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'rent_amount': rentAmount,
    'deposit_amount': depositAmount,
    'due_day': dueDay,
    'grace_days': graceDays,
    'late_fee_type': lateFeeType.name,
    'late_fee_value': lateFeeValue,
    'status': status.name,
    'move_in_notes': moveInNotes,
    'move_out_notes': moveOutNotes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Lease.fromJson(Map<String, dynamic> json) => Lease(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    unitId: json['unit_id'] as String? ?? json['unitId'] as String,
    tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String,
    propertyId: json['property_id'] as String? ?? json['propertyId'] as String,
    startDate: DateTime.parse(json['start_date'] as String? ?? json['startDate'] as String),
    endDate: (json['end_date'] ?? json['endDate']) != null 
        ? DateTime.parse(json['end_date'] as String? ?? json['endDate'] as String) 
        : null,
    rentAmount: (json['rent_amount'] as num? ?? json['rentAmount'] as num).toDouble(),
    depositAmount: (json['deposit_amount'] as num? ?? json['depositAmount'] as num).toDouble(),
    dueDay: json['due_day'] as int? ?? json['dueDay'] as int,
    graceDays: json['grace_days'] as int? ?? json['graceDays'] as int,
    lateFeeType: LateFeeType.values.firstWhere((e) => e.name == (json['late_fee_type'] ?? json['lateFeeType'])),
    lateFeeValue: (json['late_fee_value'] ?? json['lateFeeValue']) != null 
        ? ((json['late_fee_value'] ?? json['lateFeeValue']) as num).toDouble() 
        : null,
    status: LeaseStatus.values.firstWhere((e) => e.name == json['status']),
    moveInNotes: json['move_in_notes'] as String? ?? json['moveInNotes'] as String?,
    moveOutNotes: json['move_out_notes'] as String? ?? json['moveOutNotes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
  );

  String get statusLabel {
    switch (status) {
      case LeaseStatus.draft: return 'Draft';
      case LeaseStatus.active: return 'Active';
      case LeaseStatus.ended: return 'Ended';
    }
  }

  bool get isActive => status == LeaseStatus.active;
}
