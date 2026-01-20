/// Document entity type
enum DocumentEntityType { lease, tenant, ticket, invoice, payment, property, unit }

extension DocumentEntityTypeExtension on DocumentEntityType {
  String get value => name;
  
  static DocumentEntityType fromString(String value) {
    return DocumentEntityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentEntityType.lease,
    );
  }
}

/// Document model for file storage metadata
class Document {
  final String id;
  final String orgId;
  final DocumentEntityType entityType;
  final String entityId;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final String? uploadedBy;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.orgId,
    required this.entityType,
    required this.entityId,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    this.uploadedBy,
    required this.createdAt,
  });

  Document copyWith({
    String? id,
    String? orgId,
    DocumentEntityType? entityType,
    String? entityId,
    String? storagePath,
    String? fileName,
    String? mimeType,
    String? uploadedBy,
    DateTime? createdAt,
  }) => Document(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    storagePath: storagePath ?? this.storagePath,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    uploadedBy: uploadedBy ?? this.uploadedBy,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'entity_type': entityType.value,
    'entity_id': entityId,
    'storage_path': storagePath,
    'file_name': fileName,
    'mime_type': mimeType,
    'uploaded_by': uploadedBy,
    'created_at': createdAt.toIso8601String(),
  };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String,
    entityType: DocumentEntityTypeExtension.fromString(
      json['entity_type'] as String? ?? json['entityType'] as String,
    ),
    entityId: json['entity_id'] as String? ?? json['entityId'] as String,
    storagePath: json['storage_path'] as String? ?? json['storagePath'] as String,
    fileName: json['file_name'] as String? ?? json['fileName'] as String,
    mimeType: json['mime_type'] as String? ?? json['mimeType'] as String,
    uploadedBy: json['uploaded_by'] as String? ?? json['uploadedBy'] as String?,
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String) 
        : DateTime.now(),
  );

  /// Check if document is an image
  bool get isImage => mimeType.startsWith('image/');
  
  /// Check if document is a PDF
  bool get isPdf => mimeType == 'application/pdf';
  
  /// Get file extension from filename
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
