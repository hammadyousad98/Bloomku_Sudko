import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get_it/get_it.dart';
import '../../services/ad_service.dart';
import '../../data/repositories/progress_repository.dart';

/// Shows a banner ad or an empty SizedBox if ads are removed.
///
/// [adUnitId] must be one of the placement-specific IDs from [AdConstants]
/// (e.g. `AdConstants.topBannerUnitId` or `AdConstants.bottomBannerUnitId`).
class BannerAdWidget extends StatefulWidget {
  final String adUnitId;

  const BannerAdWidget({super.key, required this.adUnitId});

  @override 
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override 
  void initState() {
    super.initState();
    final adsRemoved = GetIt.I<ProgressRepository>().getProgress().adsRemoved;
    if (!adsRemoved) {
      _bannerAd = AdService.createBanner(
        adUnitId: widget.adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            setState(() {
              _isLoaded = false;
            });
          },
        ),
      )..load();
    }
  }

  @override 
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override 
  void dispose() { 
    _bannerAd?.dispose(); 
    super.dispose(); 
  }
}
