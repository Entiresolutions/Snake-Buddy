import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service providing the Second Chance feature via Google Mobile Ads Rewarded Ads.
class ChanceService {
  static const int kMaxChancesPerAttempt = 1;

  static const String _prodRewardedAdUnitId =
      'ca-app-pub-3794659976212193/6845270946';
  static const String _androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  final List<Completer<RewardedAd?>> _loadWaiters = [];

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _rewardedAdUnitId {
    if (kReleaseMode) {
      return _prodRewardedAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestRewardedAdUnitId
        : _androidTestRewardedAdUnitId;
  }

  /// Preloads a rewarded ad so it is ready when the player needs a second chance.
  void preloadAd() {
    if (!_isSupportedPlatform || _rewardedAd != null || _isLoading) return;
    unawaited(_loadAd());
  }

  Future<RewardedAd?> _loadAd() {
    if (!_isSupportedPlatform) return Future.value(null);
    if (_rewardedAd != null) return Future.value(_rewardedAd);

    final waiter = Completer<RewardedAd?>();
    _loadWaiters.add(waiter);

    if (!_isLoading) {
      _isLoading = true;
      try {
        RewardedAd.load(
          adUnitId: _rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _isLoading = false;
              _rewardedAd = ad;
              _completeWaiters(ad);
            },
            onAdFailedToLoad: (error) {
              debugPrint('RewardedAd failed to load: $error');
              _isLoading = false;
              _rewardedAd = null;
              _completeWaiters(null);
            },
          ),
        );
      } catch (e) {
        debugPrint('RewardedAd load exception: $e');
        _isLoading = false;
        _rewardedAd = null;
        _completeWaiters(null);
      }
    }

    return waiter.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => null,
    );
  }

  void _completeWaiters(RewardedAd? ad) {
    final waiters = List<Completer<RewardedAd?>>.from(_loadWaiters);
    _loadWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) {
        w.complete(ad);
      }
    }
  }

  /// Shows a rewarded ad and returns `true` only if the user earned the reward.
  Future<bool> requestChance() async {
    if (!_isSupportedPlatform) return false;

    RewardedAd? ad = _rewardedAd;
    _rewardedAd = null;

    ad ??= await _loadAd();
    if (ad == null) {
      return false;
    }

    // Consume the cached reference if _loadAd just populated it.
    if (_rewardedAd == ad) {
      _rewardedAd = null;
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
        debugPrint('RewardedAd failed to show: $error');
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
      debugPrint('RewardedAd show exception: $e');
      ad.dispose();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      preloadAd();
    }

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _completeWaiters(null);
  }
}
