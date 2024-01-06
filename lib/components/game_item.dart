import 'package:gamesarena/styles/styles.dart';
import 'package:flutter/material.dart';

import '../utils/utils.dart';

class GameItemWidget extends StatelessWidget {
  final String game;
  final double width;
  final VoidCallback onPressed;
  const GameItemWidget(
      {super.key,
      required this.game,
      required this.width,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      //height: width + 24,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.topLeft,
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width - 16,
              height: width - 16,
              child: Card(
                  semanticContainer: true,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  color: darkMode ? lightestWhite : lightestBlack,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Image.asset(getImageAsset(), fit: BoxFit.cover)),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              game,
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  String getImageAsset() {
    String asset = "";
    if (game == "Bat Ball") {
      asset = "assets/images/batball.jpeg";
    } else if (game == "Whot") {
      asset = "assets/images/whot.jpeg";
    } else if (game == "Ludo") {
      asset = "assets/images/ludo.jpeg";
    } else if (game == "Draught") {
      asset = "assets/images/draught.jpeg";
    } else if (game == "Chess") {
      asset = "assets/images/chess.jpeg";
    } else if (game == "X and O") {
      asset = "assets/images/xando.jpeg";
    }
    return asset;
  }
}
