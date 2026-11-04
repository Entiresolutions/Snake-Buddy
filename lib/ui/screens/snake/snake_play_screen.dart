// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/theme/canvas_themes.dart';
import 'package:snake_game/widgets/game_control_button.dart';
import 'package:snake_game/widgets/primary_button.dart';
import 'package:snake_game/widgets/responsive.dart';
import 'package:snake_game/widgets/responsive_scaffold.dart';
import 'package:snake_game/widgets/secondary_button.dart';
import 'package:snake_game/widgets/stat_chip.dart';

/// ===== Food definitions =====
enum FoodType { red, blue, purple, yellow }

int foodPoints(FoodType t) {
  switch (t) {
    case FoodType.red:
      return 1; // apple
    case FoodType.blue:
      return 2; // blueberry
    case FoodType.purple:
      return 3; // grape
    case FoodType.yellow:
      return 5; // banana
  }
}

String foodAsset(FoodType t) {
  switch (t) {
    case FoodType.red:
      return 'assets/images/apple.png';
    case FoodType.blue:
      return 'assets/images/blueberry.png';
    case FoodType.purple:
      return 'assets/images/grape.png';
    case FoodType.yellow:
      return 'assets/images/banana.png';
  }
}

Color foodHaloColor(FoodType t) {
  switch (t) {
    case FoodType.red:
      return AppColors.foodAppleHalo;
    case FoodType.blue:
      return AppColors.foodBlueberryHalo;
    case FoodType.purple:
      return AppColors.foodGrapeHalo;
    case FoodType.yellow:
      return AppColors.foodBananaHalo;
  }
}

class Food {
  final int x, y;
  final FoodType type;
  const Food(this.x, this.y, this.type);
}

class SnakePlayScreen extends StatefulWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;

  SnakePlayScreen({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
  }) : canvasThemes = canvasThemes ?? CanvasThemeController();

  @override
  State<SnakePlayScreen> createState() => _SnakePlayScreenState();
}

class _SnakePlayScreenState extends State<SnakePlayScreen>
    with TickerProviderStateMixin {
  // ===== Board size: 20 rows x 15 cols =====
  final int rows = Responsive.boardRows; // 20
  final int cols = Responsive.boardCols; // 15

  // Assets (14 sprite ClearCode)
  static const String _kSnakeDir = 'assets/sprites/clearcode/';

  // Game state (grid coords, head at index 0)
  List<List<int>> snake = [
    [7, 9],
    [7, 10],
    [7, 11],
  ];
  List<int> segIds = [0, 1, 2];
  int _nextId = 3;

  late Food food;

  String direction = 'up';
  String nextDirection = 'up';

  int score = 0;
  int pendingGrowth = 0;

  // Track canvases unlocked in this round for celebratory GameOver presentation
  final List<CanvasTheme> _unlockedThisRound = [];
  String? _unlockBannerText;
  Timer? _unlockBannerTimer;

  // Timing for logic and segment tweens
  Duration get tick => widget.settings.tickDuration;
  late Duration _activeTick;
  Timer? _logicTimer;

  // Controls
  final FocusNode _focusNode = FocusNode();
  bool isPlaying = false;
  bool _hasStarted = false;
  bool _gameHasEnded = false;

  // Hit star animation state
  bool _showHitStars = false;
  late final AnimationController _hitStarCtrl;
  late final Animation<double> _hitStarSpin;
  late final Animation<double> _hitStarScale;

  // Audio
  late final AudioPlayer _sfxEat, _sfxStart, _sfxOver;

  // Random
  final randomGen = Random();

  // Pulsing animation for fruit (2s, 1.0 -> 1.15)
  late final AnimationController _foodCtrl;
  late final Animation<double> _foodScale;

  @override
  void initState() {
    super.initState();
    _activeTick = tick;
    widget.settings.addListener(_onSettingsChanged);

    // Initial food
    food = const Food(7, 13, FoodType.red);
    _createFoodSafe();

    // Audio
    _sfxEat = AudioPlayer()..setVolume(0.8);
    _sfxStart = AudioPlayer()..setVolume(0.9);
    _sfxOver = AudioPlayer()..setVolume(1.0);

    // Hit star animation controller (cartoon star burst / dizzy spin)
    _hitStarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _hitStarSpin = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _hitStarCtrl, curve: Curves.easeOutCubic),
    );
    _hitStarScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(_hitStarCtrl);

    // Precache sprites
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final p in [
        'head_up.png',
        'head_down.png',
        'head_left.png',
        'head_right.png',
        'tail_up.png',
        'tail_down.png',
        'tail_left.png',
        'tail_right.png',
        'body_horizontal.png',
        'body_vertical.png',
        'body_topleft.png',
        'body_topright.png',
        'body_bottomleft.png',
        'body_bottomright.png',
      ]) {
        precacheImage(AssetImage('$_kSnakeDir$p'), context);
      }
      if (mounted) startGame();
    });

    _foodCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _foodScale = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _foodCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _logicTimer?.cancel();
    _unlockBannerTimer?.cancel();
    _foodCtrl.dispose();
    _hitStarCtrl.dispose();
    _focusNode.dispose();
    _sfxEat.dispose();
    _sfxStart.dispose();
    _sfxOver.dispose();
    super.dispose();
  }

  void _showUnlockBanner(String name) {
    _unlockBannerTimer?.cancel();
    setState(() {
      _unlockBannerText = 'New canvas unlocked: $name';
    });
    _unlockBannerTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _unlockBannerText = null;
        });
      }
    });
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final nextTick = tick;
    if (isPlaying && nextTick != _activeTick) {
      _logicTimer?.cancel();
      _activeTick = nextTick;
      _logicTimer = Timer.periodic(tick, (_) => _stepLogicOnce());
    }
    setState(() {});
  }

  // ===== Logic helpers =====
  bool _isOpposite(String a, String b) =>
      (a == 'up' && b == 'down') ||
      (a == 'down' && b == 'up') ||
      (a == 'left' && b == 'right') ||
      (a == 'right' && b == 'left');

  void _setNextDirection(String dir) {
    if (dir == direction || _isOpposite(direction, dir)) return;
    nextDirection = dir;
  }

  void _onKey(RawKeyEvent e) {
    if (e is! RawKeyDownEvent) return;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      _setNextDirection('up');
    } else if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.keyS) {
      _setNextDirection('down');
    } else if (k == LogicalKeyboardKey.arrowLeft ||
        k == LogicalKeyboardKey.keyA) {
      _setNextDirection('left');
    } else if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.keyD) {
      _setNextDirection('right');
    } else if (k == LogicalKeyboardKey.space) {
      isPlaying ? _showPauseMenu() : startGame();
    } else if (k == LogicalKeyboardKey.keyR) {
      startGame();
    }
  }

  // ===== Start / Pause / End =====
  void startGame() {
    _logicTimer?.cancel();
    _unlockedThisRound.clear();
    _unlockBannerTimer?.cancel();
    _unlockBannerText = null;
    setState(() {
      final cx = cols ~/ 2; // 7
      final cy = rows ~/ 2; // 10
      snake = [
        [cx, cy - 1], // head facing up
        [cx, cy], // body
        [cx, cy + 1], // tail
      ];
      segIds = [0, 1, 2];
      _nextId = 3;

      direction = 'up';
      nextDirection = 'up';
      score = 0;
      pendingGrowth = 0;
      isPlaying = true;
      _hasStarted = true;
      _gameHasEnded = false;
      _showHitStars = false;

      _createFoodSafe();
    });

    _hitStarCtrl.reset();
    _activeTick = tick;
    _logicTimer = Timer.periodic(tick, (_) => _stepLogicOnce());
    if (widget.settings.soundEnabled) _playStart();
    if (widget.settings.vibrationEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void _pauseGame() {
    setState(() => isPlaying = false);
    _logicTimer?.cancel();
  }

  void _resumeGame() {
    setState(() => isPlaying = true);
    _activeTick = tick;
    _logicTimer?.cancel();
    _logicTimer = Timer.periodic(tick, (_) => _stepLogicOnce());
  }

  void _showPauseMenu() {
    _pauseGame();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Game Paused',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StatChip(
                label: 'Current Score',
                value: '$score',
                icon: const Icon(
                  Icons.circle,
                  size: 10,
                  color: AppColors.foodApple,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'RESUME',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _resumeGame();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'HOME',
                  icon: Icons.home_outlined,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _goHome();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome() {
    _logicTimer?.cancel();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _endGame() {
    setState(() {
      isPlaying = false;
      _showHitStars = true;
    });
    _logicTimer?.cancel();
    if (widget.settings.soundEnabled) _playOver();
    if (widget.settings.vibrationEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }
    _gameHasEnded = true;
    _hitStarCtrl.forward(from: 0.0);
    final isNewBest = score > widget.settings.highScore;
    unawaited(widget.settings.recordHighScore(score));

    // Show Game Over dialog after brief star hit animation
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || !_gameHasEnded) return;
      _showGameOverDialog(isNewBest);
    });
  }

  void _showGameOverDialog(bool isNewBest) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isNewBest ? AppColors.primarySoft : AppColors.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNewBest ? Icons.emoji_events_rounded : Icons.replay_rounded,
                  color: isNewBest ? AppColors.primaryDeep : AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isNewBest ? 'New High Score!' : 'Game Over',
                style: AppTextStyles.displaySmall.copyWith(
                  color: isNewBest ? AppColors.primaryDeep : AppColors.danger,
                ),
              ),
              if (isNewBest) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentLime,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    'NEW BEST!',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatChip(
                    label: 'Score',
                    value: '$score',
                    icon: const Icon(
                      Icons.circle,
                      size: 10,
                      color: AppColors.foodApple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  StatChip(
                    label: 'Best',
                    value: '${max(score, widget.settings.highScore)}',
                    icon: const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.foodBananaText,
                    ),
                  ),
                ],
              ),
              if (_unlockedThisRound.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final unlockedTheme in _unlockedThisRound)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: AppColors.accentLime,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            unlockedTheme.boardLight,
                            unlockedTheme.boardFrame,
                            unlockedTheme.snakePreviewColor,
                          ].map((c) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Canvas unlocked!',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primaryDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                unlockedTheme.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatefulBuilder(
                          builder: (context, setDialogState) {
                            final isCurrent = widget.canvasThemes
                                    .selectedThemeId ==
                                unlockedTheme.id;
                            return TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                              ),
                              onPressed: isCurrent
                                  ? null
                                  : () async {
                                      await widget.canvasThemes
                                          .selectTheme(unlockedTheme.id);
                                      setState(() {});
                                      setDialogState(() {});
                                    },
                              child: Text(
                                isCurrent ? 'ACTIVE' : 'USE NOW',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isCurrent
                                      ? AppColors.textMuted
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'PLAY AGAIN',
                  icon: Icons.replay_rounded,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    startGame();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'HOME',
                  icon: Icons.home_outlined,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _goHome();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== One logic step =====
  void _stepLogicOnce() {
    if (!mounted || !isPlaying) return;

    direction = nextDirection;

    final head = snake.first;
    late List<int> newHead;
    switch (direction) {
      case 'up':
        newHead = [head[0], head[1] - 1];
        break;
      case 'down':
        newHead = [head[0], head[1] + 1];
        break;
      case 'left':
        newHead = [head[0] - 1, head[1]];
        break;
      case 'right':
        newHead = [head[0] + 1, head[1]];
        break;
    }

    setState(() {
      snake.insert(0, newHead);
      segIds.insert(0, _nextId++);
    });

    final ate = (newHead[0] == food.x && newHead[1] == food.y);
    if (ate) {
      score += foodPoints(food.type);
      pendingGrowth += 1;
      if (widget.settings.soundEnabled) _playEat();
      if (widget.settings.vibrationEnabled) {
        unawaited(HapticFeedback.selectionClick());
      }
      _createFoodSafe();

      final newlyUnlocked = widget.canvasThemes.checkUnlock(score);
      if (newlyUnlocked.isNotEmpty) {
        for (final t in newlyUnlocked) {
          if (!_unlockedThisRound.any((u) => u.id == t.id)) {
            _unlockedThisRound.add(t);
          }
          _showUnlockBanner(t.name);
        }
      }
    }

    if (pendingGrowth > 0) {
      pendingGrowth -= 1;
    } else {
      setState(() {
        snake.removeLast();
        segIds.removeLast();
      });
    }

    if (_checkGameOverNow()) _endGame();
  }

  bool _checkGameOverNow() {
    final hx = snake.first[0], hy = snake.first[1];
    if (hx < 0 || hx >= cols || hy < 0 || hy >= rows) return true;
    for (int i = 1; i < snake.length; i++) {
      if (snake[i][0] == hx && snake[i][1] == hy) return true;
    }
    return false;
  }

  // ===== Food =====
  FoodType _rollFoodType() {
    final r = randomGen.nextDouble();
    if (r < 0.60) return FoodType.red;
    if (r < 0.90) return FoodType.blue;
    if (r < 0.98) return FoodType.purple;
    return FoodType.yellow;
  }

  void _createFoodSafe() {
    while (true) {
      final x = randomGen.nextInt(cols);
      final y = randomGen.nextInt(rows);
      final overlaps = snake.any((p) => p[0] == x && p[1] == y);
      if (!overlaps) {
        food = Food(x, y, _rollFoodType());
        break;
      }
    }
  }

  // ===== Audio =====
  Future<void> _playStart() async {
    try {
      await _sfxStart.play(AssetSource('sfx/start.mp3'));
    } catch (_) {}
  }

  Future<void> _playEat() async {
    try {
      await _sfxEat.play(AssetSource('sfx/eat.mp3'));
    } catch (_) {}
  }

  Future<void> _playOver() async {
    try {
      await _sfxOver.play(AssetSource('sfx/over.mp3'));
    } catch (_) {}
  }

  // ===== Sprite mapping =====
  bool _eq(List<int> a, List<int> b) => a[0] == b[0] && a[1] == b[1];

  String _headPath(List<int> head, List<int> neck) {
    final dx = head[0] - neck[0], dy = head[1] - neck[1];
    if (dx == 1 && dy == 0) return '${_kSnakeDir}head_right.png';
    if (dx == -1 && dy == 0) return '${_kSnakeDir}head_left.png';
    if (dx == 0 && dy == -1) return '${_kSnakeDir}head_up.png';
    return '${_kSnakeDir}head_down.png';
  }

  String _tailPath(List<int> beforeTail, List<int> tail) {
    final dx = tail[0] - beforeTail[0], dy = tail[1] - beforeTail[1];
    if (dx == 1 && dy == 0) return '${_kSnakeDir}tail_right.png';
    if (dx == -1 && dy == 0) return '${_kSnakeDir}tail_left.png';
    if (dx == 0 && dy == 1) return '${_kSnakeDir}tail_down.png';
    return '${_kSnakeDir}tail_up.png';
  }

  String _bodyPath(List<int> prev, List<int> cur, List<int> next) {
    if (prev[1] == cur[1] && next[1] == cur[1]) {
      return '${_kSnakeDir}body_horizontal.png';
    }
    if (prev[0] == cur[0] && next[0] == cur[0]) {
      return '${_kSnakeDir}body_vertical.png';
    }

    final hasUp =
        (_eq(prev, [cur[0], cur[1] - 1]) || _eq(next, [cur[0], cur[1] - 1]));
    final hasDown =
        (_eq(prev, [cur[0], cur[1] + 1]) || _eq(next, [cur[0], cur[1] + 1]));
    final hasLeft =
        (_eq(prev, [cur[0] - 1, cur[1]]) || _eq(next, [cur[0] - 1, cur[1]]));
    final hasRight =
        (_eq(prev, [cur[0] + 1, cur[1]]) || _eq(next, [cur[0] + 1, cur[1]]));

    if (hasUp && hasRight) return '${_kSnakeDir}body_topright.png';
    if (hasUp && hasLeft) return '${_kSnakeDir}body_topleft.png';
    if (hasDown && hasLeft) return '${_kSnakeDir}body_bottomleft.png';
    return '${_kSnakeDir}body_bottomright.png';
  }

  String _bodyForTwo(List<int> head, List<int> body) {
    final dx = head[0] - body[0];
    if (dx != 0) return '${_kSnakeDir}body_horizontal.png';
    return '${_kSnakeDir}body_vertical.png';
  }

  // ===== UI Build =====
  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);

    return AnimatedBuilder(
      animation: widget.canvasThemes,
      builder: (context, child) {
        final activeTheme = widget.canvasThemes.selectedTheme;
        final backdropColor = Color.alphaBlend(
          activeTheme.boardFrame.withOpacity(0.04),
          AppColors.background,
        );

        return RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: _onKey,
          child: ResponsiveScaffold(
            centerContent: false,
            backgroundColor: backdropColor,
            appBar: AppBar(
              backgroundColor: backdropColor,
              leading: IconButton(
                tooltip: 'Home',
                onPressed: _goHome,
                icon: const Icon(Icons.home_outlined),
              ),
              title: const Text('SNAKE'),
              actions: [
                IconButton(
                  tooltip: isPlaying ? 'Pause' : 'Resume',
                  onPressed: isPlaying
                      ? _showPauseMenu
                      : (_hasStarted && !_gameHasEnded
                          ? _resumeGame
                          : startGame),
                  icon: Icon(isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                ),
              ],
            ),
            body: isLandscape
                ? _buildLandscapeLayout()
                : _buildPortraitLayout(),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // HUD Row (Score & Best)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatChip(
                    label: 'Score',
                    value: '$score',
                    icon: const Icon(
                      Icons.circle,
                      size: 10,
                      color: AppColors.foodApple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StatChip(
                    label: 'Best',
                    value: '${widget.settings.highScore}',
                    icon: const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.foodBananaText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Board Area
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell = Responsive.calculateCellSize(
                  availableWidth: constraints.maxWidth - AppSpacing.lg,
                  availableHeight: constraints.maxHeight - AppSpacing.sm,
                  cols: cols,
                  rows: rows,
                );
                final boardW = cols * cell;
                final boardH = rows * cell;

                return _buildBoard(cell, boardW, boardH);
              },
            ),
          ),
        ),

        // Bottom Controls (No restart button)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (widget.settings.controls == ControlType.buttons) {
                return _buildDpad(isCompact: false);
              }
              // Swipe controls hint (without restart button)
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swipe_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Swipe to steer',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Board on left
        Expanded(
          flex: 6,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell = Responsive.calculateCellSize(
                  availableWidth: constraints.maxWidth - AppSpacing.lg,
                  availableHeight: constraints.maxHeight - AppSpacing.md,
                  cols: cols,
                  rows: rows,
                );
                final boardW = cols * cell;
                final boardH = rows * cell;

                return _buildBoard(cell, boardW, boardH);
              },
            ),
          ),
        ),

        // Side panel on right (No restart button)
        Container(width: 1.5, color: AppColors.border),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatChip(
                    label: 'Score',
                    value: '$score',
                    icon: const Icon(
                      Icons.circle,
                      size: 10,
                      color: AppColors.foodApple,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatChip(
                    label: 'Best',
                    value: '${widget.settings.highScore}',
                    icon: const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.foodBananaText,
                    ),
                  ),
                  if (widget.settings.controls == ControlType.buttons) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildDpad(isCompact: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard(double cell, double boardW, double boardH) {
    final activeTheme = widget.canvasThemes.selectedTheme;

    Widget snakeLayer = Stack(
      children: _buildSnakeWidgets(cell),
    );
    if (activeTheme.snakeColorFilter != null) {
      snakeLayer = ColorFiltered(
        colorFilter: activeTheme.snakeColorFilter!,
        child: snakeLayer,
      );
    }

    return SizedBox(
      width: boardW,
      height: boardH,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        onVerticalDragUpdate: widget.settings.controls == ControlType.swipe
            ? (details) {
                if (details.delta.dy > 5) {
                  _setNextDirection('down');
                } else if (details.delta.dy < -5) {
                  _setNextDirection('up');
                }
              }
            : null,
        onHorizontalDragUpdate: widget.settings.controls == ControlType.swipe
            ? (details) {
                if (details.delta.dx > 5) {
                  _setNextDirection('right');
                } else if (details.delta.dx < -5) {
                  _setNextDirection('left');
                }
              }
            : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: activeTheme.boardLight,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: activeTheme.boardFrame,
              width: 4.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowElevated,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md - 3),
            child: Stack(
              children: [
                // Two-tone checkerboard + subtle grid lines + canvas border
                CustomPaint(
                  size: Size(boardW, boardH),
                  painter: _CheckerboardPainter(
                    rows: rows,
                    cols: cols,
                    cell: cell,
                    showGridLines: widget.settings.showGridLines,
                    boardLight: activeTheme.boardLight,
                    boardDark: activeTheme.boardDark,
                    boardFrame: activeTheme.boardFrame,
                    boardGrid: activeTheme.boardGrid,
                  ),
                ),

                // Pulsing fruit with soft ground halo
                AnimatedPositioned(
                  left: food.x * cell,
                  top: food.y * cell,
                  width: cell,
                  height: cell,
                  duration: tick,
                  curve: Curves.linear,
                  child: Center(
                    child: ScaleTransition(
                      scale: _foodScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: cell * 0.75,
                            height: cell * 0.75,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: foodHaloColor(food.type)
                                      .withOpacity(activeTheme.haloOpacity),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            foodAsset(food.type),
                            width: cell,
                            height: cell,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Snake segments with AnimatedPositioned tween wrapped in ColorFiltered
                Positioned.fill(child: snakeLayer),

                // Star animation around snake head when hit occurs
                if (_showHitStars) _buildHitStars(cell),

                // Floating non-blocking unlock banner pill at top of board
                if (_unlockBannerText != null)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IgnorePointer(
                        child: _buildBannerPill(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: AppRadius.pillRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.palette_rounded,
            size: 16,
            color: AppColors.accentLime,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _unlockBannerText ?? '',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHitStars(double cell) {
    if (snake.isEmpty) return const SizedBox.shrink();
    final head = snake.first;
    final hx = head[0].clamp(0, cols - 1);
    final hy = head[1].clamp(0, rows - 1);
    final cx = (hx + 0.5) * cell;
    final cy = (hy + 0.5) * cell;
    final orbitRadius = cell * 0.75;
    final starSize = cell * 0.55;

    return AnimatedBuilder(
      animation: _hitStarCtrl,
      builder: (context, child) {
        final spin = _hitStarSpin.value;
        final scale = _hitStarScale.value;

        return Stack(
          children: [
            for (int i = 0; i < 4; i++) ...[
              () {
                final angle = spin + (i * pi / 2);
                final x = cx + cos(angle) * orbitRadius - starSize / 2;
                final y = cy + sin(angle) * (orbitRadius * 0.6) - starSize / 2;
                return Positioned(
                  left: x,
                  top: y,
                  width: starSize,
                  height: starSize,
                  child: Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: -spin * 1.5,
                      child: Icon(
                        Icons.star_rounded,
                        color: const Color(0xFFFFB300),
                        size: starSize,
                        shadows: const [
                          Shadow(
                            color: Color(0x99FF8F00),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDpad({required bool isCompact}) {
    if (isCompact) {
      // Single compact inline row
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameControlButton(
            icon: Icons.keyboard_arrow_left_rounded,
            semanticsLabel: 'Move Left',
            size: 48,
            onPressed: () => _setNextDirection('left'),
          ),
          const SizedBox(width: AppSpacing.xs),
          GameControlButton(
            icon: Icons.keyboard_arrow_up_rounded,
            semanticsLabel: 'Move Up',
            size: 48,
            onPressed: () => _setNextDirection('up'),
          ),
          const SizedBox(width: AppSpacing.xs),
          GameControlButton(
            icon: Icons.keyboard_arrow_down_rounded,
            semanticsLabel: 'Move Down',
            size: 48,
            onPressed: () => _setNextDirection('down'),
          ),
          const SizedBox(width: AppSpacing.xs),
          GameControlButton(
            icon: Icons.keyboard_arrow_right_rounded,
            semanticsLabel: 'Move Right',
            size: 48,
            onPressed: () => _setNextDirection('right'),
          ),
        ],
      );
    }

    // Classic Cross D-pad for portrait with adequate height
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameControlButton(
          icon: Icons.keyboard_arrow_up_rounded,
          semanticsLabel: 'Move Up',
          size: 52,
          onPressed: () => _setNextDirection('up'),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GameControlButton(
              icon: Icons.keyboard_arrow_left_rounded,
              semanticsLabel: 'Move Left',
              size: 52,
              onPressed: () => _setNextDirection('left'),
            ),
            const SizedBox(width: 4),
            GameControlButton(
              icon: Icons.keyboard_arrow_down_rounded,
              semanticsLabel: 'Move Down',
              size: 52,
              onPressed: () => _setNextDirection('down'),
            ),
            const SizedBox(width: 4),
            GameControlButton(
              icon: Icons.keyboard_arrow_right_rounded,
              semanticsLabel: 'Move Right',
              size: 52,
              onPressed: () => _setNextDirection('right'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildSnakeWidgets(double cell) {
    final w = <Widget>[];
    for (int i = 0; i < snake.length; i++) {
      final seg = snake[i];
      final id = segIds[i];

      late String path;
      if (i == 0) {
        if (snake.length >= 2) {
          path = _headPath(snake[0], snake[1]);
        } else {
          path = '${_kSnakeDir}head_up.png';
        }
      } else if (snake.length == 2 && i == 1) {
        path = _bodyForTwo(snake[0], snake[1]);
      } else if (i == snake.length - 1 && snake.length >= 3) {
        path = _tailPath(snake[i - 1], snake[i]);
      } else {
        path = _bodyPath(snake[i - 1], snake[i], snake[i + 1]);
      }

      w.add(
        AnimatedPositioned(
          key: ValueKey('seg_$id'),
          left: seg[0] * cell,
          top: seg[1] * cell,
          width: cell,
          height: cell,
          duration: tick,
          curve: Curves.easeInOut,
          child: Image.asset(
            path,
            width: cell,
            height: cell,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }
    return w;
  }
}

/// Two-tone checkerboard painter + subtle grid lines + canvas border
class _CheckerboardPainter extends CustomPainter {
  final int rows, cols;
  final double cell;
  final bool showGridLines;
  final Color boardLight;
  final Color boardDark;
  final Color boardFrame;
  final Color boardGrid;

  _CheckerboardPainter({
    required this.rows,
    required this.cols,
    required this.cell,
    required this.showGridLines,
    required this.boardLight,
    required this.boardDark,
    required this.boardFrame,
    required this.boardGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = boardLight;
    final dark = Paint()..color = boardDark;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final fill = ((r + c) % 2 == 0) ? light : dark;
        canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), fill);
      }
    }

    if (showGridLines) {
      final grid = Paint()
        ..color = boardGrid
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      for (int c = 1; c < cols; c++) {
        final x = c * cell;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (int r = 1; r < rows; r++) {
        final y = r * cell;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    // Canvas border stroke
    final borderPaint = Paint()
      ..color = boardFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter old) =>
      old.rows != rows ||
      old.cols != cols ||
      old.cell != cell ||
      old.showGridLines != showGridLines ||
      old.boardLight != boardLight ||
      old.boardDark != boardDark ||
      old.boardFrame != boardFrame ||
      old.boardGrid != boardGrid;
}
