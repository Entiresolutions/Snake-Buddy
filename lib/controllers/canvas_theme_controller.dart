import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/theme/canvas_themes.dart';

/// Manages active canvas selection, progressive unlocks, and persistence.
class CanvasThemeController extends ChangeNotifier {
  static const _selectedKey = 'canvas.selectedTheme';
  static const _unlockedKey = 'canvas.unlockedThemes';
  static const _viewedKey = 'canvas.viewedThemes';
  static const _adWatchCountsKey = 'canvas.adWatchCounts';

  SharedPreferences? _preferences;

  String _selectedThemeId = 'meadow';
  Set<String> _unlockedIds = {'meadow'};
  Set<String> _viewedIds = {'meadow'};
  Map<String, int>? _adWatchCounts = {};

  String get selectedThemeId => _selectedThemeId;
  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);
  Set<String> get viewedIds => Set.unmodifiable(_viewedIds);

  int get unlockedCount => _unlockedIds.length;
  int get totalCount => kCanvasThemes.length;

  CanvasTheme get selectedTheme {
    return kCanvasThemes.firstWhere(
      (t) => t.id == _selectedThemeId,
      orElse: () => kCanvasThemes.first,
    );
  }

  bool isUnlocked(String themeId) => _unlockedIds.contains(themeId);

  int getAdWatchCount(String themeId) =>
      (_adWatchCounts ?? const {})[themeId] ?? 0;

  bool isNew(String themeId) {
    return _unlockedIds.contains(themeId) && !_viewedIds.contains(themeId);
  }

  bool get hasNewThemes => _unlockedIds.any((id) => !_viewedIds.contains(id));

  Future<void> load({int highScore = 0}) async {
    _preferences ??= await SharedPreferences.getInstance();

    final savedUnlocked = _preferences?.getStringList(_unlockedKey);
    if (savedUnlocked != null && savedUnlocked.isNotEmpty) {
      _unlockedIds = savedUnlocked.toSet();
    } else {
      _unlockedIds = {'meadow'};
    }
    _unlockedIds.add('meadow');

    // Migration rule: unlock any canvas whose unlockScore <= highScore
    for (final theme in kCanvasThemes) {
      if (highScore >= theme.unlockScore) {
        _unlockedIds.add(theme.id);
      }
    }
    await _preferences?.setStringList(_unlockedKey, _unlockedIds.toList());

    final savedViewed = _preferences?.getStringList(_viewedKey);
    if (savedViewed != null) {
      _viewedIds = savedViewed.toSet();
    } else {
      _viewedIds = {'meadow'};
    }
    _viewedIds.add('meadow');

    final savedAdCounts = _preferences?.getStringList(_adWatchCountsKey);
    final loadedCounts = <String, int>{};
    if (savedAdCounts != null) {
      for (final entry in savedAdCounts) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final count = int.tryParse(parts[1]) ?? 0;
          if (count > 0) {
            loadedCounts[parts[0]] = count;
          }
        }
      }
    }
    _adWatchCounts = loadedCounts;

    final savedSelected = _preferences?.getString(_selectedKey) ?? 'meadow';
    if (_unlockedIds.contains(savedSelected) &&
        kCanvasThemes.any((t) => t.id == savedSelected)) {
      _selectedThemeId = savedSelected;
    } else {
      _selectedThemeId = 'meadow';
      await _preferences?.setString(_selectedKey, 'meadow');
    }

    notifyListeners();
  }

  /// Selects an unlocked canvas theme. Returns false if theme is locked or invalid.
  Future<bool> selectTheme(String themeId) async {
    if (!_unlockedIds.contains(themeId)) {
      return false; // Guard: selecting a locked canvas is rejected.
    }
    final themeExists = kCanvasThemes.any((t) => t.id == themeId);
    if (!themeExists) {
      return false;
    }

    _selectedThemeId = themeId;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setString(_selectedKey, themeId);
    notifyListeners();
    return true;
  }

  /// Marks all currently unlocked canvases as viewed (clearing the NEW badge).
  Future<void> markAllAsViewed() async {
    bool changed = false;
    for (final id in _unlockedIds) {
      if (_viewedIds.add(id)) {
        changed = true;
      }
    }
    if (changed) {
      _preferences ??= await SharedPreferences.getInstance();
      await _preferences?.setStringList(_viewedKey, _viewedIds.toList());
      notifyListeners();
    }
  }

  /// Evaluates score against unlock thresholds.
  /// Unlocks any eligible canvas immediately, persists the list, and returns newly unlocked themes.
  List<CanvasTheme> checkUnlock(int currentScore) {
    final newlyUnlocked = <CanvasTheme>[];
    for (final theme in kCanvasThemes) {
      if (!_unlockedIds.contains(theme.id) &&
          currentScore >= theme.unlockScore) {
        _unlockedIds.add(theme.id);
        newlyUnlocked.add(theme);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _preferences?.setStringList(_unlockedKey, _unlockedIds.toList());
      notifyListeners();
    }

    return newlyUnlocked;
  }

  /// Records a completed rewarded ad watch for [themeId].
  /// Returns `true` if the theme reached its required ad count and is now unlocked.
  Future<bool> recordAdWatchForTheme(String themeId) async {
    final theme = kCanvasThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => kCanvasThemes.first,
    );
    if (_unlockedIds.contains(theme.id)) {
      return true;
    }

    final counts = _adWatchCounts ??= {};
    final nextCount = (counts[theme.id] ?? 0) + 1;
    counts[theme.id] = nextCount;

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setStringList(
      _adWatchCountsKey,
      counts.entries.map((e) => '${e.key}:${e.value}').toList(),
    );

    bool unlockedNow = false;
    if (theme.unlockAdsRequired > 0 && nextCount >= theme.unlockAdsRequired) {
      _unlockedIds.add(theme.id);
      await _preferences?.setStringList(_unlockedKey, _unlockedIds.toList());
      unlockedNow = true;
    }

    notifyListeners();
    return unlockedNow;
  }

  /// Unlocks all canvas themes for testing.
  Future<void> unlockAllThemesForTesting() async {
    for (final theme in kCanvasThemes) {
      _unlockedIds.add(theme.id);
    }
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setStringList(_unlockedKey, _unlockedIds.toList());
    notifyListeners();
  }

  /// Resets unlocked canvas themes to default (Meadow only) for testing.
  Future<void> resetThemesForTesting() async {
    _unlockedIds = {'meadow'};
    _viewedIds = {'meadow'};
    _selectedThemeId = 'meadow';
    _adWatchCounts = {};
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setStringList(_unlockedKey, ['meadow']);
    await _preferences?.setStringList(_viewedKey, ['meadow']);
    await _preferences?.setString(_selectedKey, 'meadow');
    await _preferences?.setStringList(_adWatchCountsKey, []);
    notifyListeners();
  }
}
