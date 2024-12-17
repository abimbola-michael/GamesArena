//ca-app-pub-2803440295563056/6114982288
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gamesarena/main.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

InterstitialAd? _interstitialAd;

class AdUtils {
  Timer? adTimer;
  int adTime = 5;
  int startTimeRange = 15;
  int endTimeRange = 25;
  Random random = Random();

  void initializeAd() {
    _startTimer();
  }

  // void _getAdTime() {
  //   adTime = startTimeRange + random.nextInt(endTimeRange - startTimeRange + 1);
  //   print("adTime = $adTime");
  // }

  void _startTimer() {
    //_getAdTime();
    adTimer?.cancel();
    adTimer = Timer(Duration(minutes: adTime), () {
      loadAd();
    });
  }

  void _stopTimer() {
    adTimer?.cancel();
    adTimer = null;
  }

  void loadAd() async {
    if (privateKey == null) return;
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    // final key = await getPrivateKey();
    //|| key == null
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    //String mobileAdUnit = dotenv.get("ADUNITID");
    String mobileAdUnit = privateKey!.mobileAdUnit;

    InterstitialAd.load(
        adUnitId: mobileAdUnit,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {
                  _stopTimer();
                },
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  _startTimer();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  _startTimer();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
            _interstitialAd!.show();
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            // startTimer();
          },
        ));
  }

  void disposeAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
