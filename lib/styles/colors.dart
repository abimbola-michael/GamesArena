import 'package:flutter/material.dart';

import '../utils/utils.dart';

Color boardColor = Colors.white;
Color ballColor = Colors.yellow;
Color batColor = Colors.blue;
Color appColor = Colors.blue;

// Color appBackgroundColor = darkMode ? Colors.black : Colors.white;
// Color cardBackgroundColor = darkMode ? lightestBlack : Colors.white;

//Color tintColor = darkMode ? Colors.white : Colors.black;
// Color lightBlack =
//     darkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8);
// Color lighterBlack =
//     darkMode ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);
// Color lightestBlack =
//     darkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2);

Color white = Colors.white;
Color lightWhite = Colors.white.withOpacity(0.8);
Color lighterWhite = Colors.white.withOpacity(0.5);
Color lightestWhite = Colors.white.withOpacity(0.1);

Color black = Colors.black;
Color lightBlack = Colors.black.withOpacity(0.8);
Color lighterBlack = Colors.black.withOpacity(0.5);
Color lightestBlack = Colors.black.withOpacity(0.1);

Color tintColor = darkMode ? white : black;

Color tintColorLight = darkMode ? lightWhite : lightBlack;
Color tintColorLighter = darkMode ? lighterWhite : lighterBlack;
Color tintColorLightest = darkMode ? lightestWhite : lightestBlack;
