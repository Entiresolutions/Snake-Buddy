import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameDifficulty { easy, normal, hard }

enum ControlType { swipe, buttons }

class SettingsController extends ChangeNotifier {
  static const _soundKey = 'settings.sound';
  static const _vibrationKey = 'settings.vibration';
  static const _difficultyKey = 'settings.difficulty';
  static const _controlsKey = 'settings.controls';
  static const _gridKey = 'settings.grid';
  static const _highScoreKey = 'game.highScore';

  late SharedPreferences _preferences;

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool showGridLines = true;
  GameDifficulty difficulty = GameDifficulty.normal;
  ControlType controls = ControlType.swipe;
  int highScore = 0;

  Duration get tickDuration {
    switch (difficulty) {
      case GameDifficulty.easy:
        return const Duration(milliseconds: 300);
      case GameDifficulty.normal:
        return const Duration(milliseconds: 240);
      case GameDifficulty.hard:
        return const Duration(milliseconds: 160);
    }
  }

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    soundEnabled = _preferences.getBool(_soundKey) ?? true;
    vibrationEnabled = _preferences.getBool(_vibrationKey) ?? true;
    showGridLines = _preferences.getBool(_gridKey) ?? true;
    highScore = _preferences.getInt(_highScoreKey) ?? 0;

    final savedDifficulty = _preferences.getString(_difficultyKey);
    difficulty = GameDifficulty.values.firstWhere(
      (value) => value.name == savedDifficulty,
      orElse: () => GameDifficulty.normal,
    );
    final savedControls = _preferences.getString(_controlsKey);
    controls = ControlType.values.firstWhere(
      (value) => value.name == savedControls,
      orElse: () => ControlType.swipe,
    );
  }

  Future<void> setSoundEnabled(bool value) async {
    await _saveBool(_soundKey, value);
    soundEnabled = value;
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _saveBool(_vibrationKey, value);
    vibrationEnabled = value;
    notifyListeners();
  }

  Future<void> setShowGridLines(bool value) async {
    await _saveBool(_gridKey, value);
    showGridLines = value;
    notifyListeners();
  }

  Future<void> setDifficulty(GameDifficulty value) async {
    if (!await _preferences.setString(_difficultyKey, value.name)) {
      throw StateError('Could not save game difficulty.');
    }
    difficulty = value;
    notifyListeners();
  }

  Future<void> setControls(ControlType value) async {
    if (!await _preferences.setString(_controlsKey, value.name)) {
      throw StateError('Could not save control type.');
    }
    controls = value;
    notifyListeners();
  }

  Future<void> recordHighScore(int score) async {
    if (score <= highScore) return;
    if (!await _preferences.setInt(_highScoreKey, score)) {
      throw StateError('Could not save high score.');
    }
    highScore = score;
    notifyListeners();
  }

  Future<void> resetHighScore() async {
    if (!await _preferences.setInt(_highScoreKey, 0)) {
      throw StateError('Could not reset high score.');
    }
    highScore = 0;
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    if (!await _preferences.setBool(key, value)) {
      throw StateError('Could not save setting "$key".');
    }
  }
}
