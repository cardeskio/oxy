enum PropertyType { residential, commercial, mixed }

/// Image stored for property or unit
class PropertyImage {
  final String url;
  final String? caption;
  final DateTime addedAt;

  PropertyImage({
    required this.url,
    this.caption,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'caption': caption,
    'added_at': addedAt.toUtc().toIso8601String(),
  };

  factory PropertyImage.fromJson(Map<String, dynamic> json) => PropertyImage(
    url: json['url'] as String,
    caption: json['caption'] as String?,
    addedAt: DateTime.parse(json['added_at'] as String? ?? DateTime.now().toIso8601String()),
  );
}

class Property {
  final String id;
  final String orgId;
  final String name;
  final PropertyType type;
  final String locationText;
  final String? notes;
  final List<PropertyImage> images;
  final bool isListed;
  final String? listingDescription;
  final List<String> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  Property({
    required this.id,
    required this.orgId,
    required this.name,
    required this.type,
    required this.locationText,
    this.notes,
    this.images = const [],
    this.isListed = false,
    this.listingDescription,
    this.features = const [],
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
    List<PropertyImage>? images,
    bool? isListed,
    String? listingDescription,
    List<String>? features,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Property(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    name: name ?? this.name,
    type: type ?? this.type,
    locationText: locationText ?? this.locationText,
    notes: notes ?? this.notes,
    images: images ?? this.images,
    isListed: isListed ?? this.isListed,
    listingDescription: listingDescription ?? this.listingDescription,
    features: features ?? this.features,
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
    'images': images.map((i) => i.toJson()).toList(),
    'is_listed': isListed,
    'listing_description': listingDescription,
    'features': features,
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
    images: (json['images'] as List<dynamic>?)
        ?.map((i) => PropertyImage.fromJson(i as Map<String, dynamic>))
        .toList() ?? [],
    isListed: json['is_listed'] as bool? ?? false,
    listingDescription: json['listing_description'] as String?,
    features: (json['features'] as List<dynamic>?)
        ?.map((f) => f as String)
        .toList() ?? [],
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

  /// Get the first image URL or null
  String? get coverImageUrl => images.isNotEmpty ? images.first.url : null;
}
