// File generated from GoogleService-Info.plist and google-services.json
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── iOS ─────────────────────────────────────────────────────────────────────
  // Source: ios/Runner/GoogleService-Info.plist  +  google-services.json iOS entry
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvhi7szj043aARzm5jBstCFiPQEHmCzcQ',
    appId: '1:963276687646:ios:01421143114f6ff6c4210f',
    messagingSenderId: '963276687646',
    projectId: 'greenrabbit-app',
    storageBucket: 'greenrabbit-app.firebasestorage.app',
    iosBundleId: 'com.greenrabbit.ai',
    // iOS OAuth 2.0 client  (client_type 2 in google-services.json)
    iosClientId:
        '963276687646-g6htuquf3okdg29auu9qe0cj2uhefpt7.apps.googleusercontent.com',
  );

  // ── macOS ────────────────────────────────────────────────────────────────────
  // Reuses the iOS OAuth client; register a separate macOS app in Firebase if needed.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBvhi7szj043aARzm5jBstCFiPQEHmCzcQ',
    appId: '1:963276687646:ios:01421143114f6ff6c4210f',
    messagingSenderId: '963276687646',
    projectId: 'greenrabbit-app',
    storageBucket: 'greenrabbit-app.firebasestorage.app',
    iosBundleId: 'com.greenrabbit.ai',
    iosClientId:
        '963276687646-g6htuquf3okdg29auu9qe0cj2uhefpt7.apps.googleusercontent.com',
  );

  // ── Android ──────────────────────────────────────────────────────────────────
  // Source: android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-1VuT28Lvg8Q_kHsr3GhMiMLE_NOlmtc',
    appId: '1:963276687646:android:e7e9edc2db009610c4210f',
    messagingSenderId: '963276687646',
    projectId: 'greenrabbit-app',
    storageBucket: 'greenrabbit-app.firebasestorage.app',
  );
}
