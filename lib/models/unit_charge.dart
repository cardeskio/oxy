/// Unit-specific charge amount override
class UnitCharge {
  final String id;
  final String orgId;
  final String unitId;
  final String chargeTypeId;
  final double amount;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? chargeTypeName;
  final String? unitLabel;
  final String? tenantName;
  final String? tenantId;

  UnitCharge({
    required this.id,
    required this.orgId,
    required this.unitId,
    required this.chargeTypeId,
    required this.amount,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.chargeTypeName,
    this.unitLabel,
    this.tenantName,
    this.tenantId,
  });

  UnitCharge copyWith({
    String? id,
    String? orgId,
    String? unitId,
    String? chargeTypeId,
    double? amount,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? chargeTypeName,
    String? unitLabel,
    String? tenantName,
    String? tenantId,
  }) => UnitCharge(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    unitId: unitId ?? this.unitId,
    chargeTypeId: chargeTypeId ?? this.chargeTypeId,
    amount: amount ?? this.amount,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    chargeTypeName: chargeTypeName ?? this.chargeTypeName,
    unitLabel: unitLabel ?? this.unitLabel,
    tenantName: tenantName ?? this.tenantName,
    tenantId: tenantId ?? this.tenantId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'unit_id': unitId,
    'charge_type_id': chargeTypeId,
    'amount': amount,
    'is_enabled': isEnabled,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory UnitCharge.fromJson(Map<String, dynamic> json) {
    final chargeType = json['charge_types'] as Map<String, dynamic>?;
    final unit = json['units'] as Map<String, dynamic>?;
    
    return UnitCharge(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      unitId: json['unit_id'] as String,
      chargeTypeId: json['charge_type_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      chargeTypeName: chargeType?['name'] as String?,
      unitLabel: unit?['unit_label'] as String?,
      tenantName: json['tenant_name'] as String?,
      tenantId: json['tenant_id'] as String?,
    );
  }
}

/// Summary of all charges for a unit with current tenant
class UnitChargeSummary {
  final String unitId;
  final String unitLabel;
  final String propertyId;
  final String propertyName;
  final String? tenantId;
  final String? tenantName;
  final double rentAmount;
  final Map<String, UnitChargeEntry> charges; // chargeTypeId -> entry

  UnitChargeSummary({
    required this.unitId,
    required this.unitLabel,
    required this.propertyId,
    required this.propertyName,
    this.tenantId,
    this.tenantName,
    required this.rentAmount,
    required this.charges,
  });

  double get totalCharges => 
    rentAmount + charges.values.where((c) => c.isEnabled).fold(0.0, (sum, c) => sum + c.amount);

  bool get hasActiveTenant => tenantId != null;
}

/// Single charge entry in a unit summary
class UnitChargeEntry {
  final String? unitChargeId; // null if using default
  final String chargeTypeId;
  final String chargeTypeName;
  final double amount;
  final double defaultAmount;
  final bool isEnabled;
  final bool isCustom; // true if amount differs from default

  UnitChargeEntry({
    this.unitChargeId,
    required this.chargeTypeId,
    required this.chargeTypeName,
    required this.amount,
    required this.defaultAmount,
    required this.isEnabled,
  }) : isCustom = amount != defaultAmount;

  UnitChargeEntry copyWith({
    String? unitChargeId,
    String? chargeTypeId,
    String? chargeTypeName,
    double? amount,
    double? defaultAmount,
    bool? isEnabled,
  }) => UnitChargeEntry(
    unitChargeId: unitChargeId ?? this.unitChargeId,
    chargeTypeId: chargeTypeId ?? this.chargeTypeId,
    chargeTypeName: chargeTypeName ?? this.chargeTypeName,
    amount: amount ?? this.amount,
    defaultAmount: defaultAmount ?? this.defaultAmount,
    isEnabled: isEnabled ?? this.isEnabled,
  );
}
