import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gamesarena/blocs/firebase_notification.dart';
import 'package:gamesarena/blocs/firebase_service.dart';
import 'package:gamesarena/firebase_options.dart';
import 'package:gamesarena/pages/pages.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
//import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

final navigatorKey = GlobalKey<NavigatorState>();
FirebaseService fs = FirebaseService();
int themeValue = 1;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    MobileAds.instance.initialize();
  }
  final pref = await SharedPreferences.getInstance();
  final theme = pref.getInt("theme");
  if (theme == null) {
    pref.setInt("theme", 1);
  } else {
    themeValue = theme;
  }
  FirebaseNotification().initNotification();
  FirebaseService().updatePresence();
  runApp(const ProviderScope(child: MyApp()));
}

class ThemeNotifier extends StateNotifier<int> {
  //int theme = themeValue;

  ThemeNotifier(super.state);
  void toggleTheme(int theme) {
    state = theme;
    //this.theme = theme;
    //notifyListeners();
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, int>((ref) {
  return ThemeNotifier(themeValue);
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeValue = ref.watch(themeNotifierProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Games Arena',
      themeMode: themeValue == 1 ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, brightness: Brightness.light)
          // brightness: Brightness.light,
          // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
          ),
      darkTheme: ThemeData(
          //brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, brightness: Brightness.dark)
          //colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
          ),
      navigatorKey: navigatorKey,
      home: const HomePage(),
    );
    // return ChangeNotifierProvider<ThemeNotifier>(
    //   create: (context) => ThemeNotifier(),
    //   builder: (context, child) {
    //     final themeValue = Provider.of<ThemeNotifier>(context).theme;
    //     return MaterialApp(
    //       debugShowCheckedModeBanner: false,
    //       title: 'Games Arena',
    //       themeMode: themeValue == 1 ? ThemeMode.dark : ThemeMode.light,
    //       theme: ThemeData(
    //           colorScheme: ColorScheme.fromSeed(
    //               seedColor: Colors.blue, brightness: Brightness.light)
    //           // brightness: Brightness.light,
    //           // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
    //           ),
    //       darkTheme: ThemeData(
    //           //brightness: Brightness.dark,
    //           colorScheme: ColorScheme.fromSeed(
    //               seedColor: Colors.blue, brightness: Brightness.dark)
    //           //colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
    //           ),
    //       navigatorKey: navigatorKey,
    //       home: const HomePage(),
    //     );
    //   },
    // );
  }
}
