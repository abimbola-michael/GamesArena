import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import '../../../shared/services.dart';
import '../../../shared/utils/utils.dart';
import 'splash_screen_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  @override
  void initState() {
    super.initState();
    initApp();
  }

  void initApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    sharedPref = await SharedPreferences.getInstance();
    currentUserId = sharedPref.getString("currentUserId") ??
        FirebaseAuth.instance.currentUser?.uid ??
        "";
    final theme = sharedPref.getInt("theme");
    if (theme == null) {
      sharedPref.setInt("theme", 1);
    } else {
      themeValue = theme;
    }
    ref.read(themeNotifierProvider.notifier).toggleTheme(themeValue);

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    // await AuthMethods().logOut();
    //if (privateKey != null) {
    //   Gemini.init(apiKey: privateKey!.chatGptApiKey);
    // }
    await dotenv.load();

    String apiKey = dotenv.env['GEMINI_API_KEY']!;
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
    firebaseNotification.initNotification();
    if (myId.isNotEmpty) {
      privateKey = await getPrivateKey();
    }

    await Hive.initFlutter();

    await Hive.openBox<String>("users");
    await Hive.openBox<String>("matches");
    await Hive.openBox<String>("gamelists");
    await Hive.openBox<String>("players");
    await Hive.openBox<String>("contacts");

    // await Hive.box<String>("matches").clear();
    // await Hive.box<String>("gamelists").clear();
    // await Hive.box<String>("players").clear();
    // await Hive.box<String>("users").clear();

    //final hivePath = Hive.deleteFromDisk();

    //FirebaseService().updatePresence();
    initialized = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // return const SplashScreenPage();
    return !initialized ? const SplashScreenPage() : const HomePage();
  }
}
