/// User model representing an authenticated user profile
class User {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String) 
        : json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
  );

  /// Stub for auth_manager compatibility
  Future<void> sendEmailVerification() async {}
  
  /// Stub for auth_manager compatibility
  Future<void> refreshUser() async {}

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
