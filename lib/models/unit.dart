enum UnitStatus { vacant, occupied, maintenance }

class Unit {
  final String id;
  final String orgId;
  final String propertyId;
  final String unitLabel;
  final String? unitType;
  final String? unitTypeId;
  final double rentAmount;
  final double depositAmount;
  final UnitStatus status;
  final String? meterRefWater;
  final String? meterRefPower;
  final DateTime createdAt;
  final DateTime updatedAt;

  Unit({
    required this.id,
    required this.orgId,
    required this.propertyId,
    required this.unitLabel,
    this.unitType,
    this.unitTypeId,
    required this.rentAmount,
    required this.depositAmount,
    required this.status,
    this.meterRefWater,
    this.meterRefPower,
    required this.createdAt,
    required this.updatedAt,
  });

  Unit copyWith({
    String? id,
    String? orgId,
    String? propertyId,
    String? unitLabel,
    String? unitType,
    String? unitTypeId,
    double? rentAmount,
    double? depositAmount,
    UnitStatus? status,
    String? meterRefWater,
    String? meterRefPower,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Unit(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    propertyId: propertyId ?? this.propertyId,
    unitLabel: unitLabel ?? this.unitLabel,
    unitType: unitType ?? this.unitType,
    unitTypeId: unitTypeId ?? this.unitTypeId,
    rentAmount: rentAmount ?? this.rentAmount,
    depositAmount: depositAmount ?? this.depositAmount,
    status: status ?? this.status,
    meterRefWater: meterRefWater ?? this.meterRefWater,
    meterRefPower: meterRefPower ?? this.meterRefPower,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'property_id': propertyId,
    'unit_label': unitLabel,
    'unit_type': unitType,
    'unit_type_id': unitTypeId,
    'rent_amount': rentAmount,
    'deposit_amount': depositAmount,
    'status': status.name,
    'meter_ref_water': meterRefWater,
    'meter_ref_power': meterRefPower,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    propertyId: json['property_id'] as String? ?? json['propertyId'] as String,
    unitLabel: json['unit_label'] as String? ?? json['unitLabel'] as String,
    unitType: json['unit_type'] as String? ?? json['unitType'] as String?,
    unitTypeId: json['unit_type_id'] as String? ?? json['unitTypeId'] as String?,
    rentAmount: (json['rent_amount'] as num? ?? json['rentAmount'] as num).toDouble(),
    depositAmount: (json['deposit_amount'] as num? ?? json['depositAmount'] as num).toDouble(),
    status: UnitStatus.values.firstWhere((e) => e.name == json['status']),
    meterRefWater: json['meter_ref_water'] as String? ?? json['meterRefWater'] as String?,
    meterRefPower: json['meter_ref_power'] as String? ?? json['meterRefPower'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
  );

  String get statusLabel {
    switch (status) {
      case UnitStatus.vacant: return 'Vacant';
      case UnitStatus.occupied: return 'Occupied';
      case UnitStatus.maintenance: return 'Maintenance';
    }
  }
}
