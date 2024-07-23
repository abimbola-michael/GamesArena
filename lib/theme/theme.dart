import 'package:flutter/material.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

final lightThemeData = ThemeData(
  //dialogBackgroundColor: const Color(0xFFF2F2F2),
  // scaffoldBackgroundColor: white,
  colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor, brightness: Brightness.light),
  useMaterial3: true,
  textTheme: TextTheme(
    bodyLarge: GoogleFonts.poppins(
        color: black, fontWeight: FontWeight.w400, fontSize: 16),
    bodyMedium: GoogleFonts.poppins(
        color: black, fontWeight: FontWeight.w400, fontSize: 14),
    bodySmall: GoogleFonts.poppins(
        color: black, fontWeight: FontWeight.w400, fontSize: 12),
    headlineLarge: GoogleFonts.poppins(
        fontSize: 36, fontWeight: FontWeight.w700, color: black),
    headlineMedium: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700, color: black),
    headlineSmall: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w700, color: black),
  ),
);

final darkThemeData = ThemeData(
  // dialogBackgroundColor: const Color(0xFF333333),
  //scaffoldBackgroundColor: black,
  colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor, brightness: Brightness.dark),
  useMaterial3: true,
  textTheme: TextTheme(
    bodyLarge: GoogleFonts.poppins(
        color: white, fontWeight: FontWeight.w400, fontSize: 16),
    bodyMedium: GoogleFonts.poppins(
        color: white, fontWeight: FontWeight.w400, fontSize: 14),
    bodySmall: GoogleFonts.poppins(
        color: white, fontWeight: FontWeight.w400, fontSize: 12),
    headlineLarge: GoogleFonts.poppins(
        fontSize: 36, fontWeight: FontWeight.w700, color: white),
    headlineMedium: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700, color: white),
    headlineSmall: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w700, color: white),
  ),
);
