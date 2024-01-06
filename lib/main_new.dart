// import 'package:flutter/foundation.dart';
// import 'package:gamesarena/blocs/firebase_service.dart';
// import 'package:gamesarena/firebase_options.dart';
// import 'package:gamesarena/pages/pages.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // if (kIsWeb) {
//   //   await Firebase.initializeApp(
//   //     options: const FirebaseOptions(
//   //         apiKey: "AIzaSyB79lpHD9LyYySmTS4iuVoh89_B7JVVU4Y",
//   //         authDomain: "games-arena-dbc67.firebaseapp.com",
//   //         databaseURL: "https://games-arena-dbc67-default-rtdb.firebaseio.com",
//   //         projectId: "games-arena-dbc67",
//   //         storageBucket: "games-arena-dbc67.appspot.com",
//   //         messagingSenderId: "182221656090",
//   //         appId: "1:182221656090:web:e4ccb6f62d8f1c41ad41a3",
//   //         measurementId: "G-S79G6MVH39"),
//   //   );
//   // } else {
//   //   await Firebase.initializeApp(
//   //       options: DefaultFirebaseOptions.currentPlatform);
//   //   MobileAds.instance.initialize();
//   // }
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   if (!kIsWeb) {
//     MobileAds.instance.initialize();
//   }
//   // if (FirebaseAuth.instance.currentUser != null) {}
//   FirebaseService().updatePresence();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Games Arena',
//         //theme: ThemeData.dark(),
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//           // primarySwatch: Colors.blue,
//         ),
//         darkTheme: ThemeData.dark(useMaterial3: true),
//         home: const HomePage());
//   }
// }
