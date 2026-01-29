class TicketAttachment {
  final String url;
  final String name;
  final String type; // 'image' or 'video'
  final int? size;

  TicketAttachment({
    required this.url,
    required this.name,
    required this.type,
    this.size,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      url: json['url'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'type': type,
    if (size != null) 'size': size,
  };

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
}

class TicketComment {
  final String id;
  final String ticketId;
  final String userId;
  final String orgId;
  final String content;
  final List<TicketAttachment> attachments;
  final bool isInternal;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined data
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final bool? isManager;

  TicketComment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.orgId,
    required this.content,
    this.attachments = const [],
    this.isInternal = false,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.isManager,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List<dynamic>? ?? [];
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    return TicketComment(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      orgId: json['org_id'] as String,
      content: json['content'] as String,
      attachments: attachmentsJson
          .map((a) => TicketAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      isInternal: json['is_internal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: profile?['full_name'] as String?,
      userEmail: profile?['email'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
      isManager: json['is_manager'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticket_id': ticketId,
    'user_id': userId,
    'org_id': orgId,
    'content': content,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'is_internal': isInternal,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  TicketComment copyWith({
    String? id,
    String? ticketId,
    String? userId,
    String? orgId,
    String? content,
    List<TicketAttachment>? attachments,
    bool? isInternal,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
    bool? isManager,
  }) {
    return TicketComment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      orgId: orgId ?? this.orgId,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      isInternal: isInternal ?? this.isInternal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isManager: isManager ?? this.isManager,
    );
  }
}
