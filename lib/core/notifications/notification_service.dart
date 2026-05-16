import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  const NotificationService._();

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.setAutoInitEnabled(true);
    await messaging.getToken();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
