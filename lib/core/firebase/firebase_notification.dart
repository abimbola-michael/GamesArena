import 'dart:convert';
import 'dart:io';
import 'package:gamesarena/main.dart';
import 'package:http/http.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../shared/utils/constants.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services.dart';

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
          icon: '@mipmap/launcher_icon',
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

  Future<void> initNotification() async {
    if (!kIsWeb && Platform.isWindows) return;

    await messaging.requestPermission();

    String? token;
    if (kIsWeb) {
      final key = await getPrivateKey();
      if (key == null) return;
      String vapidKey = key.vapidKey;
      token = await messaging.getToken(vapidKey: vapidKey);
    } else {
      token = await messaging.getToken();
    }
    if (token != null) {
      updateToken(token);
    }
    messaging.onTokenRefresh.listen((token) {
      updateToken(token);
    });
    initPushNotification();
    initLocalNotification();
  }
}

Future sendPushNotification(String token, String title, String body) async {
  if (privateKey == null) return;
  String firebaseAuthKey = privateKey!.firebaseAuthKey;
  try {
    await post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Authorization": "key=$firebaseAuthKey",
      },
      body: jsonEncode(<String, dynamic>{
        "priority": "high",
        "data": <String, dynamic>{
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "status": "done",
          "body": body,
          "title": title,
        },
        "notification": <String, dynamic>{
          "body": body,
          "title": title,
          "android_channel_id": CHANNEL_ID,
        },
        "to": token,
      }),
    );
  } catch (e) {}
}
