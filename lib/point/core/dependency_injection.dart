// lib/core/services/dependency_injection.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../services/base_service.dart';
import '../../services/mjengo_service.dart';
import '../../news/controllers/home_news_controller.dart';
import '../../news/controllers/discover_controller.dart';
import '../../videos/controllers/videos_controller.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../shared/theme/theme_controller.dart';
import '../../shared/services/deep_link_service.dart';
import 'firebase_initializer.dart';


class DependencyInjection {
  static Future<void> init() async {
    print('🚀 Starting dependency injection...');

    try {
      print('🔧 Initializing BaseService...');
      Get.put(BaseService(), permanent: true);
      print('✅ BaseService initialized');
    } catch (e) {
      print('❌ BaseService failed: $e');
    }

    try {
      print('🌐 Initializing MjengoService...');
      Get.put(MjengoService(), permanent: true);
      print('✅ MjengoService initialized');
    } catch (e) {
      print('❌ MjengoService failed: $e');
    }

    try {
      print('🎨 Initializing ThemeController...');
      Get.put(ThemeController(), permanent: true);
      print('✅ ThemeController initialized');
    } catch (e) {
      print('❌ ThemeController failed: $e');
    }

    try {
      print('🔐 Initializing MjengoAuthController...');
      Get.put(MjengoAuthController(), permanent: true);
      print('✅ MjengoAuthController initialized');
    } catch (e) {
      print('❌ MjengoAuthController failed: $e');
    }

    try {
      print('📰 Initializing HomeNewsController...');
      Get.put(HomeNewsController(), permanent: true);
      print('✅ HomeNewsController initialized');
    } catch (e) {
      print('❌ HomeNewsController failed: $e');
    }

    try {
      print('🔍 Initializing DiscoverController...');
      Get.put(DiscoverController(), permanent: true);
      print('✅ DiscoverController initialized');
    } catch (e) {
      print('❌ DiscoverController failed: $e');
    }

    try {
      print('🎬 Initializing VideosController...');
      Get.put(VideosController(), permanent: true);
      print('✅ VideosController initialized');
    } catch (e) {
      print('❌ VideosController failed: $e');
    }

    try {
      print('🔔 Initializing NotificationsController...');
      Get.put(NotificationsController(), permanent: true);
      print('✅ NotificationsController initialized');
    } catch (e) {
      print('❌ NotificationsController failed: $e');
    }

    if (!kIsWeb) {
      try {
        print('🔔 Initializing FCM...');
        await FirebaseInitializer.initNotifications();
        print('✅ FCM initialized');
      } catch (e) {
        print('❌ FCM initialization failed: $e');
      }
    }

    if (!kIsWeb) {
      try {
        print('🔗 Initializing DeepLinkService...');
        final deepLinks = DeepLinkService();
        Get.put(deepLinks, permanent: true);
        await deepLinks.init();
        print('✅ DeepLinkService initialized');
      } catch (e) {
        print('❌ DeepLinkService failed: $e');
      }
    }

    print('✅ Dependency injection complete');
  }

  static void clearAll() {
    try {
      Get.deleteAll(force: true);
      print('🗑️ All dependencies cleared');
    } catch (e) {
      print('❌ Error clearing dependencies: $e');
    }
  }

  static Future<void> reset<T>() async {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>(force: true);
        print('🔄 ${T.toString()} dependency reset');
      }
    } catch (e) {
      print('❌ Error resetting ${T.toString()}: $e');
    }
  }

  static bool areAllDependenciesReady() {
    try {
      return Get.isRegistered<BaseService>() &&
          Get.isRegistered<HomeNewsController>() &&
          Get.isRegistered<DiscoverController>();
    } catch (e) {
      print('❌ Error checking dependencies: $e');
      return false;
    }
  }
}
