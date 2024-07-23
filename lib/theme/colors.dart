import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/utils.dart';

const boardColor = Colors.white;
const ballColor = Colors.yellow;
const batColor = Colors.blue;
const primaryColor = Colors.blue;

const white = Colors.white;
const black = Colors.black;
const red = Colors.red;
const blue = Colors.blue;

const transparent = Colors.transparent;
final lightBlack = Colors.black.withOpacity(0.7);
final lighterBlack = Colors.black.withOpacity(0.5);
final lightestBlack = Colors.black.withOpacity(0.1);
final faintBlack = Colors.black.withOpacity(0.04);

final lightWhite = Colors.white.withOpacity(0.7);
final lighterWhite = Colors.white.withOpacity(0.5);
final lightestWhite = Colors.white.withOpacity(0.1);
final faintWhite = Colors.white.withOpacity(0.04);

Color get tint => darkMode ? white : black;
Color get lightTint => darkMode ? lightWhite : lightBlack;
Color get lighterTint => darkMode ? lighterWhite : lighterBlack;
Color get lightestTint => darkMode ? lightestWhite : lightestBlack;
Color get faintTint => darkMode ? faintWhite : faintBlack;

Color get dialogBgColor =>
    darkMode ? const Color(0xFF333333) : const Color(0xFFF2F2F2);
Color get dialogBgColor2 =>
    darkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F2);
