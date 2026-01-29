/// Order status enum
enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  preparing('preparing', 'Preparing'),
  ready('ready', 'Ready'),
  outForDelivery('out_for_delivery', 'Out for Delivery'),
  delivered('delivered', 'Delivered'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;

  const OrderStatus(this.value, this.label);

  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  bool get isActive => this != cancelled && this != completed;
  bool get canCancel => this == pending || this == confirmed;
  bool get isDelivered => this == delivered || this == completed;
}

/// Delivery type enum
enum DeliveryType {
  delivery('delivery', 'Delivery'),
  pickup('pickup', 'Pickup');

  final String value;
  final String label;

  const DeliveryType(this.value, this.label);

  static DeliveryType fromValue(String value) {
    return DeliveryType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => DeliveryType.delivery,
    );
  }
}

/// Order item model
class OrderItem {
  final String? id;
  final String? orderId;
  final String? listingId;
  final String title;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  OrderItem({
    this.id,
    this.orderId,
    this.listingId,
    required this.title,
    this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String?,
    orderId: json['order_id'] as String?,
    listingId: json['listing_id'] as String?,
    title: json['title'] as String,
    description: json['description'] as String?,
    quantity: json['quantity'] as int? ?? 1,
    unitPrice: (json['unit_price'] as num).toDouble(),
    totalPrice: (json['total_price'] as num).toDouble(),
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (orderId != null) 'order_id': orderId,
    if (listingId != null) 'listing_id': listingId,
    'title': title,
    if (description != null) 'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    if (notes != null) 'notes': notes,
  };

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? listingId,
    String? title,
    String? description,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
  }) => OrderItem(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    listingId: listingId ?? this.listingId,
    title: title ?? this.title,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    totalPrice: totalPrice ?? this.totalPrice,
    notes: notes ?? this.notes,
  );
}

/// Order model
class Order {
  final String id;
  final String customerId;
  final String providerId;
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final DeliveryType deliveryType;
  final String? deliveryAddress;
  final String? deliveryApartment;
  final String? deliveryUnit;
  final String? deliveryInstructions;
  final String deliveryPhone;
  final String deliveryName;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final DateTime? requestedTime;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final String? customerNotes;
  final String? providerNotes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;

  // Joined data
  final String? providerName;
  final String? providerLogo;
  final String? customerName;

  Order({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 0,
    required this.totalAmount,
    required this.deliveryType,
    this.deliveryAddress,
    this.deliveryApartment,
    this.deliveryUnit,
    this.deliveryInstructions,
    required this.deliveryPhone,
    required this.deliveryName,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.requestedTime,
    this.estimatedDelivery,
    this.actualDelivery,
    this.customerNotes,
    this.providerNotes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.completedAt,
    this.providerName,
    this.providerLogo,
    this.customerName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse items from JSONB
    List<OrderItem> items = [];
    if (json['items'] != null) {
      final itemsList = json['items'] as List;
      items = itemsList.map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList();
    }

    // Get provider info if joined
    final provider = json['service_providers'] as Map<String, dynamic>?;
    final customer = json['profiles'] as Map<String, dynamic>?;

    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      orderNumber: json['order_number'] as String,
      status: OrderStatus.fromValue(json['status'] as String),
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryType: DeliveryType.fromValue(json['delivery_type'] as String? ?? 'delivery'),
      deliveryAddress: json['delivery_address'] as String?,
      deliveryApartment: json['delivery_apartment'] as String?,
      deliveryUnit: json['delivery_unit'] as String?,
      deliveryInstructions: json['delivery_instructions'] as String?,
      deliveryPhone: json['delivery_phone'] as String,
      deliveryName: json['delivery_name'] as String,
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
      requestedTime: json['requested_time'] != null 
          ? DateTime.parse(json['requested_time'] as String) 
          : null,
      estimatedDelivery: json['estimated_delivery'] != null 
          ? DateTime.parse(json['estimated_delivery'] as String) 
          : null,
      actualDelivery: json['actual_delivery'] != null 
          ? DateTime.parse(json['actual_delivery'] as String) 
          : null,
      customerNotes: json['customer_notes'] as String?,
      providerNotes: json['provider_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      confirmedAt: json['confirmed_at'] != null 
          ? DateTime.parse(json['confirmed_at'] as String) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      providerName: provider?['business_name'] as String?,
      providerLogo: provider?['logo_url'] as String?,
      customerName: customer?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'provider_id': providerId,
    'order_number': orderNumber,
    'status': status.value,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'delivery_fee': deliveryFee,
    'total_amount': totalAmount,
    'delivery_type': deliveryType.value,
    'delivery_address': deliveryAddress,
    'delivery_apartment': deliveryApartment,
    'delivery_unit': deliveryUnit,
    'delivery_instructions': deliveryInstructions,
    'delivery_phone': deliveryPhone,
    'delivery_name': deliveryName,
    'delivery_latitude': deliveryLatitude,
    'delivery_longitude': deliveryLongitude,
    'requested_time': requestedTime?.toIso8601String(),
    'estimated_delivery': estimatedDelivery?.toIso8601String(),
    'actual_delivery': actualDelivery?.toIso8601String(),
    'customer_notes': customerNotes,
    'provider_notes': providerNotes,
    'cancellation_reason': cancellationReason,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'confirmed_at': confirmedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  Order copyWith({
    String? id,
    String? customerId,
    String? providerId,
    String? orderNumber,
    OrderStatus? status,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? totalAmount,
    DeliveryType? deliveryType,
    String? deliveryAddress,
    String? deliveryApartment,
    String? deliveryUnit,
    String? deliveryInstructions,
    String? deliveryPhone,
    String? deliveryName,
    double? deliveryLatitude,
    double? deliveryLongitude,
    DateTime? requestedTime,
    DateTime? estimatedDelivery,
    DateTime? actualDelivery,
    String? customerNotes,
    String? providerNotes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    String? providerName,
    String? providerLogo,
    String? customerName,
  }) => Order(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    providerId: providerId ?? this.providerId,
    orderNumber: orderNumber ?? this.orderNumber,
    status: status ?? this.status,
    items: items ?? this.items,
    subtotal: subtotal ?? this.subtotal,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    totalAmount: totalAmount ?? this.totalAmount,
    deliveryType: deliveryType ?? this.deliveryType,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    deliveryApartment: deliveryApartment ?? this.deliveryApartment,
    deliveryUnit: deliveryUnit ?? this.deliveryUnit,
    deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    deliveryPhone: deliveryPhone ?? this.deliveryPhone,
    deliveryName: deliveryName ?? this.deliveryName,
    deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
    deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
    requestedTime: requestedTime ?? this.requestedTime,
    estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    actualDelivery: actualDelivery ?? this.actualDelivery,
    customerNotes: customerNotes ?? this.customerNotes,
    providerNotes: providerNotes ?? this.providerNotes,
    cancellationReason: cancellationReason ?? this.cancellationReason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    completedAt: completedAt ?? this.completedAt,
    providerName: providerName ?? this.providerName,
    providerLogo: providerLogo ?? this.providerLogo,
    customerName: customerName ?? this.customerName,
  );

  String get statusEmoji {
    switch (status) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.preparing:
        return '👨‍🍳';
      case OrderStatus.ready:
        return '📦';
      case OrderStatus.outForDelivery:
        return '🚗';
      case OrderStatus.delivered:
        return '🎉';
      case OrderStatus.completed:
        return '✨';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
}

/// User delivery settings model
class UserDeliverySettings {
  final String id;
  final String userId;
  final String? defaultName;
  final String? defaultPhone;
  final String? defaultAddress;
  final String? defaultApartment;
  final String? defaultUnit;
  final String? defaultInstructions;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDeliverySettings({
    required this.id,
    required this.userId,
    this.defaultName,
    this.defaultPhone,
    this.defaultAddress,
    this.defaultApartment,
    this.defaultUnit,
    this.defaultInstructions,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDeliverySettings.fromJson(Map<String, dynamic> json) => UserDeliverySettings(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    defaultName: json['default_name'] as String?,
    defaultPhone: json['default_phone'] as String?,
    defaultAddress: json['default_address'] as String?,
    defaultApartment: json['default_apartment'] as String?,
    defaultUnit: json['default_unit'] as String?,
    defaultInstructions: json['default_instructions'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'default_name': defaultName,
    'default_phone': defaultPhone,
    'default_address': defaultAddress,
    'default_apartment': defaultApartment,
    'default_unit': defaultUnit,
    'default_instructions': defaultInstructions,
    'latitude': latitude,
    'longitude': longitude,
  };

  UserDeliverySettings copyWith({
    String? id,
    String? userId,
    String? defaultName,
    String? defaultPhone,
    String? defaultAddress,
    String? defaultApartment,
    String? defaultUnit,
    String? defaultInstructions,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserDeliverySettings(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    defaultName: defaultName ?? this.defaultName,
    defaultPhone: defaultPhone ?? this.defaultPhone,
    defaultAddress: defaultAddress ?? this.defaultAddress,
    defaultApartment: defaultApartment ?? this.defaultApartment,
    defaultUnit: defaultUnit ?? this.defaultUnit,
    defaultInstructions: defaultInstructions ?? this.defaultInstructions,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Cart item for local cart management
class CartItem {
  final String listingId;
  final String providerId;
  final String title;
  final String? description;
  final double price;
  final String? priceUnit;
  final String? imageUrl;
  int quantity;
  String? notes;

  CartItem({
    required this.listingId,
    required this.providerId,
    required this.title,
    this.description,
    required this.price,
    this.priceUnit,
    this.imageUrl,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice => price * quantity;

  OrderItem toOrderItem() => OrderItem(
    listingId: listingId,
    title: title,
    description: description,
    quantity: quantity,
    unitPrice: price,
    totalPrice: totalPrice,
    notes: notes,
  );
}
