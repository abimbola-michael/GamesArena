import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_card_info/sim_card_info.dart';
import 'package:sim_card_info/sim_info.dart';

import 'country_codes.dart';
import 'utils.dart';

String dialCode = "";
String countryCode = "";
String countryDialCode = "";

// Future<String?> getCurrentCountryCode() async {
//   bool serviceEnabled;
//   LocationPermission permission;

//   // Test if location services are enabled.
//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     // Location services are not enabled don't continue
//     // accessing the position and request users of the
//     // App to enable the location services.
//     return Future.error('Location services are disabled.');
//   }

//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       // Permissions are denied, next time you could try
//       // requesting permissions again (this is also where
//       // Android's shouldShowRequestPermissionRationale
//       // returned true. According to Android guidelines
//       // your App should show an explanatory UI now.
//       return Future.error('Location permissions are denied');
//     }
//   }

//   if (permission == LocationPermission.deniedForever) {
//     // Permissions are denied forever, handle appropriately.
//     return Future.error(
//         'Location permissions are permanently denied, we cannot request permissions.');
//   }

//   // When we reach here, permissions are granted and we can
//   // continue accessing the position of the device.
//   final position = await Geolocator.getCurrentPosition();
//   print("position = $position");
// }

Future<String?> getCurrentCountryCode() async {
  if (countryCode.isNotEmpty) return countryCode;
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return null;
    }
    // Request location permission
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("locationDenied");
      return null;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // print("noPosition");

    // Reverse geocode the location to get the country
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      countryCode = placemarks.first.isoCountryCode ?? "";
      return countryCode; // e.g., "NG"
    }
  } catch (e) {
    print("Error getting country code: $e");
    return null;
  }

  return null;
}

Future<String?> getCurrentCountryDialingCode([String? countryIsoCode]) async {
  if (countryIsoCode == null && countryDialCode.isNotEmpty) {
    return countryDialCode;
  }

  // Step 1: Get the country ISO code (e.g., NG, US)
  String? isoCode = countryIsoCode ?? (await getCurrentCountryCode());

  //String? isoCode = countryIsoCode ?? await getSimCountryCode();
  if (isoCode == null) return null;
  final code = countryCodes.firstWhere(
      (map) => map["alpha_2_code"] == isoCode || map["alpha_3_code"] == isoCode,
      orElse: () => {})["dial_code"];
  if (countryIsoCode == null) {
    countryDialCode = code ?? "";
  }
  return code;
}

Future<String?> getDialCode() async {
  if (dialCode.isNotEmpty) return dialCode;
  await Permission.phone.request();
  final simCardInfoPlugin = SimCardInfo();

  List<SimInfo>? simCardInfo;

  try {
    simCardInfo = await simCardInfoPlugin.getSimInfo() ?? [];
    if (simCardInfo.isEmpty) return null;
    countryCode = simCardInfo.first.countryIso.toUpperCase().trim();
    print("countryCode = $countryCode");

    //final countries = CountryManager().countries;
    // dialCode = countries
    //         .firstWhereNullable(
    //             (country) => country.countryCode == countryCode.capitalize)
    //         ?.phoneCode ??
    //     "";
    final codeMap = countryCodes.firstWhereNullable((map) =>
        map["alpha_2_code"] == countryCode ||
        map["alpha_3_code"] == countryCode);

    final code = codeMap?["dial_code"];

    dialCode = code ?? "";
    return code;
  } on Exception {
    simCardInfo = [];
    if (isAndroidAndIos) return null;
    countryCode = await getCurrentCountryCode() ?? "";
    if (countryCode.isEmpty) return null;

    final codeMap = countryCodes.firstWhereNullable((map) =>
        map["alpha_2_code"] == countryCode ||
        map["alpha_3_code"] == countryCode);

    final code = codeMap?["dial_code"];

    dialCode = code ?? "";

    return null;
  }
}
