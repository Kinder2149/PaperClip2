import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'env_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static final FirebaseOptions web = FirebaseOptions(
    apiKey: EnvConfig.firebaseWebApiKey,
    appId: EnvConfig.firebaseWebAppId,
    messagingSenderId: '426827215567',
    projectId: EnvConfig.firebaseWebProjectId,
    authDomain: EnvConfig.firebaseWebAuthDomain,
    databaseURL: EnvConfig.firebaseWebDatabaseUrl,
    storageBucket: EnvConfig.firebaseWebStorageBucket,
  );

  static final FirebaseOptions android = FirebaseOptions(
    apiKey: EnvConfig.firebaseAndroidApiKey,
    appId: EnvConfig.firebaseAndroidAppId,
    messagingSenderId: '426827215567',
    projectId: 'paperclip2-2149',
    databaseURL: 'https://paperclip2-2149-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'paperclip2-2149.firebasestorage.app',
  );

  static final FirebaseOptions ios = FirebaseOptions(
    apiKey: EnvConfig.firebaseIosApiKey,
    appId: EnvConfig.firebaseIosAppId,
    messagingSenderId: '426827215567',
    projectId: 'paperclip2-2149',
    databaseURL: 'https://paperclip2-2149-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'paperclip2-2149.firebasestorage.app',
    iosBundleId: 'com.example.paperclip2',
  );
}