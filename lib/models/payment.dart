enum PaymentMethod { mpesa, cash, bank }
enum PaymentStatus { unallocated, partiallyAllocated, allocated }

class PaymentAllocation {
  final String id;
  final String orgId;
  final String paymentId;
  final String invoiceLineId;
  final String invoiceId;
  final double amountAllocated;

  PaymentAllocation({
    required this.id,
    required this.orgId,
    required this.paymentId,
    required this.invoiceLineId,
    required this.invoiceId,
    required this.amountAllocated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'payment_id': paymentId,
    'invoice_line_id': invoiceLineId,
    'invoice_id': invoiceId,
    'amount_allocated': amountAllocated,
  };

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) => PaymentAllocation(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    paymentId: json['payment_id'] as String? ?? json['paymentId'] as String,
    invoiceLineId: json['invoice_line_id'] as String? ?? json['invoiceLineId'] as String,
    invoiceId: json['invoice_id'] as String? ?? json['invoiceId'] as String,
    amountAllocated: (json['amount_allocated'] as num? ?? json['amountAllocated'] as num).toDouble(),
  );
}

class Payment {
  final String id;
  final String orgId;
  final String? tenantId;
  final String? leaseId;
  final String? unitId;
  final double amount;
  final PaymentMethod method;
  final String reference;
  final DateTime paidAt;
  final String capturedBy;
  final String? notes;
  final PaymentStatus status;
  final List<PaymentAllocation> allocations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.orgId,
    this.tenantId,
    this.leaseId,
    this.unitId,
    required this.amount,
    required this.method,
    required this.reference,
    required this.paidAt,
    required this.capturedBy,
    this.notes,
    required this.status,
    required this.allocations,
    required this.createdAt,
    required this.updatedAt,
  });

  Payment copyWith({
    String? id,
    String? orgId,
    String? tenantId,
    String? leaseId,
    String? unitId,
    double? amount,
    PaymentMethod? method,
    String? reference,
    DateTime? paidAt,
    String? capturedBy,
    String? notes,
    PaymentStatus? status,
    List<PaymentAllocation>? allocations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Payment(
    id: id ?? this.id,
    orgId: orgId ?? this.orgId,
    tenantId: tenantId ?? this.tenantId,
    leaseId: leaseId ?? this.leaseId,
    unitId: unitId ?? this.unitId,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    reference: reference ?? this.reference,
    paidAt: paidAt ?? this.paidAt,
    capturedBy: capturedBy ?? this.capturedBy,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    allocations: allocations ?? this.allocations,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'tenant_id': tenantId,
    'lease_id': leaseId,
    'unit_id': unitId,
    'amount': amount,
    'method': method.name,
    'reference': reference,
    'paid_at': paidAt.toIso8601String(),
    'captured_by': capturedBy,
    'notes': notes,
    'status': status.name,
    'allocations': allocations.map((a) => a.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    orgId: json['org_id'] as String? ?? json['orgId'] as String? ?? '',
    tenantId: json['tenant_id'] as String? ?? json['tenantId'] as String?,
    leaseId: json['lease_id'] as String? ?? json['leaseId'] as String?,
    unitId: json['unit_id'] as String? ?? json['unitId'] as String?,
    amount: (json['amount'] as num).toDouble(),
    method: PaymentMethod.values.firstWhere((e) => e.name == json['method']),
    reference: json['reference'] as String,
    paidAt: DateTime.parse(json['paid_at'] as String? ?? json['paidAt'] as String),
    capturedBy: json['captured_by'] as String? ?? json['capturedBy'] as String,
    notes: json['notes'] as String?,
    status: PaymentStatus.values.firstWhere((e) => e.name == json['status']),
    allocations: (json['allocations'] as List?)?.map((a) => PaymentAllocation.fromJson(a)).toList() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
  );

  String get methodLabel {
    switch (method) {
      case PaymentMethod.mpesa: return 'M-Pesa';
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.bank: return 'Bank Transfer';
    }
  }

  String get statusLabel {
    switch (status) {
      case PaymentStatus.unallocated: return 'Unallocated';
      case PaymentStatus.partiallyAllocated: return 'Partial';
      case PaymentStatus.allocated: return 'Allocated';
    }
  }

  double get allocatedAmount => allocations.fold(0, (sum, a) => sum + a.amountAllocated);
  double get unallocatedAmount => amount - allocatedAmount;
}
