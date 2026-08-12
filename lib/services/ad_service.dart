import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/ad_constants.dart';

enum RewardType { hint, extraLife, undo, bulb, autoMark }

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _interstitialReady = false;

  static RewardedAd? _rewardedAd;
  static bool _rewardedReady = false;
  static bool _rewardedLoading = false;

  static BannerAd? _topBannerAd;
  static BannerAd? _bottomBannerAd;
  static bool _topBannerLoading = false;
  static bool _bottomBannerLoading = false;

  static AppOpenAd? _appOpenAd;
  static DateTime? _appOpenLoadTime;
  static bool _isShowingAd = false;
  static bool _adsRemoved = false;
  static bool isInGame = false;

  static bool get isPresentingFullScreenAd => _isShowingAd;

  /// Call in main() before runApp()
  static Future<void> initialize({bool adsRemoved = false}) async {
    _adsRemoved = adsRemoved;
    await MobileAds.instance.initialize();
    _preloadInterstitial();
    _preloadAppOpenAd();
    if (!adsRemoved) {
      _preloadRewarded();
    }
  }

  static void _logLoadFailure(String adType, LoadAdError error) {
    debugPrint(
      '$adType failed to load: code=${error.code}, '
      'message=${error.message}, domain=${error.domain}, error=$error',
    );
  }

  static void _preloadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: AdConstants.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _logLoadFailure('App-open ad', error);
        },
      ),
    );
  }

  static void showAppOpenAdIfAvailable({bool adsRemoved = false}) {
    if (adsRemoved || _isShowingAd || isInGame) return;

    if (_appOpenAd == null) {
      _preloadAppOpenAd();
      return;
    }

    if (_appOpenLoadTime != null &&
        DateTime.now().difference(_appOpenLoadTime!) >
            const Duration(hours: 4)) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      _preloadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _preloadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _preloadAppOpenAd();
      },
    );

    _appOpenAd!.show();
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
            onAdShowedFullScreenContent: (ad) {
              _isShowingAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingAd = false;
              ad.dispose();
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingAd = false;
              ad.dispose();
              _preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialReady = false;
          _logLoadFailure('Interstitial ad', error);
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

  static void _preloadRewarded() {
    if (_adsRemoved || _rewardedLoading || _rewardedReady) return;

    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdConstants.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          if (_adsRemoved) {
            ad.dispose();
            return;
          }

          _rewardedAd = ad;
          _rewardedReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingAd = false;
              ad.dispose();
              _preloadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingAd = false;
              ad.dispose();
              _preloadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading = false;
          _rewardedReady = false;
          _logLoadFailure('Rewarded ad preload', error);
          if (!_adsRemoved) {
            Future.delayed(const Duration(seconds: 3), _preloadRewarded);
          }
        },
      ),
    );
  }

  /// Shows a rewarded ad. Calls onRewarded with the RewardType when complete.
  static bool showRewarded(
    RewardType type, {
    required Function(RewardType) onRewarded,
    bool adsRemoved = false,
    VoidCallback? onClosed,
  }) {
    _adsRemoved = adsRemoved;
    if (adsRemoved) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _rewardedReady = false;
      return false;
    }

    final cachedAd = _rewardedAd;
    if (_rewardedReady && cachedAd != null) {
      _rewardedReady = false;
      _rewardedAd = null;
      cachedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          _isShowingAd = false;
          ad.dispose();
          _preloadRewarded();
          onClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isShowingAd = false;
          ad.dispose();
          _preloadRewarded();
          onClosed?.call();
        },
      );
      cachedAd.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewarded(type);
        },
      );
      _preloadRewarded();
      return true;
    }

    // Fall back to an on-demand load if the preloaded ad is not ready yet.
    RewardedAd.load(
      adUnitId: AdConstants.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingAd = false;
              ad.dispose();
              _preloadRewarded();
              onClosed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingAd = false;
              ad.dispose();
              _preloadRewarded();
              onClosed?.call();
            },
          );
          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onRewarded(type);
          });
          _preloadRewarded();
        },
        onAdFailedToLoad: (error) {
          _logLoadFailure('Rewarded ad on-demand', error);
          _preloadRewarded();
          onClosed?.call();
        },
      ),
    );
    return true;
  }

  /// Starts loading both game-banner placements before GameScreen mounts.
  static void preloadGameBanners({bool adsRemoved = false}) {
    _adsRemoved = adsRemoved;
    if (adsRemoved) {
      _topBannerAd?.dispose();
      _bottomBannerAd?.dispose();
      _topBannerAd = null;
      _bottomBannerAd = null;
      return;
    }

    _preloadBanner(isTop: true);
    _preloadBanner(isTop: false);
  }

  static void _preloadBanner({required bool isTop}) {
    final cachedAd = isTop ? _topBannerAd : _bottomBannerAd;
    final isLoading = isTop ? _topBannerLoading : _bottomBannerLoading;
    if (_adsRemoved || cachedAd != null || isLoading) return;

    if (isTop) {
      _topBannerLoading = true;
    } else {
      _bottomBannerLoading = true;
    }

    final placement = isTop ? 'top' : 'bottom';
    final adUnitId =
        isTop ? AdConstants.topBannerUnitId : AdConstants.bottomBannerUnitId;
    late final BannerAd banner;
    banner = createBanner(
      adUnitId: adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (isTop) {
            _topBannerLoading = false;
          } else {
            _bottomBannerLoading = false;
          }

          if (_adsRemoved) {
            ad.dispose();
          } else if (isTop) {
            _topBannerAd = banner;
          } else {
            _bottomBannerAd = banner;
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (isTop) {
            _topBannerLoading = false;
          } else {
            _bottomBannerLoading = false;
          }
          _logLoadFailure('$placement banner ad preload', error);
          ad.dispose();
        },
      ),
    )..load();
  }

  /// Transfers ownership of a loaded preloaded banner to its widget.
  static BannerAd? getPreloadedBanner(String adUnitId) {
    if (_adsRemoved) return null;

    if (_topBannerAd?.adUnitId == adUnitId) {
      final ad = _topBannerAd;
      _topBannerAd = null;
      return ad;
    }
    if (_bottomBannerAd?.adUnitId == adUnitId) {
      final ad = _bottomBannerAd;
      _bottomBannerAd = null;
      return ad;
    }
    return null;
  }

  /// Creates and returns a BannerAd (caller must show it in a widget).
  ///
  /// [adUnitId] should be the placement-specific unit ID from [AdConstants],
  /// e.g. `AdConstants.topBannerUnitId` or `AdConstants.bottomBannerUnitId`.
  static BannerAd createBanner({
    required String adUnitId,
    BannerAdListener? listener,
    AdSize size = AdSize.banner,
  }) {
    return BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }
}
