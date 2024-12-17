import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/models/match.dart';
import 'package:gamesarena/features/records/pages/game_records_page.dart';
import 'package:gamesarena/main.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/game/models/game_list.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/utils.dart';
import '../../shared/services.dart';

const androidChannel = AndroidNotificationChannel(CHANNEL_ID, CHANNEL_NAME,
    description: CHANNEL_DESC, importance: Importance.defaultImportance);
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> handleMessage(RemoteMessage? message,
    [bool isMessageOpened = false]) async {
  if (message == null) return;
  final notification = message.notification;
  final data = message.data;
  final title = notification?.title;
  final body = notification?.body;
  final isDataOnly = title == null && body == null;
  final notificationType = data["notificationType"];
  if (isMessageOpened) {
    if (notificationType == "match") {
      // final match = Match.fromMap(data);
      // navigatorKey.currentState?.push(MaterialPageRoute(
      //     builder: (context) =>
      //         GameRecordsPage(game_id: game_id, id: id, type: type)));
    }
  } else {
    if (!isDataOnly) return;
    if (notificationType == "match") {
      final match = Match.fromMap(data);

      final gameListsBox = Hive.box<String>("gamelists");
      final matchesBox = Hive.box<String>("matches");

      final gameListJson = gameListsBox.get(match.game_id);
      final gameList =
          gameListJson == null ? null : GameList.fromJson(gameListJson);
      if (gameList != null) {
        if (matchesBox.get(match.match_id) == null) {
          gameList.unseen =
              match.creator_id == myId ? 0 : (gameList.unseen ?? 0) + 1;
        }
        gameList.match = match;
        gameListsBox.put(gameList.game_id, gameList.toJson());
        matchesBox.put(match.match_id, match.toJson());
      }
    }
  }
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
  FirebaseMessaging.onMessageOpenedApp
      .listen((message) => handleMessage(message, true));
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

  void subscribeToTopic(String topic) {
    if (!kIsWeb && Platform.isWindows) return;

    FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  void unsubscribeFromTopic(String topic) {
    if (!kIsWeb && Platform.isWindows) return;

    FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  void updateFirebaseToken() async {
    if (!kIsWeb && Platform.isWindows) return;
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
  }

  Future<void> initNotification() async {
    if (!kIsWeb && Platform.isWindows) return;

    await messaging.requestPermission();

    //updateFirebaseToken();

    messaging.onTokenRefresh.listen((token) {
      updateToken(token);
    });
    initPushNotification();
    initLocalNotification();
  }
}

Future sendPushNotification(String tokenOrTopic,
    {Map<String, dynamic>? data,
    String? title,
    String? body,
    String? notificationType,
    bool isTopic = false}) async {
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
          "notificationType": notificationType,
          if (data != null) ...data,
        },
        if (title != null || body != null) ...{
          "notification": <String, dynamic>{
            "body": body,
            "title": title,
            "android_channel_id": CHANNEL_ID,
          }
        },
        if (isTopic) ...{
          "topic": tokenOrTopic,
        } else ...{
          "to": tokenOrTopic,
        }
      }),
    );
  } catch (e) {}
}
