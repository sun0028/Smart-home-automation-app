import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    } else if (Platform.isMacOS) {
      return macos;
    } else if (Platform.isWindows) {
      return windows;
    } else if (Platform.isLinux) {
      return linux;
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "YOUR_ANDROID_API_KEY",
    appId: "YOUR_ANDROID_APP_ID",
    messagingSenderId: "YOUR_ANDROID_MESSAGING_SENDER_ID",
    projectId: "iot-sha-760c8",
    storageBucket: "YOUR_STORAGE_BUCKET",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "YOUR_IOS_MESSAGING_SENDER_ID",
    projectId: "iot-sha-760c8",
    storageBucket: "YOUR_STORAGE_BUCKET",
    iosBundleId: "YOUR_IOS_BUNDLE_ID",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "YOUR_MACOS_API_KEY",
    appId: "YOUR_MACOS_APP_ID",
    messagingSenderId: "YOUR_MACOS_MESSAGING_SENDER_ID",
    projectId: "iot-sha-760c8",
    storageBucket: "YOUR_STORAGE_BUCKET",
    iosBundleId: "YOUR_MACOS_BUNDLE_ID",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "YOUR_WINDOWS_API_KEY",
    appId: "YOUR_WINDOWS_APP_ID",
    messagingSenderId: "YOUR_WINDOWS_MESSAGING_SENDER_ID",
    projectId: "iot-sha-760c8",
    storageBucket: "YOUR_STORAGE_BUCKET",
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: "YOUR_LINUX_API_KEY",
    appId: "YOUR_LINUX_APP_ID",
    messagingSenderId: "YOUR_LINUX_MESSAGING_SENDER_ID",
    projectId: "iot-sha-760c8",
    storageBucket: "YOUR_STORAGE_BUCKET",
  );
}
