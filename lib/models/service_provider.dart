/// Service category types for the Living feature
enum ServiceCategory {
  foodDining('food_dining', 'Food & Dining', '🍽️'),
  shopping('shopping', 'Shopping', '🛍️'),
  healthWellness('health_wellness', 'Health & Wellness', '💊'),
  homeServices('home_services', 'Home Services', '🔧'),
  professionalServices('professional_services', 'Professional Services', '💼'),
  entertainment('entertainment', 'Entertainment', '🎬'),
  transport('transport', 'Transport', '🚗'),
  education('education', 'Education', '📚'),
  beautySpa('beauty_spa', 'Beauty & Spa', '💅'),
  fitness('fitness', 'Fitness', '💪'),
  financial('financial', 'Financial', '💰'),
  other('other', 'Other', '📦');

  final String value;
  final String label;
  final String emoji;
  
  const ServiceCategory(this.value, this.label, this.emoji);
  
  static ServiceCategory fromValue(String value) {
    return ServiceCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ServiceCategory.other,
    );
  }
}

/// Provider account status
enum ProviderStatus {
  pending,
  active,
  suspended,
  inactive;
  
  static ProviderStatus fromValue(String value) {
    return ProviderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ProviderStatus.pending,
    );
  }
}

/// Business hours model
class BusinessHours {
  final Map<String, DayHours?> hours;
  
  BusinessHours({required this.hours});
  
  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    final hours = <String, DayHours?>{};
    for (final day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']) {
      if (json[day] != null) {
        hours[day] = DayHours.fromJson(json[day] as Map<String, dynamic>);
      } else {
        hours[day] = null; // Closed
      }
    }
    return BusinessHours(hours: hours);
  }
  
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    hours.forEach((day, dayHours) {
      if (dayHours != null) {
        result[day] = dayHours.toJson();
      }
    });
    return result;
  }
  
  bool isOpenNow() {
    final now = DateTime.now();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = dayNames[now.weekday - 1];
    final todayHours = hours[today];
    
    if (todayHours == null) return false;
    
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return currentTime.compareTo(todayHours.open) >= 0 && 
           currentTime.compareTo(todayHours.close) <= 0;
  }
  
  String? getTodayHours() {
    final now = DateTime.now();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = dayNames[now.weekday - 1];
    final todayHours = hours[today];
    
    if (todayHours == null) return 'Closed today';
    return '${todayHours.open} - ${todayHours.close}';
  }
}

class DayHours {
  final String open;
  final String close;
  
  DayHours({required this.open, required this.close});
  
  factory DayHours.fromJson(Map<String, dynamic> json) => DayHours(
    open: json['open'] as String,
    close: json['close'] as String,
  );
  
  Map<String, dynamic> toJson() => {'open': open, 'close': close};
}

/// Service Provider model
class ServiceProvider {
  final String id;
  final String userId;
  
  // Business details
  final String businessName;
  final String? businessDescription;
  final ServiceCategory category;
  final List<String> subcategories;
  
  // Contact
  final String phone;
  final String? email;
  final String? website;
  final String? whatsapp;
  
  // Location
  final String locationText;
  final double? latitude;
  final double? longitude;
  final double serviceRadiusKm;
  
  // Media
  final String? logoUrl;
  final String? coverImageUrl;
  final List<dynamic> images;
  
  // Hours
  final BusinessHours? businessHours;
  
  // Settings
  final ProviderStatus status;
  final bool isVerified;
  final bool isFeatured;
  
  // Stats
  final double ratingAverage;
  final int ratingCount;
  
  // Metadata
  final List<String> tags;
  final List<String> features;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed (from nearby query)
  final double? distanceKm;

  ServiceProvider({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessDescription,
    required this.category,
    this.subcategories = const [],
    required this.phone,
    this.email,
    this.website,
    this.whatsapp,
    required this.locationText,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm = 10,
    this.logoUrl,
    this.coverImageUrl,
    this.images = const [],
    this.businessHours,
    this.status = ProviderStatus.pending,
    this.isVerified = false,
    this.isFeatured = false,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.tags = const [],
    this.features = const [],
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) => ServiceProvider(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    businessName: json['business_name'] as String,
    businessDescription: json['business_description'] as String?,
    category: ServiceCategory.fromValue(json['category'] as String),
    subcategories: (json['subcategories'] as List<dynamic>?)?.cast<String>() ?? [],
    phone: json['phone'] as String,
    email: json['email'] as String?,
    website: json['website'] as String?,
    whatsapp: json['whatsapp'] as String?,
    locationText: json['location_text'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble() ?? 10,
    logoUrl: json['logo_url'] as String?,
    coverImageUrl: json['cover_image_url'] as String?,
    images: json['images'] as List<dynamic>? ?? [],
    businessHours: json['business_hours'] != null && json['business_hours'] is Map
        ? BusinessHours.fromJson(json['business_hours'] as Map<String, dynamic>)
        : null,
    status: ProviderStatus.fromValue(json['status'] as String? ?? 'pending'),
    isVerified: json['is_verified'] as bool? ?? false,
    isFeatured: json['is_featured'] as bool? ?? false,
    ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
    ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'business_name': businessName,
    'business_description': businessDescription,
    'category': category.value,
    'subcategories': subcategories,
    'phone': phone,
    'email': email,
    'website': website,
    'whatsapp': whatsapp,
    'location_text': locationText,
    'latitude': latitude,
    'longitude': longitude,
    'service_radius_km': serviceRadiusKm,
    'logo_url': logoUrl,
    'cover_image_url': coverImageUrl,
    'images': images,
    'business_hours': businessHours?.toJson(),
    'status': status.name,
    'is_verified': isVerified,
    'is_featured': isFeatured,
    'tags': tags,
    'features': features,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  ServiceProvider copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessDescription,
    ServiceCategory? category,
    List<String>? subcategories,
    String? phone,
    String? email,
    String? website,
    String? whatsapp,
    String? locationText,
    double? latitude,
    double? longitude,
    double? serviceRadiusKm,
    String? logoUrl,
    String? coverImageUrl,
    List<dynamic>? images,
    BusinessHours? businessHours,
    ProviderStatus? status,
    bool? isVerified,
    bool? isFeatured,
    double? ratingAverage,
    int? ratingCount,
    List<String>? tags,
    List<String>? features,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distanceKm,
  }) => ServiceProvider(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    businessName: businessName ?? this.businessName,
    businessDescription: businessDescription ?? this.businessDescription,
    category: category ?? this.category,
    subcategories: subcategories ?? this.subcategories,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    website: website ?? this.website,
    whatsapp: whatsapp ?? this.whatsapp,
    locationText: locationText ?? this.locationText,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
    logoUrl: logoUrl ?? this.logoUrl,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    images: images ?? this.images,
    businessHours: businessHours ?? this.businessHours,
    status: status ?? this.status,
    isVerified: isVerified ?? this.isVerified,
    isFeatured: isFeatured ?? this.isFeatured,
    ratingAverage: ratingAverage ?? this.ratingAverage,
    ratingCount: ratingCount ?? this.ratingCount,
    tags: tags ?? this.tags,
    features: features ?? this.features,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    distanceKm: distanceKm ?? this.distanceKm,
  );

  String get initials {
    final words = businessName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return businessName.substring(0, businessName.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get distanceLabel {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()}m away';
    }
    return '${distanceKm!.toStringAsFixed(1)}km away';
  }

  String get ratingLabel {
    if (ratingCount == 0) return 'No reviews yet';
    return '${ratingAverage.toStringAsFixed(1)} (${ratingCount} review${ratingCount == 1 ? '' : 's'})';
  }
}

/// Service Listing model
enum ListingStatus {
  active,
  paused,
  soldOut('sold_out'),
  expired;
  
  final String? _value;
  const ListingStatus([this._value]);
  
  String get value => _value ?? name;
  
  static ListingStatus fromValue(String value) {
    return ListingStatus.values.firstWhere(
      (s) => s.value == value || s.name == value,
      orElse: () => ListingStatus.active,
    );
  }
}

class ServiceListing {
  final String id;
  final String providerId;
  final String title;
  final String? description;
  final double? price;
  final String? priceUnit;
  final List<dynamic> images;
  final ListingStatus status;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceListing({
    required this.id,
    required this.providerId,
    required this.title,
    this.description,
    this.price,
    this.priceUnit,
    this.images = const [],
    this.status = ListingStatus.active,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceListing.fromJson(Map<String, dynamic> json) => ServiceListing(
    id: json['id'] as String,
    providerId: json['provider_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num?)?.toDouble(),
    priceUnit: json['price_unit'] as String?,
    images: json['images'] as List<dynamic>? ?? [],
    status: ListingStatus.fromValue(json['status'] as String? ?? 'active'),
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_id': providerId,
    'title': title,
    'description': description,
    'price': price,
    'price_unit': priceUnit,
    'images': images,
    'status': status.value,
    'tags': tags,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get priceLabel {
    if (price == null) return 'Contact for price';
    final priceStr = 'KES ${price!.toStringAsFixed(0)}';
    if (priceUnit == null) return priceStr;
    switch (priceUnit) {
      case 'per_hour': return '$priceStr/hr';
      case 'per_item': return '$priceStr/item';
      case 'per_service': return '$priceStr';
      case 'from': return 'From $priceStr';
      default: return priceStr;
    }
  }

  String? get coverImageUrl {
    if (images.isEmpty) return null;
    final first = images.first;
    if (first is Map) return first['url'] as String?;
    if (first is String) return first;
    return null;
  }
}

/// Service Review model
class ServiceReview {
  final String id;
  final String providerId;
  final String userId;
  final int rating;
  final String? comment;
  final String? providerResponse;
  final DateTime? providerResponseAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined from profiles
  final String? userName;
  final String? userAvatarUrl;

  ServiceReview({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.rating,
    this.comment,
    this.providerResponse,
    this.providerResponseAt,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    return ServiceReview(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      providerResponse: json['provider_response'] as String?,
      providerResponseAt: json['provider_response_at'] != null
          ? DateTime.parse(json['provider_response_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: profile?['full_name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_id': providerId,
    'user_id': userId,
    'rating': rating,
    'comment': comment,
    'provider_response': providerResponse,
    'provider_response_at': providerResponseAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
