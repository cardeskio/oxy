enum PropertyType { residential, commercial, mixed }

class Property {
  final String id;
  final String orgId;
  final String name;
  final PropertyType type;
  final String locationText;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Property({
    required this.id,
    required this.orgId,
    required this.name,
    required this.type,
    required this.locationText,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Property copyWith({
    String? id,
    String? orgId,
    String? name,
    PropertyType? type,
    String? locationText,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Property(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    name: name ?? this.name,
    type: type ?? this.type,
    locationText: locationText ?? this.locationText,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'name': name,
    'type': type.name,
    'location_text': locationText,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Property.fromJson(Map<String, dynamic> json) => Property(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    name: json['name'] as String,
    type: PropertyType.values.firstWhere((e) => e.name == json['type']),
    locationText: json['location_text'] as String? ?? json['locationText'] as String,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
  );

  String get typeLabel {
    switch (type) {
      case PropertyType.residential: return 'Residential';
      case PropertyType.commercial: return 'Commercial';
      case PropertyType.mixed: return 'Mixed Use';
    }
  }
}
