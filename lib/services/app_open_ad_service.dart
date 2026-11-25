import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for showing an App Open Ad when transitioning from Level Select
/// to the Play screen, skipping the very first game play.
class AppOpenAdService {
  static const String _hasPlayedFirstGameKey = 'ads.hasPlayedFirstGame';

  static const String _prodAppOpenAdUnitId =
      'ca-app-pub-3794659976212193/1872272174';
  static const String _androidTestAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _iosTestAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/5575463023';

  static const Duration _maxAdAge = Duration(hours: 4);

  AppOpenAd? _appOpenAd;
  DateTime? _adLoadTime;
  bool _isLoading = false;
  bool _isShowing = false;
  final List<Completer<AppOpenAd?>> _loadWaiters = [];

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _adUnitId {
    if (kReleaseMode) {
      return _prodAppOpenAdUnitId;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestAppOpenAdUnitId
        : _androidTestAppOpenAdUnitId;
  }

  bool get _isAdAvailable {
    if (_appOpenAd == null || _adLoadTime == null) return false;
    return DateTime.now().difference(_adLoadTime!) < _maxAdAge;
  }

  /// Preloads an App Open Ad if the user has already played their first game.
  Future<void> preloadIfEligible() async {
    if (!_isSupportedPlatform) return;
    final prefs = await SharedPreferences.getInstance();
    final hasPlayedFirst = prefs.getBool(_hasPlayedFirstGameKey) ?? false;
    if (hasPlayedFirst) {
      preloadAd();
    }
  }

  /// Preloads an App Open Ad.
  void preloadAd() {
    if (!_isSupportedPlatform || _isLoading) return;
    if (_isAdAvailable) return;
    if (_appOpenAd != null) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _adLoadTime = null;
    }
    unawaited(_loadAd());
  }

  Future<AppOpenAd?> _loadAd() {
    if (!_isSupportedPlatform) return Future.value(null);
    if (_isAdAvailable) return Future.value(_appOpenAd);

    final waiter = Completer<AppOpenAd?>();
    _loadWaiters.add(waiter);

    if (!_isLoading) {
      _isLoading = true;
      try {
        AppOpenAd.load(
          adUnitId: _adUnitId,
          request: const AdRequest(),
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              _isLoading = false;
              _appOpenAd = ad;
              _adLoadTime = DateTime.now();
              _completeWaiters(ad);
            },
            onAdFailedToLoad: (error) {
              debugPrint('AppOpenAd failed to load: $error');
              _isLoading = false;
              _appOpenAd = null;
              _adLoadTime = null;
              _completeWaiters(null);
            },
          ),
        );
      } catch (e) {
        debugPrint('AppOpenAd load exception: $e');
        _isLoading = false;
        _appOpenAd = null;
        _adLoadTime = null;
        _completeWaiters(null);
      }
    }

    return waiter.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => null,
    );
  }

  void _completeWaiters(AppOpenAd? ad) {
    final waiters = List<Completer<AppOpenAd?>>.from(_loadWaiters);
    _loadWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) {
        w.complete(ad);
      }
    }
  }

  /// Skips showing an ad on the very first game play, marks it as played,
  /// and shows an App Open Ad on subsequent level selections before gameplay.
  Future<void> showBeforeLevelStartIfEligible() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPlayedFirst = prefs.getBool(_hasPlayedFirstGameKey) ?? false;

    if (!hasPlayedFirst) {
      await prefs.setBool(_hasPlayedFirstGameKey, true);
      preloadAd();
      return;
    }

    if (!_isSupportedPlatform || _isShowing) return;

    AppOpenAd? ad = _isAdAvailable ? _appOpenAd : null;
    _appOpenAd = null;
    _adLoadTime = null;

    ad ??= await _loadAd();
    if (ad == null) {
      preloadAd();
      return;
    }

    if (_appOpenAd == ad) {
      _appOpenAd = null;
      _adLoadTime = null;
    }

    _isShowing = true;
    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        _isShowing = false;
        shownAd.dispose();
        if (!completer.isCompleted) completer.complete();
        preloadAd();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        debugPrint('AppOpenAd failed to show: $error');
        _isShowing = false;
        shownAd.dispose();
        if (!completer.isCompleted) completer.complete();
        preloadAd();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('AppOpenAd show exception: $e');
      _isShowing = false;
      ad.dispose();
      if (!completer.isCompleted) completer.complete();
      preloadAd();
    }

    await completer.future;
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _adLoadTime = null;
    _completeWaiters(null);
  }
}
