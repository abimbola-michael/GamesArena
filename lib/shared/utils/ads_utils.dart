//ca-app-pub-2803440295563056/6114982288
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/subscription/pages/subscription_page.dart';
import '../services.dart';

InterstitialAd? _interstitialAd;

class AdUtils {
  //Timer? adTimer;
  int adTime = 0;
  // int maxAdTime = 600;
  int maxAdTime = 300;

  int adRetryCount = 0;
  int maxAdRetryCount = 3;
  int adsCount = 0;
  bool isSubscribed = false;

  bool get isReadyToLoad => adTime >= maxAdTime;

  void loadAd(
      {VoidCallback? onShow,
      VoidCallback? onHide,
      VoidCallback? onFail}) async {
    privateKey ??= await getPrivateKey();
    if (privateKey == null) return;
    await _interstitialAd?.dispose();
    _interstitialAd = null;

    if (kIsWeb || !isAndroidAndIos) {
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
                  adsCount++;
                  // if (adsCount % 3 == 0 && isSubscribed == false) {
                  //   gotoSubscription();
                  // }
                  // _stopTimer();
                  onShow?.call();
                },
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  if (!isConnectedToInternet ||
                      adRetryCount == maxAdRetryCount) {
                    adRetryCount = 0;
                    onFail?.call();

                    return;
                  }

                  if (isConnectedToInternet) {
                    loadAd(onShow: onShow, onHide: onHide, onFail: onFail);
                    adRetryCount++;
                  }
                  //_startTimer();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  onHide?.call();
                  //_startTimer();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
            _interstitialAd!.show();
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            if (!isConnectedToInternet || adRetryCount == maxAdRetryCount) {
              adRetryCount = 0;
              return;
            }

            if (isConnectedToInternet) {
              loadAd(onShow: onShow, onHide: onHide, onFail: onFail);
              adRetryCount++;
            }

            // startTimer();
          },
        ));
  }

  void gotoSubscription() {
    navigatorKey.currentContext?.pushTo(const SubscriptionPage());
  }

  void disposeAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
