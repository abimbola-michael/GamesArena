import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_card_info/sim_card_info.dart';
import 'package:sim_card_info/sim_info.dart';

import 'country_codes.dart';

String dialCode = "";
String countryCode = "";
String countryDialCode = "";

Future<String?> getCurrentCountryCode() async {
  if (countryCode.isNotEmpty) return countryCode;
  try {
    // Request location permission
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

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
  await Permission.phone.request();
  final simCardInfoPlugin = SimCardInfo();
  // bool isSupported = true;
  List<SimInfo>? simCardInfo;
  // Platform messages may fail, so we use a try/catch PlatformException.
  // We also handle the message potentially returning null.
  try {
    simCardInfo = await simCardInfoPlugin.getSimInfo() ?? [];
    if (simCardInfo.isEmpty) return null;
    dialCode = simCardInfo.first.countryPhonePrefix;
    return dialCode;
  } on PlatformException {
    simCardInfo = [];
    // setState(() {
    //   isSupported = false;
    // });
    return null;
  }
}
