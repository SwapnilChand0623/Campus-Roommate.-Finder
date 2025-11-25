import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling local push notifications
/// Sends notifications for matches, likes, and new messages
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to appropriate screen based on payload
    // For now, just log the action
    print('Notification tapped: ${response.payload}');
  }

  /// Send a notification for a new match
  Future<void> sendMatchNotification({
    required String matchName,
    required String matchId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'matches',
      'Matches',
      channelDescription: 'Notifications for new matches',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      matchId.hashCode,
      '🎉 New Match!',
      'You matched with $matchName! Start chatting now.',
      details,
      payload: 'match:$matchId',
    );
  }

  /// Send a notification for a new like/favorite
  Future<void> sendLikeNotification({
    required String likerName,
    required String likerId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'likes',
      'Likes',
      channelDescription: 'Notifications for new likes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      likerId.hashCode,
      '💜 Someone likes you!',
      '$likerName added you to their favorites.',
      details,
      payload: 'like:$likerId',
    );
  }

  /// Send a notification for a new message
  Future<void> sendMessageNotification({
    required String senderName,
    required String senderId,
    required String messagePreview,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      senderId.hashCode,
      '💬 $senderName',
      messagePreview,
      details,
      payload: 'message:$senderId',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Set up real-time listeners for notifications
  Future<void> setupRealtimeListeners(String currentUserId) async {
    final supabase = Supabase.instance.client;

    // Listen for new favorites (likes)
    supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('favorited_user_id', currentUserId)
        .listen((data) async {
          if (data.isEmpty) return;
          
          // Get the latest favorite
          final latest = data.last;
          final likerId = latest['user_id'] as String;
          
          // Fetch liker's profile
          final profile = await supabase
              .from('users')
              .select('full_name')
              .eq('id', likerId)
              .single();
          
          final likerName = profile['full_name'] as String;
          
          // Check if it's a mutual match
          final mutualMatch = await supabase
              .from('favorites')
              .select()
              .eq('user_id', currentUserId)
              .eq('favorited_user_id', likerId)
              .maybeSingle();
          
          if (mutualMatch != null) {
            // It's a match!
            await sendMatchNotification(
              matchName: likerName,
              matchId: likerId,
            );
          } else {
            // Just a like
            await sendLikeNotification(
              likerName: likerName,
              likerId: likerId,
            );
          }
        });

    // Listen for new messages
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUserId)
        .listen((data) async {
          if (data.isEmpty) return;
          
          // Get the latest message
          final latest = data.last;
          final senderId = latest['sender_id'] as String;
          final content = latest['content'] as String;
          
          // Fetch sender's profile
          final profile = await supabase
              .from('users')
              .select('full_name')
              .eq('id', senderId)
              .single();
          
          final senderName = profile['full_name'] as String;
          
          // Send notification
          await sendMessageNotification(
            senderName: senderName,
            senderId: senderId,
            messagePreview: content.length > 50 
                ? '${content.substring(0, 50)}...' 
                : content,
          );
        });
  }
}
