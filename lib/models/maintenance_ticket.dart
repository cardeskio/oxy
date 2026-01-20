enum TicketPriority { low, medium, high }
enum TicketStatus { new_, assigned, inProgress, done, approved, rejected }

class MaintenanceCost {
  final String id;
  final String orgId;
  final String ticketId;
  final String item;
  final double amount;
  final String? notes;

  MaintenanceCost({
    required this.id,
    required this.orgId,
    required this.ticketId,
    required this.item,
    required this.amount,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'ticket_id': ticketId,
    'item': item,
    'amount': amount,
    'notes': notes,
  };

  factory MaintenanceCost.fromJson(Map<String, dynamic> json) => MaintenanceCost(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    ticketId: json['ticket_id'] as String? ?? json['ticketId'] as String,
    item: json['item'] as String,
    amount: (json['amount'] as num).toDouble(),
    notes: json['notes'] as String?,
  );
}

class MaintenanceTicket {
  final String id;
  final String orgId;
  final String propertyId;
  final String unitId;
  final String? tenantId;
  final String? leaseId;
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedToUserId;
  final String? vendorId;
  final String? vendorName;
  final DateTime? resolvedAt;
  final List<MaintenanceCost> costs;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceTicket({
    required this.id,
    required this.orgId,
    required this.propertyId,
    required this.unitId,
    this.tenantId,
    this.leaseId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedToUserId,
    this.vendorId,
    this.vendorName,
    this.resolvedAt,
    required this.costs,
    required this.createdAt,
    required this.updatedAt,
  });

  MaintenanceTicket copyWith({
    String? id,
    String? orgId,
    String? propertyId,
    String? unitId,
    String? tenantId,
    String? leaseId,
    String? title,
    String? description,
    TicketPriority? priority,
    TicketStatus? status,
    String? assignedToUserId,
    String? vendorId,
    String? vendorName,
    DateTime? resolvedAt,
    List<MaintenanceCost>? costs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MaintenanceTicket(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    propertyId: propertyId ?? this.propertyId,
    unitId: unitId ?? this.unitId,
    tenantId: tenantId ?? this.tenantId,
    leaseId: leaseId ?? this.leaseId,
    title: title ?? this.title,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    assignedToUserId: assignedToUserId ?? this.assignedToUserId,
    vendorId: vendorId ?? this.vendorId,
    vendorName: vendorName ?? this.vendorName,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    costs: costs ?? this.costs,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'property_id': propertyId,
    'unit_id': unitId,
    'tenant_id': tenantId,
    'lease_id': leaseId,
    'title': title,
    'description': description,
    'priority': priority.name,
    'status': status == TicketStatus.new_ ? 'new' : (status == TicketStatus.inProgress ? 'inProgress' : status.name),
    'assigned_to_user_id': assignedToUserId,
    'vendor_id': vendorId,
    'vendor_name': vendorName,
    'resolved_at': resolvedAt?.toIso8601String(),
    'costs': costs.map((c) => c.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory MaintenanceTicket.fromJson(Map<String, dynamic> json) => MaintenanceTicket(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    propertyId: json['property_id'] as String? ?? json['propertyId'] as String,
    unitId: json['unit_id'] as String? ?? json['unitId'] as String,
    tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String?,
    leaseId: json['lease_id'] as String? ?? json['leaseId'] as String?,
    title: json['title'] as String,
    description: json['description'] as String,
    priority: TicketPriority.values.firstWhere((e) => e.name == json['priority']),
    status: json['status'] == 'new' 
        ? TicketStatus.new_ 
        : TicketStatus.values.firstWhere((e) => e.name == json['status']),
    assignedToUserId: json['assigned_to_user_id'] as String? ?? json['assignedToUserId'] as String?,
    vendorId: json['vendor_id'] as String? ?? json['vendorId'] as String?,
    vendorName: json['vendor_name'] as String? ?? json['vendorName'] as String?,
    resolvedAt: (json['resolved_at'] ?? json['resolvedAt']) != null 
        ? DateTime.parse(json['resolved_at'] as String? ?? json['resolvedAt'] as String) 
        : null,
    costs: (json['costs'] as List?)?.map((c) => MaintenanceCost.fromJson(c)).toList() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
  );

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.low: return 'Low';
      case TicketPriority.medium: return 'Medium';
      case TicketPriority.high: return 'High';
    }
  }

  String get statusLabel {
    switch (status) {
      case TicketStatus.new_: return 'New';
      case TicketStatus.assigned: return 'Assigned';
      case TicketStatus.inProgress: return 'In Progress';
      case TicketStatus.done: return 'Done';
      case TicketStatus.approved: return 'Approved';
      case TicketStatus.rejected: return 'Rejected';
    }
  }

  double get totalCost => costs.fold(0, (sum, c) => sum + c.amount);
}
