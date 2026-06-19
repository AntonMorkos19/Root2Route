import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages the local notification channel and foreground display.
///
/// **Why this is critical for background notifications:**
/// On Android 8+ (API 26), every notification MUST be posted to a
/// notification channel. If the channel doesn't exist on the device,
/// the system silently drops the notification. Firebase Messaging
/// uses the channel ID sent in the FCM payload (e.g. "root2route_default"),
/// so we MUST create that exact channel before any notification arrives.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService _instance =
      LocalNotificationService._();
  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// The channel ID — MUST match what the backend sends in
  /// `android.notification.channel_id`.
  static const String _channelId = 'root2route_default';
  static const String _channelName = 'Root2Route Notifications';
  static const String _channelDescription =
      'إشعارات تطبيق Root2Route للطلبات والمنتجات والمزادات';

  bool _initialized = false;

  /// Call once in `main()` AFTER `Firebase.initializeApp()`.
  Future<void> init() async {
    if (_initialized) return;

    // ── 1. Android channel ──────────────────────────────────────────────
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create the channel on the device. Safe to call multiple times.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ── 2. Initialise the plugin ────────────────────────────────────────
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('[LocalNotification] ✅ Initialized — channel "$_channelId" created');
  }

  /// Show a local notification when a message arrives in the FOREGROUND.
  /// In background/killed states the OS handles display automatically
  /// (because the channel now exists).
  void showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;

    _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          showWhen: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Called when user taps a local notification (foreground-shown ones).
  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
      '[LocalNotification] Tapped notification — payload: ${response.payload}',
    );
    // TODO: Add deep-link / routing logic here if needed.
  }
}
