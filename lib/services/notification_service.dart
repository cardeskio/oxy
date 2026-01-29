import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oxy/models/notification.dart';
import 'package:oxy/supabase/supabase_config.dart';
import 'package:oxy/services/auth_service.dart';

/// Service for managing user notifications with real-time updates
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AuthService _authService = AuthService();
  RealtimeChannel? _notificationChannel;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  bool get hasUnread => unreadCount > 0;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        _isInitialized = true;
        return;
      }

      await _loadNotifications();
      _setupRealtimeSubscription();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load notifications from database
  Future<void> _loadNotifications() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final data = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      _notifications = data.map((n) => AppNotification.fromJson(n)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  /// Set up real-time subscription for new notifications
  void _setupRealtimeSubscription() {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    _notificationChannel?.unsubscribe();
    
    _notificationChannel = SupabaseConfig.client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleNewNotification(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleNotificationUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleNotificationDelete(payload.oldRecord);
          },
        )
        .subscribe();
  }

  /// Handle new notification from real-time
  void _handleNewNotification(Map<String, dynamic> record) {
    try {
      final notification = AppNotification.fromJson(record);
      
      // Avoid duplicates
      if (!_notifications.any((n) => n.id == notification.id)) {
        _notifications.insert(0, notification);
        notifyListeners();
        debugPrint('New notification received: ${notification.title}');
      }
    } catch (e) {
      debugPrint('Error handling new notification: $e');
    }
  }

  /// Handle notification update from real-time
  void _handleNotificationUpdate(Map<String, dynamic> record) {
    try {
      final updated = AppNotification.fromJson(record);
      final index = _notifications.indexWhere((n) => n.id == updated.id);
      
      if (index != -1) {
        _notifications[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling notification update: $e');
    }
  }

  /// Handle notification deletion from real-time
  void _handleNotificationDelete(Map<String, dynamic> record) {
    try {
      final id = record['id'] as String?;
      if (id != null) {
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling notification delete: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      // Update local state immediately
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      await SupabaseConfig.client
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// Refresh notifications from database
  Future<void> refresh() async {
    await _loadNotifications();
  }

  /// Clean up subscriptions
  void _removeRealtimeSubscription() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  /// Clear all data and subscriptions
  void clear() {
    _removeRealtimeSubscription();
    _notifications.clear();
    _isInitialized = false;
    notifyListeners();
  }
}
