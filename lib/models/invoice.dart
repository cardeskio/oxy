enum InvoiceStatus { open, paid, void_ }

extension InvoiceStatusExtension on InvoiceStatus {
  String get statusLabel {
    switch (this) {
      case InvoiceStatus.open:
        return 'Open';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.void_:
        return 'Void';
    }
  }
}

class InvoiceLine {
  final String id;
  final String orgId;
  final String invoiceId;
  final String? chargeTypeId;
  final String chargeType;
  final String description;
  final double amount;
  final double balanceAmount;

  InvoiceLine({
    required this.id,
    required this.orgId,
    required this.invoiceId,
    this.chargeTypeId,
    required this.chargeType,
    required this.description,
    required this.amount,
    required this.balanceAmount,
  });

  InvoiceLine copyWith({
    String? id,
    String? orgId,
    String? invoiceId,
    String? chargeTypeId,
    String? chargeType,
    String? description,
    double? amount,
    double? balanceAmount,
  }) => InvoiceLine(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    invoiceId: invoiceId ?? this.invoiceId,
    chargeTypeId: chargeTypeId ?? this.chargeTypeId,
    chargeType: chargeType ?? this.chargeType,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    balanceAmount: balanceAmount ?? this.balanceAmount,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'invoice_id': invoiceId,
    'charge_type_id': chargeTypeId,
    'charge_type': chargeType,
    'description': description,
    'amount': amount,
    'balance_amount': balanceAmount,
  };

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => InvoiceLine(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    invoiceId: json['invoice_id'] as String? ?? json['invoiceId'] as String,
    chargeTypeId: json['charge_type_id'] as String? ?? json['chargeTypeId'] as String?,
    chargeType: json['charge_type'] as String? ?? json['chargeType'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
    balanceAmount: (json['balance_amount'] as num? ?? json['balanceAmount'] as num).toDouble(),
  );
}

class Invoice {
  final String id;
  final String orgId;
  final String leaseId;
  final String tenantId;
  final String unitId;
  final String propertyId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dueDate;
  final InvoiceStatus status;
  final double totalAmount;
  final double balanceAmount;
  final List<InvoiceLine> lines;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.orgId,
    required this.leaseId,
    required this.tenantId,
    required this.unitId,
    required this.propertyId,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    required this.status,
    required this.totalAmount,
    required this.balanceAmount,
    required this.lines,
    required this.createdAt,
    required this.updatedAt,
  });

  Invoice copyWith({
    String? id,
    String? orgId,
    String? leaseId,
    String? tenantId,
    String? unitId,
    String? propertyId,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? dueDate,
    InvoiceStatus? status,
    double? totalAmount,
    double? balanceAmount,
    List<InvoiceLine>? lines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Invoice(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    leaseId: leaseId ?? this.leaseId,
    tenantId: tenantId ?? this.tenantId,
    unitId: unitId ?? this.unitId,
    propertyId: propertyId ?? this.propertyId,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    totalAmount: totalAmount ?? this.totalAmount,
    balanceAmount: balanceAmount ?? this.balanceAmount,
    lines: lines ?? this.lines,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'lease_id': leaseId,
    'tenant_id': tenantId,
    'unit_id': unitId,
    'property_id': propertyId,
    'period_start': periodStart.toIso8601String(),
    'period_end': periodEnd.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'status': status == InvoiceStatus.void_ ? 'void' : status.name,
    'total_amount': totalAmount,
    'balance_amount': balanceAmount,
    'lines': lines.map((l) => l.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    leaseId: json['lease_id'] as String? ?? json['leaseId'] as String,
    tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String,
    unitId: json['unit_id'] as String? ?? json['unitId'] as String,
    propertyId: json['property_id'] as String? ?? json['propertyId'] as String,
    periodStart: DateTime.parse(json['period_start'] as String? ?? json['periodStart'] as String),
    periodEnd: DateTime.parse(json['period_end'] as String? ?? json['periodEnd'] as String),
    dueDate: DateTime.parse(json['due_date'] as String? ?? json['dueDate'] as String),
    status: json['status'] == 'void' 
        ? InvoiceStatus.void_ 
        : InvoiceStatus.values.firstWhere((e) => e.name == json['status']),
    totalAmount: (json['total_amount'] as num? ?? json['totalAmount'] as num).toDouble(),
    balanceAmount: (json['balance_amount'] as num? ?? json['balanceAmount'] as num).toDouble(),
    lines: (json['lines'] as List?)?.map((l) => InvoiceLine.fromJson(l)).toList() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
  );

  String get statusLabel {
    switch (status) {
      case InvoiceStatus.open: return 'Open';
      case InvoiceStatus.paid: return 'Paid';
      case InvoiceStatus.void_: return 'Void';
    }
  }

  bool get isOverdue => status == InvoiceStatus.open && DateTime.now().isAfter(dueDate);
  
  String get periodLabel {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[periodStart.month - 1]} ${periodStart.year}';
  }
}
