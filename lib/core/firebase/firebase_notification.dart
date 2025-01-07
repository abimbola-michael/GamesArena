import 'dart:convert';
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

import '../../features/game/models/game_list.dart';
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
  print("handleMessage message = $message, mode = $mode");
  if (message == null) return;
  final notification = message.notification;

  if (notification != null && mode == NotificationMode.background) {
    final title = notification.title;
    final body = notification.body;
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      title,
      body,
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
  }

  final data = message.data;

  print("pushNotificationData = $data");

  if (data["data"] != null) {
    FirebaseNotification.onMessageData(data);
    final notificationType = data["type"];
    final dataValue = jsonDecode(data["data"]);
    if (mode == NotificationMode.foreground ||
        mode == NotificationMode.background ||
        mode == NotificationMode.initial) {
      if (notificationType == "match") {
        final match = Match.fromMap(dataValue);

        final gameListsBox = Hive.box<String>("gamelists");
        final matchesBox = Hive.box<String>("matches");

        final gameListJson = gameListsBox.get(match.game_id);
        final gameList =
            gameListJson == null ? null : GameList.fromJson(gameListJson);
        if (gameList != null) {
          if (matchesBox.get(match.match_id) == null) {
            gameList.unseen =
                match.creator_id == myId ? 0 : (gameList.unseen ?? 0) + 1;
            gameList.match = match;
            gameListsBox.put(gameList.game_id, gameList.toJson());
          }

          matchesBox.put(match.match_id, match.toJson());
        }
      }
    } else {}
  }
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

  static void Function(Map<String, dynamic>? data) onMessageData = (data) {};

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

Future sendUserPushNotification(String userId,
    {Map<String, dynamic>? data,
    String? title,
    String? body,
    String? notificationType,
    List<String>? previouslySentTokens}) async {
  //previouslySentTokens == null
  final user = await getUser(userId, useCache: false);
  if ((user?.tokens ?? []).isEmpty) return;

  for (int i = 0; i < user!.tokens!.length; i++) {
    final token = user.tokens![i];
    print("userToken = $token");
    // if (previouslySentTokens != null && previouslySentTokens.contains(token)) {
    //   continue;
    // }
    final result = await sendPushNotification(token,
        data: data,
        title: title,
        body: body,
        notificationType: notificationType);
    // if (!result) {
    //   if (previouslySentTokens != null) continue;
    //   sendUserPushNotification(userId,
    //       data: data,
    //       title: title,
    //       body: body,
    //       notificationType: notificationType,
    //       previouslySentTokens: previouslySentTokens);
    //   return;
    // } else {
    //   previouslySentTokens ??= [];
    //   previouslySentTokens.add(token);
    // }
  }
}

Future<String?> getAccessToken() async {
  String serviceAccountPath = 'secure_files/service_account.json';

  final serviceAccount = ServiceAccountCredentials.fromJson(
      json.decode(File(serviceAccountPath).readAsStringSync()));

  final authClient = await clientViaServiceAccount(
      serviceAccount, ['https://www.googleapis.com/auth/firebase.messaging']);

  return authClient.credentials.accessToken.data;
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
      print('Failed to obtain access token');
      return false;
    }
    print("accessToken = $accessToken");

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final notificationPayload = {
      'message': {
        isTopic ? "topic" : 'token': tokenOrTopic,
        if (title != null || body != null)
          'notification': {
            'title': title,
            'body': body,
          },

        "data": {
          "type": notificationType,
          if (data != null) "data": jsonEncode(data),
        }

        // 'data': data ?? {},
        // "data": {
        //   "click_action": "FLUTTER_NOTIFICATION_CLICK",
        //   "status": "done",
        //   "body": body,
        //   "title": title,
        //   "notificationType": notificationType,
        // },
      }
    };

    final response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: headers,
      body: jsonEncode(notificationPayload),
    );

    print('FCM Response: ${response.statusCode} - ${response.body}');
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }

// Future<bool> sendPushNotification(String tokenOrTopic,
//     {Map<String, dynamic>? data,
//     String? title,
//     String? body,
//     String? notificationType,
//     bool isTopic = false}) async {
//   privateKey ??= await getPrivateKey();
//   String firebaseAuthKey = privateKey!.firebaseAuthKey;
//   print(
//       "firebaseAuthKey = $firebaseAuthKey, tokenOrTopic = $tokenOrTopic data = $data, $title, $body");
//   try {
//     final response = await post(
//       Uri.parse("https://fcm.googleapis.com/fcm/send"),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "key=$firebaseAuthKey",
//       },
//       body: jsonEncode(<String, dynamic>{
//         "priority": "high",
//         if (title != null || body != null)
//           "notification": {
//             "body": body,
//             "title": title,
//             "android_channel_id": CHANNEL_ID,
//           },
//         "data": {
//           "click_action": "FLUTTER_NOTIFICATION_CLICK",
//           "status": "done",
//           "body": body,
//           "title": title,
//           "notificationType": notificationType,
//           if (data != null) "data": data,
//         },
//         if (isTopic) "topic": tokenOrTopic else "to": tokenOrTopic,
//       }),
//     );
//     print('FCM Response: ${response.statusCode} - ${response.body}');
//     return response.statusCode == 200;
//   } catch (e) {
//     return false;
//   }
}
