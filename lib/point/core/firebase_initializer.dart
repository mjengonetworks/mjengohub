import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';

import '../../firebase_options.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../notifications/services/notifications_service.dart';
import '../../shared/widgets/push_preference_prompt.dart';

/// Runs in a separate isolate for background/terminated-state messages —
/// must stay a top-level function per firebase_messaging's contract.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FirebaseInitializer {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // On web (including incognito), switch to SESSION persistence so Firebase
    // uses sessionStorage instead of IndexedDB/localStorage. IndexedDB is
    // blocked or unavailable in incognito, which causes the app to hang.
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
    }
  }

  /// Requests notification permission, registers the FCM device token with
  /// the backend, and shows a one-time "customize your notifications" prompt
  /// the first time permission is granted this app install. Mobile-only
  /// (guarded by `!kIsWeb` at the call site in DependencyInjection) — web
  /// push would need a VAPID key + service worker this app doesn't ship yet.
  static Future<void> initNotifications() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) return;

    final token = await messaging.getToken();
    if (token != null) {
      await NotificationsService().registerDeviceToken(
        token,
        platform: _platformLabel,
      );
    }
    messaging.onTokenRefresh.listen((newToken) {
      NotificationsService().registerDeviceToken(
        newToken,
        platform: _platformLabel,
      );
    });

    // Foreground messages just refresh the bell badge — the OS already
    // surfaces the banner on Android/iOS backgrounded delivery.
    FirebaseMessaging.onMessage.listen((_) {
      try {
        Get.find<NotificationsController>().refreshUnreadCount();
      } catch (_) {}
    });

    PushPreferencePrompt.maybeShowAfterGrant();
  }

  static String get _platformLabel {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }
}
