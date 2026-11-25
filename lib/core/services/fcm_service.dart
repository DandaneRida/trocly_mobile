import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../controllers/notifications_controller.dart';

/// Service FCM non-bloquant (100% gratuit via Firebase Cloud Messaging V1)
/// S'initialise automatiquement sur Android/iOS lorsque google-services.json est présent.
class FcmService {
  static bool _initialized = false;

  static Future<void> initAndSyncToken() async {
    if (kIsWeb) return;
    try {
      if (!_initialized) {
        await Firebase.initializeApp();
        _initialized = true;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null &&
          token.isNotEmpty &&
          Get.isRegistered<NotificationsController>()) {
        final platform = Platform.isIOS ? 'ios' : 'android';
        await Get.find<NotificationsController>()
            .registerDeviceToken(token, platform: platform);
      }

      messaging.onTokenRefresh.listen((newToken) {
        if (Get.isRegistered<NotificationsController>()) {
          final platform = Platform.isIOS ? 'ios' : 'android';
          Get.find<NotificationsController>()
              .registerDeviceToken(newToken, platform: platform);
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        final notif = msg.notification;
        if (notif != null && (notif.title != null || notif.body != null)) {
          Get.snackbar(
            notif.title ?? 'Trocly',
            notif.body ?? '',
          );
          if (Get.isRegistered<NotificationsController>()) {
            Get.find<NotificationsController>().fetchUnreadCount();
          }
        }
      });
    } catch (e) {
      debugPrint('FCM init skipped or unavailable: $e');
    }
  }
}
