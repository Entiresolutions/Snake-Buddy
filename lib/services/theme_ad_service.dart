import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for showing Google Mobile Ads Rewarded Interstitial Ads to unlock themes.
class ThemeAdService {
  static const String _prodRewardedInterstitialAdUnitId =
      'ca-app-pub-3794659976212193/4650031648';
  static const String _androidTestRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';
  static const String _iosTestRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/6978759866';

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isLoading = false;
  final List<Completer<RewardedInterstitialAd?>> _loadWaiters = [];

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _adUnitId {
    if (kReleaseMode) {
      return _prodRewardedInterstitialAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestRewardedInterstitialAdUnitId
        : _androidTestRewardedInterstitialAdUnitId;
  }

  /// Preloads a rewarded interstitial ad so it is ready when unlocking a theme.
  void preloadAd() {
    if (!_isSupportedPlatform || _rewardedInterstitialAd != null || _isLoading) {
      return;
    }
    unawaited(_loadAd());
  }

  Future<RewardedInterstitialAd?> _loadAd() {
    if (!_isSupportedPlatform) return Future.value(null);
    if (_rewardedInterstitialAd != null) {
      return Future.value(_rewardedInterstitialAd);
    }

    final waiter = Completer<RewardedInterstitialAd?>();
    _loadWaiters.add(waiter);

    if (!_isLoading) {
      _isLoading = true;
      try {
        RewardedInterstitialAd.load(
          adUnitId: _adUnitId,
          request: const AdRequest(),
          rewardedInterstitialAdLoadCallback:
              RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              _isLoading = false;
              _rewardedInterstitialAd = ad;
              _completeWaiters(ad);
            },
            onAdFailedToLoad: (error) {
              debugPrint('RewardedInterstitialAd failed to load: $error');
              _isLoading = false;
              _rewardedInterstitialAd = null;
              _completeWaiters(null);
            },
          ),
        );
      } catch (e) {
        debugPrint('RewardedInterstitialAd load exception: $e');
        _isLoading = false;
        _rewardedInterstitialAd = null;
        _completeWaiters(null);
      }
    }

    return waiter.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => null,
    );
  }

  void _completeWaiters(RewardedInterstitialAd? ad) {
    final waiters = List<Completer<RewardedInterstitialAd?>>.from(_loadWaiters);
    _loadWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) {
        w.complete(ad);
      }
    }
  }

  /// Shows a rewarded interstitial ad and returns `true` if the user earned the reward.
  Future<bool> showAd() async {
    if (!_isSupportedPlatform) return false;

    RewardedInterstitialAd? ad = _rewardedInterstitialAd;
    _rewardedInterstitialAd = null;

    ad ??= await _loadAd();
    if (ad == null) {
      return false;
    }

    if (_rewardedInterstitialAd == ad) {
      _rewardedInterstitialAd = null;
    }

    final completer = Completer<bool>();
    bool earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        if (!completer.isCompleted) {
          completer.complete(earnedReward);
        }
        preloadAd();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        debugPrint('RewardedInterstitialAd failed to show: $error');
        shownAd.dispose();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        preloadAd();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (adWithoutView, reward) {
          earnedReward = true;
        },
      );
    } catch (e) {
      debugPrint('RewardedInterstitialAd show exception: $e');
      ad.dispose();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      preloadAd();
    }

    return completer.future;
  }

  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _completeWaiters(null);
  }
}
