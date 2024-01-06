import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/utils.dart';
import 'firebase_service.dart';

const androidChannel = AndroidNotificationChannel(CHANNEL_ID, CHANNEL_NAME,
    description: CHANNEL_DESC, importance: Importance.defaultImportance);
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> handleMessage(RemoteMessage? message) async {
  if (message == null) return;
  final notification = message.notification;
  final data = message.data;
  final title = notification?.title;
  final body = notification?.body;
  //navigatorKey.currentState?.push(MaterialPageRoute(builder: ((context) => )));
}

Future<void> handleResponse(NotificationResponse response) async {
  if (response.payload == null) return;
  final message = RemoteMessage.fromMap(jsonDecode(response.payload!));
  handleMessage(message);
}

Future initLocalNotification() async {
  const iOS = DarwinInitializationSettings();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android, iOS: iOS);
  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: handleResponse,
    onDidReceiveBackgroundNotificationResponse: handleResponse,
  );
  final platform =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await platform?.createNotificationChannel(androidChannel);
}

Future initPushNotification() async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true);
  FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  FirebaseMessaging.onBackgroundMessage(handleMessage);
  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification == null) return;
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          icon: '@mipmap/ic_launcher',
          // importance: Importance.max,
          // priority: Priority.max,
          playSound: true,
        ),
      ),
      payload: jsonEncode(message.toMap()),
    );
  });
}

class FirebaseNotification {
  final messaging = FirebaseMessaging.instance;
  FirebaseService fs = FirebaseService();

  Future<void> initNotification() async {
    await messaging.requestPermission();
    String? token;
    if (kIsWeb) {
      final key = await fs.getPrivateKey();
      if (key == null) return;
      String vapidKey = key.vapidKey;
      token = await messaging.getToken(vapidKey: vapidKey);
    } else {
      token = await messaging.getToken();
    }
    if (token != null) {
      fs.updateToken(token);
    }
    messaging.onTokenRefresh.listen((token) {
      fs.updateToken(token);
    });
    initPushNotification();
    initLocalNotification();
  }
}
