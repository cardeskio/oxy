/// Vendor model for maintenance service providers
class Vendor {
  final String id;
  final String orgId;
  final String name;
  final String phone;
  final String trade;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vendor({
    required this.id,
    required this.orgId,
    required this.name,
    required this.phone,
    required this.trade,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Vendor copyWith({
    String? id,
    String? orgId,
    String? name,
    String? phone,
    String? trade,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Vendor(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    trade: trade ?? this.trade,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'name': name,
    'phone': phone,
    'trade': trade,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    trade: json['trade'] as String,
    notes: json['notes'] as String?,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : DateTime.now(),
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String) 
        : DateTime.now(),
  );

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
