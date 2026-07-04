import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/ad_constants.dart';

enum RewardType { hint, extraLife, undo, bulb }

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _interstitialReady = false;

  /// Call in main() before runApp()
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _preloadInterstitial();
  }

  /// Preloads the interstitial ad so it's ready when needed.
  static void _preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdConstants.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialReady = false;
        },
      ),
    );
  }

  /// Shows interstitial if ready and ads not removed. Preloads next one after.
  static void showInterstitial({bool adsRemoved = false}) {
    if (adsRemoved || !_interstitialReady || _interstitialAd == null) return;
    _interstitialReady = false;
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  /// Shows a rewarded ad. Calls onRewarded with the RewardType when complete.
  static void showRewarded(
    RewardType type, {
    required Function(RewardType) onRewarded,
  }) {
    RewardedAd.load(
      adUnitId: AdConstants.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onRewarded(type);
          });
        },
        onAdFailedToLoad: (error) {
          // Could call onRewarded here if you want to give the reward anyway on failure,
          // or handle it with an error callback.
        },
      ),
    );
  }

  /// Creates and returns a BannerAd (caller must show it in a widget).
  static BannerAd createBanner({
    BannerAdListener? listener,
    AdSize size = AdSize.banner,
  }) {
    return BannerAd(
      adUnitId: AdConstants.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }
}
