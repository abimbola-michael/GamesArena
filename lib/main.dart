import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebaseUser;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
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
import './features/game/models/match.dart';

import './features/game/models/game_list.dart';
import './features/user/models/user.dart';
import 'features/game/pages/game_page.dart';
import 'shared/utils/ads_utils.dart';
import 'theme/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();
late SharedPreferences sharedPref;
int themeValue = 1;
String currentUserId = "";
PrivateKey? privateKey;
Map<String, User?> usersMap = {};
AdUtils adUtils = AdUtils();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  privateKey = await getPrivateKey();
  //if (privateKey != null) {
  //   Gemini.init(apiKey: privateKey!.chatGptApiKey);
  // }
  String apiKey = "AIzaSyDvzr6pZ2o_DlWGFtzFmRrREJaiCG2ulHQ";
  Gemini.init(apiKey: apiKey);

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    MobileAds.instance.initialize();

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  sharedPref = await SharedPreferences.getInstance();
  currentUserId = sharedPref.getString("currentUserId") ??
      firebaseUser.FirebaseAuth.instance.currentUser?.uid ??
      "";
  final theme = sharedPref.getInt("theme");
  if (theme == null) {
    sharedPref.setInt("theme", 1);
  } else {
    themeValue = theme;
  }
  await Hive.initFlutter();

  await Hive.openBox<String>("users");
  await Hive.openBox<String>("matches");
  await Hive.openBox<String>("gamelists");
  await Hive.openBox<String>("players");
  await Hive.openBox<String>("contacts");

  //final hivePath = Hive.deleteFromDisk();

  FirebaseNotification().initNotification();
  //FirebaseService().updatePresence();
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
      home: const HomePage(),
      // home: StreamBuilder<User?>(
      //     stream: FirebaseAuth.instance.authStateChanges(),
      //     builder: (context, snapshot) {
      //       print("data = ${snapshot.data}");
      //       currentUserId = snapshot.data?.uid ?? "";

      //       if (snapshot.connectionState == ConnectionState.waiting) {
      //         return const Center(
      //           child: CircularProgressIndicator(),
      //         );
      //       }
      //       return const HomePage();

      //       // return snapshot.hasData
      //       //     ? const HomePage()
      //       //     : const LoginPage(login: true);
      //     }),
      routes: {
        GamePage.route: (_) => const GamePage(),
        // ChessGamePage.route: (_) => const ChessGamePage(),
        // DraughtGamePage.route: (_) => const DraughtGamePage(),
        // LudoGamePage.route: (_) => const LudoGamePage(),
        // WhotGamePage.route: (_) => const WhotGamePage(),
        // WordPuzzleGamePage.route: (_) => const WordPuzzleGamePage(),
        // XandOGamePage.route: (_) => const XandOGamePage(),
        // QuizGamePage.route: (_) => const QuizGamePage(),
      },
    );
  }
}
