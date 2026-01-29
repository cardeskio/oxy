enum EnquiryType { viewing, information, application }

enum EnquiryStatus { pending, contacted, scheduled, viewingDone, declined, converted }

class PropertyEnquiry {
  final String id;
  final String orgId;
  final String propertyId;
  final String? unitId;
  final String userId;
  final EnquiryType enquiryType;
  final EnquiryStatus status;
  final String? message;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final DateTime? preferredDate;
  final DateTime? scheduledDate;
  final String? managerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined fields (from queries)
  final String? propertyName;
  final String? unitLabel;

  PropertyEnquiry({
    required this.id,
    required this.orgId,
    required this.propertyId,
    this.unitId,
    required this.userId,
    required this.enquiryType,
    required this.status,
    this.message,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    this.preferredDate,
    this.scheduledDate,
    this.managerNotes,
    required this.createdAt,
    required this.updatedAt,
    this.propertyName,
    this.unitLabel,
  });

  PropertyEnquiry copyWith({
    String? id,
    String? orgId,
    String? propertyId,
    String? unitId,
    String? userId,
    EnquiryType? enquiryType,
    EnquiryStatus? status,
    String? message,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    DateTime? preferredDate,
    DateTime? scheduledDate,
    String? managerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? propertyName,
    String? unitLabel,
  }) => PropertyEnquiry(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    propertyId: propertyId ?? this.propertyId,
    unitId: unitId ?? this.unitId,
    userId: userId ?? this.userId,
    enquiryType: enquiryType ?? this.enquiryType,
    status: status ?? this.status,
    message: message ?? this.message,
    contactName: contactName ?? this.contactName,
    contactPhone: contactPhone ?? this.contactPhone,
    contactEmail: contactEmail ?? this.contactEmail,
    preferredDate: preferredDate ?? this.preferredDate,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    managerNotes: managerNotes ?? this.managerNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    propertyName: propertyName ?? this.propertyName,
    unitLabel: unitLabel ?? this.unitLabel,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'property_id': propertyId,
    'unit_id': unitId,
    'user_id': userId,
    'enquiry_type': enquiryTypeToDb(enquiryType),
    'status': statusToDb(status),
    'message': message,
    'contact_name': contactName,
    'contact_phone': contactPhone,
    'contact_email': contactEmail,
    'preferred_date': preferredDate?.toUtc().toIso8601String(),
    'scheduled_date': scheduledDate?.toUtc().toIso8601String(),
    'manager_notes': managerNotes,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory PropertyEnquiry.fromJson(Map<String, dynamic> json) => PropertyEnquiry(
    id: json['id'] as String,
    orgId: json['org_id'] as String,
    propertyId: json['property_id'] as String,
    unitId: json['unit_id'] as String?,
    userId: json['user_id'] as String,
    enquiryType: enquiryTypeFromDb(json['enquiry_type'] as String? ?? 'viewing'),
    status: statusFromDb(json['status'] as String? ?? 'pending'),
    message: json['message'] as String?,
    contactName: json['contact_name'] as String,
    contactPhone: json['contact_phone'] as String,
    contactEmail: json['contact_email'] as String?,
    preferredDate: json['preferred_date'] != null 
        ? DateTime.parse(json['preferred_date'] as String) 
        : null,
    scheduledDate: json['scheduled_date'] != null 
        ? DateTime.parse(json['scheduled_date'] as String) 
        : null,
    managerNotes: json['manager_notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    propertyName: json['property_name'] as String?,
    unitLabel: json['unit_label'] as String?,
  );

  String get enquiryTypeLabel {
    switch (enquiryType) {
      case EnquiryType.viewing: return 'Property Viewing';
      case EnquiryType.information: return 'Information Request';
      case EnquiryType.application: return 'Rental Application';
    }
  }

  String get statusLabel {
    switch (status) {
      case EnquiryStatus.pending: return 'Pending';
      case EnquiryStatus.contacted: return 'Contacted';
      case EnquiryStatus.scheduled: return 'Scheduled';
      case EnquiryStatus.viewingDone: return 'Viewing Done';
      case EnquiryStatus.declined: return 'Declined';
      case EnquiryStatus.converted: return 'Converted';
    }
  }

  static EnquiryType enquiryTypeFromDb(String value) {
    switch (value) {
      case 'viewing': return EnquiryType.viewing;
      case 'information': return EnquiryType.information;
      case 'application': return EnquiryType.application;
      default: return EnquiryType.viewing;
    }
  }

  static String enquiryTypeToDb(EnquiryType type) {
    switch (type) {
      case EnquiryType.viewing: return 'viewing';
      case EnquiryType.information: return 'information';
      case EnquiryType.application: return 'application';
    }
  }

  static EnquiryStatus statusFromDb(String value) {
    switch (value) {
      case 'pending': return EnquiryStatus.pending;
      case 'contacted': return EnquiryStatus.contacted;
      case 'scheduled': return EnquiryStatus.scheduled;
      case 'viewing_done': return EnquiryStatus.viewingDone;
      case 'declined': return EnquiryStatus.declined;
      case 'converted': return EnquiryStatus.converted;
      default: return EnquiryStatus.pending;
    }
  }

  static String statusToDb(EnquiryStatus status) {
    switch (status) {
      case EnquiryStatus.pending: return 'pending';
      case EnquiryStatus.contacted: return 'contacted';
      case EnquiryStatus.scheduled: return 'scheduled';
      case EnquiryStatus.viewingDone: return 'viewing_done';
      case EnquiryStatus.declined: return 'declined';
      case EnquiryStatus.converted: return 'converted';
    }
  }
}

/// Listed property for explore page
class ListedProperty {
  final String id;
  final String orgId;
  final String name;
  final String type;
  final String locationText;
  final List<dynamic> images;
  final String? listingDescription;
  final List<String> features;
  final int availableUnits;
  final double? minRent;
  final double? maxRent;
  final DateTime createdAt;

  ListedProperty({
    required this.id,
    required this.orgId,
    required this.name,
    required this.type,
    required this.locationText,
    required this.images,
    this.listingDescription,
    this.features = const [],
    required this.availableUnits,
    this.minRent,
    this.maxRent,
    required this.createdAt,
  });

  factory ListedProperty.fromJson(Map<String, dynamic> json) => ListedProperty(
    id: json['id'] as String,
    orgId: json['org_id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    locationText: json['location_text'] as String,
    images: json['images'] as List<dynamic>? ?? [],
    listingDescription: json['listing_description'] as String?,
    features: (json['features'] as List<dynamic>?)
        ?.map((f) => f as String)
        .toList() ?? [],
    availableUnits: (json['available_units'] as num?)?.toInt() ?? 0,
    minRent: (json['min_rent'] as num?)?.toDouble(),
    maxRent: (json['max_rent'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  String get typeLabel {
    switch (type) {
      case 'residential': return 'Residential';
      case 'commercial': return 'Commercial';
      case 'mixed': return 'Mixed Use';
      default: return type;
    }
  }

  String? get coverImageUrl {
    if (images.isEmpty) return null;
    final first = images.first;
    if (first is Map) return first['url'] as String?;
    return null;
  }

  String get rentRangeLabel {
    if (minRent == null && maxRent == null) return 'Contact for pricing';
    if (minRent == maxRent) return 'KES ${minRent!.toStringAsFixed(0)}/mo';
    return 'KES ${minRent?.toStringAsFixed(0) ?? '?'} - ${maxRent?.toStringAsFixed(0) ?? '?'}/mo';
  }
}

/// Enquiry comment for communication thread
class EnquiryComment {
  final String id;
  final String enquiryId;
  final String userId;
  final String orgId;
  final String content;
  final bool isFromManager;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined from profiles
  final String? userName;
  final String? userEmail;

  EnquiryComment({
    required this.id,
    required this.enquiryId,
    required this.userId,
    required this.orgId,
    required this.content,
    required this.isFromManager,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
  });

  factory EnquiryComment.fromJson(Map<String, dynamic> json) => EnquiryComment(
    id: json['id'] as String,
    enquiryId: json['enquiry_id'] as String,
    userId: json['user_id'] as String,
    orgId: json['org_id'] as String,
    content: json['content'] as String,
    isFromManager: json['is_from_manager'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    userName: json['user_name'] as String?,
    userEmail: json['user_email'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'enquiry_id': enquiryId,
    'user_id': userId,
    'org_id': orgId,
    'content': content,
    'is_from_manager': isFromManager,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

/// Listed unit for explore page
class ListedUnit {
  final String id;
  final String orgId;
  final String propertyId;
  final String unitLabel;
  final String? unitType;
  final double rentAmount;
  final double depositAmount;
  final List<dynamic> images;
  final String? listingDescription;
  final List<String> amenities;
  final String propertyName;
  final String propertyLocation;
  final String propertyType;
  final List<dynamic> propertyImages;
  final DateTime createdAt;

  ListedUnit({
    required this.id,
    required this.orgId,
    required this.propertyId,
    required this.unitLabel,
    this.unitType,
    required this.rentAmount,
    required this.depositAmount,
    required this.images,
    this.listingDescription,
    required this.amenities,
    required this.propertyName,
    required this.propertyLocation,
    required this.propertyType,
    required this.propertyImages,
    required this.createdAt,
  });

  factory ListedUnit.fromJson(Map<String, dynamic> json) => ListedUnit(
    id: json['id'] as String,
    orgId: json['org_id'] as String,
    propertyId: json['property_id'] as String,
    unitLabel: json['unit_label'] as String,
    unitType: json['unit_type'] as String?,
    rentAmount: (json['rent_amount'] as num).toDouble(),
    depositAmount: (json['deposit_amount'] as num).toDouble(),
    images: json['images'] as List<dynamic>? ?? [],
    listingDescription: json['listing_description'] as String?,
    amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
    propertyName: json['property_name'] as String,
    propertyLocation: json['property_location'] as String,
    propertyType: json['property_type'] as String,
    propertyImages: json['property_images'] as List<dynamic>? ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  String? get coverImageUrl {
    // Prefer unit images, fall back to property images
    final imageList = images.isNotEmpty ? images : propertyImages;
    if (imageList.isEmpty) return null;
    final first = imageList.first;
    if (first is Map) return first['url'] as String?;
    return null;
  }
}
