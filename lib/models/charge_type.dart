/// Charge type model for invoice line items
class ChargeType {
  final String id;
  final String orgId;
  final String name;
  final bool isRecurring;
  final double? defaultAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChargeType({
    required this.id,
    required this.orgId,
    required this.name,
    this.isRecurring = false,
    this.defaultAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  ChargeType copyWith({
    String? id,
    String? orgId,
    String? name,
    bool? isRecurring,
    double? defaultAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChargeType(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    name: name ?? this.name,
    isRecurring: isRecurring ?? this.isRecurring,
    defaultAmount: defaultAmount ?? this.defaultAmount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'name': name,
    'is_recurring': isRecurring,
    'default_amount': defaultAmount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ChargeType.fromJson(Map<String, dynamic> json) => ChargeType(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String,
    name: json['name'] as String,
    isRecurring: json['is_recurring'] as bool? ?? json['isRecurring'] as bool? ?? false,
    defaultAmount: json['default_amount'] != null 
        ? (json['default_amount'] as num).toDouble() 
        : json['defaultAmount'] != null 
            ? (json['defaultAmount'] as num).toDouble()
            : null,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : DateTime.now(),
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String) 
        : DateTime.now(),
  );

  /// Standard Kenyan charge types
  static List<String> get standardChargeTypes => [
    'Rent',
    'Water',
    'Garbage',
    'Service Charge',
    'Parking',
    'Electricity',
    'Security',
    'Penalty',
    'Deposit',
    'Other',
  ];
}
