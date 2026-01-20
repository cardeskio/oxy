class Tenant {
  final String id;
  final String orgId;
  final String fullName;
  final String phone;
  final String? idNumber;
  final String? email;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? userId; // Linked auth user ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Tenant({
    required this.id,
    required this.orgId,
    required this.fullName,
    required this.phone,
    this.idNumber,
    this.email,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLinkedToUser => userId != null;

  Tenant copyWith({
    String? id,
    String? orgId,
    String? fullName,
    String? phone,
    String? idNumber,
    String? email,
    String? nextOfKinName,
    String? nextOfKinPhone,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Tenant(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    idNumber: idNumber ?? this.idNumber,
    email: email ?? this.email,
    nextOfKinName: nextOfKinName ?? this.nextOfKinName,
    nextOfKinPhone: nextOfKinPhone ?? this.nextOfKinPhone,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'full_name': fullName,
    'phone': phone,
    'id_number': idNumber,
    'email': email,
    'next_of_kin_name': nextOfKinName,
    'next_of_kin_phone': nextOfKinPhone,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    fullName: json['full_name'] as String? ?? json['fullName'] as String,
    phone: json['phone'] as String,
    idNumber: json['id_number'] as String? ?? json['idNumber'] as String?,
    email: json['email'] as String?,
    nextOfKinName: json['next_of_kin_name'] as String? ?? json['nextOfKinName'] as String?,
    nextOfKinPhone: json['next_of_kin_phone'] as String? ?? json['nextOfKinPhone'] as String?,
    userId: json['user_id'] as String? ?? json['userId'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
  );

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
