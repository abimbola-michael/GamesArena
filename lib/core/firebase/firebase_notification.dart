import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/models/match.dart';
import 'package:gamesarena/main.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/user/services.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services.dart';

enum NotificationMode {
  messageOpened,
  background,
  foreground,
  initial,
  response
}

const androidChannel = AndroidNotificationChannel(CHANNEL_ID, CHANNEL_NAME,
    description: CHANNEL_DESC, importance: Importance.defaultImportance);
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await handleMessage(message, NotificationMode.background);
}

Future<void> handleMessage(
    RemoteMessage? message, NotificationMode mode) async {
  // print("handleMessage message = $message, mode = $mode");
  if (message == null) return;
  final notification = message.notification;
  final data = message.data;
  if (data.isEmpty) return;
  FirebaseNotification.sendData(data);

  // if (notification != null && mode == NotificationMode.background) {
  //   final title = notification.title;
  //   final body = notification.body;
  //   flutterLocalNotificationsPlugin.show(
  //     notification.hashCode,
  //     title,
  //     body,
  //     NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         androidChannel.id,
  //         androidChannel.name,
  //         channelDescription: androidChannel.description,
  //         icon: '@mipmap/launcher_icon',
  //         // importance: Importance.max,
  //         // priority: Priority.max,
  //         playSound: true,
  //       ),
  //     ),
  //     payload: jsonEncode(message.toMap()),
  //   );
  // }
}

Future<void> handleResponse(NotificationResponse response) async {
  if (response.payload == null) return;
  final message = RemoteMessage.fromMap(jsonDecode(response.payload!));
  handleMessage(message, NotificationMode.response);
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
  FirebaseMessaging.instance
      .getInitialMessage()
      .then((message) => handleMessage(message, NotificationMode.initial));
  FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => handleMessage(message, NotificationMode.messageOpened));
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage
      .listen((message) => handleMessage(message, NotificationMode.foreground));
}

class FirebaseNotification {
  final messaging = FirebaseMessaging.instance;

  static List<ValueChanged<Map<String, dynamic>>> listeners = [];

  static addListener(ValueChanged<Map<String, dynamic>> callback) {
    listeners.add(callback);
  }

  static removeListener(ValueChanged<Map<String, dynamic>> callback) {
    listeners.remove(callback);
  }

  static sendData(Map<String, dynamic> data) {
    for (int i = 0; i < listeners.length; i++) {
      final callback = listeners[i];
      callback(data);
    }
  }

  void subscribeToTopic(String topic) {
    if (!isAndroidAndIos) return;

    FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  void unsubscribeFromTopic(String topic) {
    if (!isAndroidAndIos) return;

    FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  Future<String?> getMessagingToken() async {
    if (!kIsWeb && Platform.isWindows) return null;
    String? token;

    if (kIsWeb) {
      privateKey ??= await getPrivateKey();
      if (privateKey == null) return null;
      String vapidKey = privateKey!.vapidKey;
      token = await messaging.getToken(vapidKey: vapidKey);
    } else {
      token = await messaging.getToken();
    }

    return token;
  }

  void updateFirebaseToken() async {
    final token = await getMessagingToken();
    if (token != null) {
      updateToken(token);
    }
  }

  Future<void> initNotification() async {
    if (!kIsWeb && Platform.isWindows) return;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    messaging.onTokenRefresh.listen(updateToken);

    await initLocalNotification();
    await initPushNotification();
  }
}

Future<String?> getAccessToken() async {
  String serviceAccountPath = 'secure_files/service_account.json';

  // final serviceAccount = ServiceAccountCredentials.fromJson(
  //     json.decode(File(serviceAccountPath).readAsStringSync()));
  privateKey ??= await getPrivateKey();
  if (privateKey == null) return null;
  final clientId = privateKey!.clientId;
  final clientEmail = privateKey!.clientEmail;
  final key = privateKey!.privateKey;
  // dotenv.env['CLIENT_EMAIL']!
  //dotenv.env['CLIENT_ID']!
  //dotenv.env['PRIVATE_KEY']!
  final serviceAccount = ServiceAccountCredentials(
    clientEmail,
    ClientId(clientId),
    key.replaceAll(r'\n', '\n'),
  );

  final authClient = await clientViaServiceAccount(
      serviceAccount, ['https://www.googleapis.com/auth/firebase.messaging']);

  return authClient.credentials.accessToken.data;
}

Future sendUserPushNotification(String userId,
    {Map<String, dynamic>? data,
    String? title,
    String? body,
    String? notificationType}) async {
  if (!isConnectedToInternet) return;

  final user = await getUser(userId);
  final tokens = user?.tokens ?? [];

  if (tokens.isEmpty) return;

  List<String> sentTokens = [];
  List<String> unsentTokens = [];

  for (int i = 0; i < tokens.length; i++) {
    final token = tokens[i];

    final result = await sendPushNotification(token,
        data: data,
        title: title,
        body: body,
        notificationType: notificationType);
    if (result) {
      sentTokens.add(token);
    } else {
      unsentTokens.add(token);
    }
  }

  if (unsentTokens.isNotEmpty) {
    final user = await getUser(userId, useCache: false);
    final tokens = user?.tokens ?? [];
    if (!isConnectedToInternet) return;

    List<String> newTokens = tokens
        .where((token) =>
            sentTokens.contains(token) || unsentTokens.contains(token))
        .toList();

    for (int i = 0; i < newTokens.length; i++) {
      final token = newTokens[i];

      await sendPushNotification(token,
          data: data,
          title: title,
          body: body,
          notificationType: notificationType);
    }
    if (!isConnectedToInternet) return;

    final dormantTokens = tokens.where((token) => unsentTokens.contains(token));
    if (dormantTokens.isEmpty) return;

    tokens.removeWhere((token) => unsentTokens.contains(token));

    updateUserToken(userId, tokens);
  }
}

Future<bool> sendPushNotification(String tokenOrTopic,
    {Map<String, dynamic>? data,
    String? title,
    String? body,
    String? notificationType,
    bool isTopic = false}) async {
  String fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/games-arena-dbc67/messages:send';

  try {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      // print('Failed to obtain access token');
      return false;
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final notificationPayload = {
      'message': {
        if (isTopic) "topic": tokenOrTopic else "token": tokenOrTopic,
        if (title != null || body != null) ...{
          'notification': {
            'title': title,
            'body': body,
          },
          "android": {
            "priority": "HIGH",
            "notification": {"channel_id": "high_importance_channel"}
          },
        },
        "data": {
          "type": notificationType,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "status": "done",
          if (data != null) "data": jsonEncode(data),
        }
      }
    };

    final response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: headers,
      body: jsonEncode(notificationPayload),
    );

    // print('FCM Response: ${response.statusCode} - ${response.body}');

    return response.statusCode == 200;
  } catch (e) {
    // print("notificationError = $e");
    return false;
  }
}
