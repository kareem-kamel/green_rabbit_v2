import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../presentation/cubit/notification_cubit.dart';
import '../../../market/presentation/pages/instrument_detail_page.dart';
import '../../../../main.dart'; // for globalNavigatorKey

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(NotificationCubit notificationCubit) async {
    try {
      // 1. Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 2. Fetch and register the FCM token
        String? token = await _firebaseMessaging.getToken();
        final deviceId = await _getOrCreateDeviceId();
        if (token != null) {
          final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
          await notificationCubit.registerFcmToken(
            fcmToken: token,
            deviceType: platform,
            deviceId: deviceId,
          );
        }

        // 3. Listen to token refreshes
        _firebaseMessaging.onTokenRefresh.listen((token) async {
          final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
          final refreshedDeviceId = await _getOrCreateDeviceId();
          notificationCubit.registerFcmToken(
            fcmToken: token,
            deviceType: platform,
            deviceId: refreshedDeviceId,
          );
        });

        // 4. Initialize local notifications for foreground head-up displays
        const AndroidInitializationSettings androidInitSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosInitSettings =
            DarwinInitializationSettings();
        const InitializationSettings initSettings = InitializationSettings(
          android: androidInitSettings,
          iOS: iosInitSettings,
        );

        await _localNotifications.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) {
              _handleDeepLink(payload);
            }
          },
        );

        // Create android notification channel for heads-up display
        if (Platform.isAndroid) {
          await _localNotifications
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(
                const AndroidNotificationChannel(
                  'high_importance_channel',
                  'High Importance Notifications',
                  description: 'Used for important price and alert notifications.',
                  importance: Importance.max,
                ),
              );
        }

        // 5. Handle foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          // Force fetch unread count to sync application badges
          notificationCubit.fetchUnreadCount();

          RemoteNotification? notification = message.notification;
          if (notification != null) {
            final data = message.data;
            final instrumentId = data['instrumentId']?.toString() ?? data['instrument_id']?.toString();
            
            _localNotifications.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              payload: instrumentId,
            );
          }
        });

        // 6. Handle notification click in background state
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final instrumentId = message.data['instrumentId']?.toString() ?? message.data['instrument_id']?.toString();
          if (instrumentId != null && instrumentId.isNotEmpty) {
            _handleDeepLink(instrumentId);
          }
        });

        // 7. Handle notification click in terminated state
        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          final instrumentId = initialMessage.data['instrumentId']?.toString() ?? initialMessage.data['instrument_id']?.toString();
          if (instrumentId != null && instrumentId.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _handleDeepLink(instrumentId);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }
  }

  static void _handleDeepLink(String instrumentId) {
    final context = globalNavigatorKey.currentContext;
    if (context != null && instrumentId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InstrumentDetailPage(instrumentId: instrumentId),
        ),
      );
    }
  }

  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: Random().nextInt(100000),
      title: 'Meyka Alert Triggered! 🚀',
      body: 'Your price alert for Apple Inc. has been reached at \$196.45',
      notificationDetails: details,
      payload: 'stock:AAPL',
    );
  }

  static Future<String> _getOrCreateDeviceId() async {
    const storage = FlutterSecureStorage();
    String? deviceId = await storage.read(key: 'device_id');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateUUIDv4();
      await storage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }

  static String _generateUUIDv4() {
    final random = Random.secure();
    final hexDigits = '0123456789abcdef';
    final charCodes = List<int>.generate(36, (index) {
      if (index == 8 || index == 13 || index == 18 || index == 23) {
        return 45; // '-'
      }
      if (index == 14) {
        return 52; // '4'
      }
      final randomVal = random.nextInt(16);
      if (index == 19) {
        return hexDigits.codeUnitAt((randomVal & 0x3) | 0x8);
      }
      return hexDigits.codeUnitAt(randomVal);
    });
    return String.fromCharCodes(charCodes);
  }
}
