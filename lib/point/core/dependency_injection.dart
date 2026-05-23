// lib/core/services/dependency_injection.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../auth/controllers/user_controller.dart';
import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../services/base_service.dart';
import '../../services/mjengo_service.dart';
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
      print('🔐 Initializing MjengoAuthController...');
      Get.put(MjengoAuthController(), permanent: true);
      print('✅ MjengoAuthController initialized');
    } catch (e) {
      print('❌ MjengoAuthController failed: $e');
    }

    try {
      print('👤 Initializing UserController...');
      Get.put(UserController(), permanent: true);
      print('✅ UserController initialized');
    } catch (e) {
      print('❌ UserController failed: $e');
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
          Get.isRegistered<UserController>();
    } catch (e) {
      print('❌ Error checking dependencies: $e');
      return false;
    }
  }
}
