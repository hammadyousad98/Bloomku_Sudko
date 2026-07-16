import 'dart:io';

class AdConstants {
  /// true uses Google's test ad unit IDs. Set false for release after replacing
  /// the placeholder real IDs below with AdMob IDs for this app.
  static const bool useTestAds = false;

  /// Per-placement banner switches for GameScreen. These only control the top
  /// and bottom banner widgets; PlayerProgress.adsRemoved remains the master
  /// switch that suppresses all ads for a player.
  static const bool showTopBannerAd = true;
  static const bool showBottomBannerAd = true;

  static String get topBannerUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3484975951055142/7603054198'
        : 'YOUR_REAL_IOS_TOP_BANNER';
  }

  static String get bottomBannerUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3484975951055142/5875039556'
        : 'YOUR_REAL_IOS_BOTTOM_BANNER';
  }

  static String get interstitialUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3484975951055142/5350506933'
        : 'YOUR_REAL_IOS_INTERSTITIAL';
  }

  static String get rewardedUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3484975951055142/4216995455'
        : 'YOUR_REAL_IOS_REWARDED';
  }

  static String get appOpenAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9257395921'
          : 'ca-app-pub-3940256099942544/5625152562';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3484975951055142/5415325816'
        : 'YOUR_REAL_IOS_APP_OPEN';
  }
}
