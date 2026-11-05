import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/levels/level_catalog.dart';
import 'package:snake_game/levels/level_model.dart';

class CampaignController extends ChangeNotifier {
  static const String _highestUnlockedKey = 'levels.highestUnlocked';
  static const String _starsKey = 'levels.stars';
  static const String _highScoreKey = 'game.highScore';
  static const String _debugUnlockAllKey = 'levels.debugUnlockAll';

  SharedPreferences? _preferences;

  int highestUnlockedLevel = 1;
  final List<int> _stars = List.filled(30, 0); // 0-indexed for levels 1-30
  int currentLevelId = 1;
  int currentRunScore = 0;
  int runScoreAtLevelStart = 0;
  int bestRunScore = 0;
  int chancesUsedThisAttempt = 0;
  bool debugUnlockAll = false;

  List<int> get stars => List.unmodifiable(_stars);

  int get totalStars => _stars.fold(0, (sum, s) => sum + s);

  LevelConfig get currentLevel =>
      kLevelCatalog.firstWhere((lvl) => lvl.id == currentLevelId);

  Future<void> load({int? existingHighScore}) async {
    _preferences ??= await SharedPreferences.getInstance();
    highestUnlockedLevel =
        (_preferences?.getInt(_highestUnlockedKey) ?? 1).clamp(1, 30);
    bestRunScore = existingHighScore ??
        (_preferences?.getInt(_highScoreKey) ?? 0);
    debugUnlockAll = _preferences?.getBool(_debugUnlockAllKey) ?? false;

    final savedStars = _preferences?.getStringList(_starsKey);
    if (savedStars != null) {
      for (int i = 0; i < min(30, savedStars.length); i++) {
        final val = int.tryParse(savedStars[i]) ?? 0;
        _stars[i] = val.clamp(0, 3);
      }
    }
    notifyListeners();
  }

  bool isLevelUnlocked(int levelId) {
    if (kDebugMode && debugUnlockAll) return true;
    if (levelId < 1 || levelId > 30) return false;
    return levelId <= highestUnlockedLevel;
  }

  int getStarsForLevel(int levelId) {
    if (levelId < 1 || levelId > 30) return 0;
    return _stars[levelId - 1];
  }

  bool startLevel(int levelId, {bool resetRunScore = false}) {
    if (!isLevelUnlocked(levelId)) return false;
    currentLevelId = levelId;
    if (resetRunScore) {
      currentRunScore = 0;
    }
    runScoreAtLevelStart = currentRunScore;
    chancesUsedThisAttempt = 0;
    notifyListeners();
    return true;
  }

  void retryLevel() {
    currentRunScore = runScoreAtLevelStart;
    chancesUsedThisAttempt = 0;
    notifyListeners();
  }

  void useChance() {
    chancesUsedThisAttempt++;
    notifyListeners();
  }

  void updateRunScore(int delta) {
    currentRunScore += delta;
    if (currentRunScore > bestRunScore) {
      bestRunScore = currentRunScore;
      if (_preferences != null) {
        unawaited(_preferences!.setInt(_highScoreKey, bestRunScore));
      } else {
        SharedPreferences.getInstance().then((p) {
          _preferences = p;
          p.setInt(_highScoreKey, bestRunScore);
        });
      }
    }
    notifyListeners();
  }

  Future<int> onLevelComplete({
    required int levelId,
    required int levelScore,
  }) async {
    _preferences ??= await SharedPreferences.getInstance();
    // 3 = 0 chances used, 2 = 1 chance used, 1 = 2 chances used
    final earnedStars = (3 - chancesUsedThisAttempt).clamp(1, 3);
    final idx = (levelId - 1).clamp(0, 29);
    if (earnedStars > _stars[idx]) {
      _stars[idx] = earnedStars;
      await _preferences?.setStringList(
        _starsKey,
        _stars.map((e) => e.toString()).toList(),
      );
    }

    if (levelId < 30 && highestUnlockedLevel < levelId + 1) {
      highestUnlockedLevel = levelId + 1;
      await _preferences?.setInt(_highestUnlockedKey, highestUnlockedLevel);
    }

    if (currentRunScore > bestRunScore) {
      bestRunScore = currentRunScore;
      await _preferences?.setInt(_highScoreKey, bestRunScore);
    }

    notifyListeners();
    return earnedStars;
  }

  Future<void> setDebugUnlockAll(bool value) async {
    debugUnlockAll = value;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setBool(_debugUnlockAllKey, value);
    notifyListeners();
  }

  /// Unlocks all 30 levels for testing.
  Future<void> unlockAllLevelsForTesting() async {
    highestUnlockedLevel = 30;
    debugUnlockAll = true;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setInt(_highestUnlockedKey, 30);
    await _preferences?.setBool(_debugUnlockAllKey, true);
    notifyListeners();
  }

  Future<void> resetCampaign() async {
    highestUnlockedLevel = 1;
    for (int i = 0; i < 30; i++) {
      _stars[i] = 0;
    }
    currentLevelId = 1;
    currentRunScore = 0;
    runScoreAtLevelStart = 0;
    chancesUsedThisAttempt = 0;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setInt(_highestUnlockedKey, 1);
    await _preferences?.setStringList(
      _starsKey,
      _stars.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }
}
