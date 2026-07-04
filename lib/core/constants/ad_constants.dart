import 'dart:io';

class AdConstants {
  /// true uses Google's test ad unit IDs. Set false for release after replacing
  /// the placeholder real IDs below with AdMob IDs for this app.
  static const bool useTestAds = true;

  /// Per-placement banner switches for GameScreen. These only control the top
  /// and bottom banner widgets; PlayerProgress.adsRemoved remains the master
  /// switch that suppresses all ads for a player.
  static const bool showTopBannerAd = true;
  static const bool showBottomBannerAd = true;

  static String get bannerUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'YOUR_REAL_ANDROID_BANNER'
        : 'YOUR_REAL_IOS_BANNER';
  }

  static String get interstitialUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'YOUR_REAL_ANDROID_INTERSTITIAL'
        : 'YOUR_REAL_IOS_INTERSTITIAL';
  }

  static String get rewardedUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? 'YOUR_REAL_ANDROID_REWARDED'
        : 'YOUR_REAL_IOS_REWARDED';
  }
}
