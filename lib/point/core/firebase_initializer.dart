import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../firebase_options.dart';

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

  static Future<void> initNotifications() async {}
}
