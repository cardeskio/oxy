/// Notification types
enum NotificationType {
  // Manager notifications
  newTicket,
  ticketMessage,
  newEnquiry,
  enquiryMessage,
  paymentReceived,
  leaseExpiring,

  // Tenant notifications
  invoiceCreated,
  ticketUpdated,
  ticketReply,
  enquiryUpdated,
  enquiryReply,
  leaseReminder,
  
  // Provider notifications
  orderNew,
  orderUpdate,
}

extension NotificationTypeExtension on NotificationType {
  String get dbValue {
    switch (this) {
      case NotificationType.newTicket:
        return 'new_ticket';
      case NotificationType.ticketMessage:
        return 'ticket_message';
      case NotificationType.newEnquiry:
        return 'new_enquiry';
      case NotificationType.enquiryMessage:
        return 'enquiry_message';
      case NotificationType.paymentReceived:
        return 'payment_received';
      case NotificationType.leaseExpiring:
        return 'lease_expiring';
      case NotificationType.invoiceCreated:
        return 'invoice_created';
      case NotificationType.ticketUpdated:
        return 'ticket_updated';
      case NotificationType.ticketReply:
        return 'ticket_reply';
      case NotificationType.enquiryUpdated:
        return 'enquiry_updated';
      case NotificationType.enquiryReply:
        return 'enquiry_reply';
      case NotificationType.leaseReminder:
        return 'lease_reminder';
      case NotificationType.orderNew:
        return 'order_new';
      case NotificationType.orderUpdate:
        return 'order_update';
    }
  }

  static NotificationType fromDbValue(String value) {
    switch (value) {
      case 'new_ticket':
        return NotificationType.newTicket;
      case 'ticket_message':
        return NotificationType.ticketMessage;
      case 'new_enquiry':
        return NotificationType.newEnquiry;
      case 'enquiry_message':
        return NotificationType.enquiryMessage;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'lease_expiring':
        return NotificationType.leaseExpiring;
      case 'invoice_created':
        return NotificationType.invoiceCreated;
      case 'ticket_updated':
        return NotificationType.ticketUpdated;
      case 'ticket_reply':
        return NotificationType.ticketReply;
      case 'enquiry_updated':
        return NotificationType.enquiryUpdated;
      case 'enquiry_reply':
        return NotificationType.enquiryReply;
      case 'lease_reminder':
        return NotificationType.leaseReminder;
      case 'order_new':
        return NotificationType.orderNew;
      case 'order_update':
        return NotificationType.orderUpdate;
      default:
        return NotificationType.newTicket; // Default fallback
    }
  }

  /// Returns the route to navigate to when notification is tapped
  String? getNavigationRoute(Map<String, dynamic> data) {
    switch (this) {
      case NotificationType.newTicket:
      case NotificationType.ticketMessage:
        final ticketId = data['ticket_id'];
        return ticketId != null ? '/maintenance/$ticketId' : '/maintenance';

      case NotificationType.ticketUpdated:
      case NotificationType.ticketReply:
        final ticketId = data['ticket_id'];
        return ticketId != null ? '/tenant/maintenance/$ticketId' : '/tenant/maintenance';

      case NotificationType.newEnquiry:
      case NotificationType.enquiryMessage:
        return '/enquiries';

      case NotificationType.enquiryUpdated:
      case NotificationType.enquiryReply:
        return '/tenant/enquiries';

      case NotificationType.paymentReceived:
        return '/payments';

      case NotificationType.invoiceCreated:
        return '/tenant/invoices';

      case NotificationType.leaseExpiring:
        final tenantId = data['tenant_id'];
        return tenantId != null ? '/tenants/$tenantId' : '/tenants';

      case NotificationType.leaseReminder:
        return '/tenant/lease';
        
      case NotificationType.orderNew:
        // Provider receives new order notification
        return '/provider/orders';
        
      case NotificationType.orderUpdate:
        // Customer receives order status update
        return '/tenant/orders';
    }
  }

  /// Whether this notification type is for managers
  bool get isManagerNotification {
    switch (this) {
      case NotificationType.newTicket:
      case NotificationType.ticketMessage:
      case NotificationType.newEnquiry:
      case NotificationType.enquiryMessage:
      case NotificationType.paymentReceived:
      case NotificationType.leaseExpiring:
        return true;
      default:
        return false;
    }
  }
}

/// App notification model
class AppNotification {
  final String id;
  final String userId;
  final String? orgId;
  final NotificationType type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.orgId,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orgId: json['org_id'] as String?,
      type: NotificationTypeExtension.fromDbValue(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String?,
      data: json['data'] != null 
          ? Map<String, dynamic>.from(json['data'] as Map) 
          : {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'org_id': orgId,
    'type': type.dbValue,
    'title': title,
    'body': body,
    'data': data,
    'is_read': isRead,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  AppNotification copyWith({
    String? id,
    String? userId,
    String? orgId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orgId: orgId ?? this.orgId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the navigation route for this notification
  String? get navigationRoute => type.getNavigationRoute(data);
}
