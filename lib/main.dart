import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseUser;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:gamesarena/core/firebase/auth_methods.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/features/games/quiz/pages/quiz_game_page.dart';
import 'package:gamesarena/shared/models/private_key.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/firebase_options.dart';
import 'package:gamesarena/features/games/pages.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
//import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import './features/user/models/user.dart';
import 'features/game/pages/game_page.dart';
import 'features/home/pages/main_page.dart';
import 'features/tutorials/models/tutorial.dart';
import 'shared/utils/ads_utils.dart';
import 'theme/theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final navigatorKey = GlobalKey<NavigatorState>();
late SharedPreferences sharedPref;
bool isConnectedToInternet = false;
int themeValue = 1;
String currentUserId = "";
PrivateKey? privateKey;
Map<String, User?> usersMap = {};
AdUtils adUtils = AdUtils();
FirebaseNotification firebaseNotification = FirebaseNotification();
bool initialized = false;
bool initializedGemini = false;
bool isHomeResumed = false;

Map<String, Tutorial>? tutorialsMap;
FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  runApp(const ProviderScope(child: MyApp()));
}

class ThemeNotifier extends StateNotifier<int> {
  ThemeNotifier(super.state);
  void toggleTheme(int theme) {
    state = theme;
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, int>((ref) {
  return ThemeNotifier(themeValue);
});

class NavigateBackIntent extends Intent {}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeValue = ref.watch(themeNotifierProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Games Arena',
      themeMode: themeValue == 1 ? ThemeMode.dark : ThemeMode.light,
      navigatorKey: navigatorKey,
      darkTheme: darkThemeData,
      theme: lightThemeData,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.backspace): NavigateBackIntent(),
      },
      actions: {
        NavigateBackIntent: CallbackAction(
          onInvoke: (Intent intent) {
            navigatorKey.currentState?.pop();
            return null;
          },
        ),
      },
      home: const MainPage(),

      // home: const HomePage(),

      routes: {
        GamePage.route: (_) => const GamePage(),
      },
    );
  }
}
