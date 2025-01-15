import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../theme/colors.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offtint,
      body: Stack(
        children: [
          Center(
            child: Container(
              height: 100,
              width: 250,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("launcher_icon.png".toIcon),
                      fit: BoxFit.cover)),
            ),
            // child: Column(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     // const SizedBox(height: 10),
            //     Text("Games Arena",
            //         style: GoogleFonts.merienda(
            //           fontWeight: FontWeight.bold,
            //           fontSize: 24,
            //         ))
            //   ],
            // ),
          ),
          Positioned(
              bottom: 30,
              left: 30,
              right: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "from",
                    style: context.bodySmall?.copyWith(
                      color: lightTint,
                    ),
                  ),
                  Text(
                    "HOTTEC",
                    style: context.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ))
        ],
      ),
    );
  }
}
