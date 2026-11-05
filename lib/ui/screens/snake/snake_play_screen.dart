// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/levels/level_catalog.dart';
import 'package:snake_game/levels/level_model.dart';
import 'package:snake_game/services/chance_service.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/theme/canvas_themes.dart';
import 'package:snake_game/widgets/dialogs/game_complete_dialog.dart';
import 'package:snake_game/widgets/dialogs/game_over_dialog.dart';
import 'package:snake_game/widgets/dialogs/level_complete_dialog.dart';
import 'package:snake_game/widgets/game_control_button.dart';
import 'package:snake_game/widgets/level_intro_card.dart';
import 'package:snake_game/widgets/obstacle_painter.dart';
import 'package:snake_game/widgets/patrol_layer.dart';
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
    case FoodType.blue:
    case FoodType.purple:
      return 1;
    case FoodType.yellow:
      return 10;
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

class PatrolRuntimeState {
  final PatrolConfig config;
  final int id;
  int currentStepIndex;
  int directionSign; // 1 or -1
  List<int> previousPos;
  List<int> currentPos;
  String moveDirection;

  PatrolRuntimeState({
    required this.config,
    required this.id,
    required this.currentStepIndex,
    required this.directionSign,
    required this.previousPos,
    required this.currentPos,
    required this.moveDirection,
  });

  PatrolRuntimeState clone() {
    return PatrolRuntimeState(
      config: config,
      id: id,
      currentStepIndex: currentStepIndex,
      directionSign: directionSign,
      previousPos: List<int>.from(previousPos),
      currentPos: List<int>.from(currentPos),
      moveDirection: moveDirection,
    );
  }

  void step(int tickCount) {
    if (config.path.length <= 1) return;
    if (tickCount % config.stepEveryTicks != 0) return;

    previousPos = List<int>.from(currentPos);

    if (config.mode == PatrolMode.loop) {
      currentStepIndex = (currentStepIndex + 1) % config.path.length;
    } else {
      currentStepIndex += directionSign;
      if (currentStepIndex >= config.path.length - 1) {
        currentStepIndex = config.path.length - 1;
        directionSign = -1;
      } else if (currentStepIndex <= 0) {
        currentStepIndex = 0;
        directionSign = 1;
      }
    }

    final nextPos = config.path[currentStepIndex];
    final dx = nextPos[0] - currentPos[0];
    final dy = nextPos[1] - currentPos[1];
    if (dx > 0) {
      moveDirection = 'right';
    } else if (dx < 0) {
      moveDirection = 'left';
    } else if (dy > 0) {
      moveDirection = 'down';
    } else if (dy < 0) {
      moveDirection = 'up';
    }

    currentPos = List<int>.from(nextPos);
  }

  bool occupies(int x, int y) {
    if (currentPos[0] == x && currentPos[1] == y) return true;
    if (config.size == 2 && previousPos[0] == x && previousPos[1] == y) {
      return true;
    }
    return false;
  }

  bool swapped(List<int> headOld, List<int> headNew) {
    return (headNew[0] == previousPos[0] && headNew[1] == previousPos[1]) &&
        (currentPos[0] == headOld[0] && currentPos[1] == headOld[1]);
  }
}

class GameSnapshot {
  final List<List<int>> snake;
  final List<int> segIds;
  final List<String> segDirs;
  final String direction;
  final String nextDirection;
  final Food food;
  final Food? banana;
  final int fruitsSinceBanana;
  final int pendingGrowth;
  final int levelScore;
  final int runScore;
  final int tickCount;
  final List<PatrolRuntimeState> patrols;

  GameSnapshot({
    required this.snake,
    required this.segIds,
    required this.segDirs,
    required this.direction,
    required this.nextDirection,
    required this.food,
    this.banana,
    this.fruitsSinceBanana = 0,
    required this.pendingGrowth,
    required this.levelScore,
    required this.runScore,
    required this.tickCount,
    required this.patrols,
  });
}

class SnakePlayScreen extends StatefulWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;
  final CampaignController campaign;
  final int? initialLevelId;
  final bool showIntro;

  SnakePlayScreen({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
    CampaignController? campaign,
    this.initialLevelId,
    this.showIntro = false,
  })  : canvasThemes = canvasThemes ?? CanvasThemeController(),
        campaign = campaign ?? CampaignController();

  @override
  State<SnakePlayScreen> createState() => _SnakePlayScreenState();
}

class _SnakePlayScreenState extends State<SnakePlayScreen>
    with TickerProviderStateMixin {
  final int rows = Responsive.boardRows; // 20
  final int cols = Responsive.boardCols; // 15

  static const String _kSnakeDir = 'assets/sprites/clearcode/';

  // Campaign & Level state
  late LevelConfig currentLevel;
  final ChanceService _chanceService = ChanceService();
  bool _showingIntro = true;
  String? _countdownText;
  Timer? _countdownTimer;

  // Level hazards parsed for $O(1)$ fast lookups
  final Set<String> _rockSet = {};
  final Map<String, List<int>> _portalPartners = {};
  final List<PatrolRuntimeState> _patrols = [];
  final Map<int, SpikeState> _spikeStates = {};
  int _tickCount = 0;

  // Ring buffer for Second Chance (last 8 ticks)
  final List<GameSnapshot> _snapshotBuffer = [];

  // Game state (grid coords, head at index 0)
  List<List<int>> snake = [
    [7, 9],
    [7, 10],
    [7, 11],
  ];
  List<int> segIds = [0, 1, 2];
  List<String> segDirs = ['up', 'up', 'up'];
  int _nextId = 3;

  late Food food;
  Food? banana;
  int _fruitsSinceBanana = 0;
  Timer? _bananaTimer;
  int _bananaRemainingMs = 0;

  String direction = 'up';
  String nextDirection = 'up';

  int levelScore = 0;
  int pendingGrowth = 0;

  // Canvas unlocks
  final List<CanvasTheme> _unlockedThisRound = [];
  String? _unlockBannerText;
  Timer? _unlockBannerTimer;

  // Active tick duration calculated with speed ramp formula
  Duration get tick => Duration(
        milliseconds: LevelRules.calculateTickMs(
          _baseTickMs(widget.settings.difficulty),
          currentLevel.id,
        ),
      );
  late Duration _activeTick;
  Timer? _logicTimer;

  int _baseTickMs(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy:
        return 300;
      case GameDifficulty.normal:
        return 240;
      case GameDifficulty.hard:
        return 160;
    }
  }

  // State flags
  bool isPlaying = false;
  bool _hasStarted = false;
  bool _gameHasEnded = false;
  bool _showHitStars = false;

  // Hit star animation
  late final AnimationController _hitStarCtrl;
  late final Animation<double> _hitStarSpin;
  late final Animation<double> _hitStarScale;

  // Fruit pulse
  late final AnimationController _foodCtrl;
  late final Animation<double> _foodScale;

  // Portal swirl & Spike pulse animations
  late final AnimationController _portalCtrl;
  late final AnimationController _spikePulseCtrl;

  // Keyboard
  final FocusNode _focusNode = FocusNode();

  // Audio players
  final AudioPlayer _sfxEat = AudioPlayer();
  final AudioPlayer _sfxStart = AudioPlayer();
  final AudioPlayer _sfxOver = AudioPlayer();

  final Random randomGen = Random();

  @override
  void initState() {
    super.initState();
    final lvlId = widget.initialLevelId ?? widget.campaign.currentLevelId;
    currentLevel = kLevelCatalog.firstWhere(
      (l) => l.id == lvlId,
      orElse: () => kLevelCatalog.first,
    );

    _showingIntro = widget.showIntro;

    _initLevelHazards();
    _createRegularFoodSafe();

    widget.settings.addListener(_onSettingsChanged);

    _hitStarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _hitStarSpin = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _hitStarCtrl, curve: Curves.easeOutCubic),
    );
    _hitStarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hitStarCtrl, curve: Curves.elasticOut),
    );

    _foodCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _foodScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _foodCtrl, curve: Curves.easeInOut),
    );

    _portalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _spikePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

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
      if (!widget.showIntro && mounted) {
        startGame();
      }
    });
  }

  void _initLevelHazards() {
    _rockSet.clear();
    for (final r in currentLevel.rocks) {
      _rockSet.add('${r[0]},${r[1]}');
    }

    _portalPartners.clear();
    for (final entry in currentLevel.portals.entries) {
      final pts = entry.value;
      if (pts.length >= 2) {
        _portalPartners['${pts[0][0]},${pts[0][1]}'] = pts[1];
        _portalPartners['${pts[1][0]},${pts[1][1]}'] = pts[0];
      }
    }

    _patrols.clear();
    for (int i = 0; i < currentLevel.patrols.length; i++) {
      final pConfig = currentLevel.patrols[i];
      final startPos = pConfig.path.isNotEmpty ? pConfig.path.first : [0, 0];
      _patrols.add(
        PatrolRuntimeState(
          config: pConfig,
          id: i,
          currentStepIndex: 0,
          directionSign: 1,
          previousPos: List<int>.from(startPos),
          currentPos: List<int>.from(startPos),
          moveDirection: 'right',
        ),
      );
    }

    _updateSpikeStates();
  }

  void _updateSpikeStates() {
    _spikeStates.clear();
    for (final group in currentLevel.spikeGroups) {
      final s = group.stateAtTick(_tickCount);
      if (s == 'on') {
        _spikeStates[group.id] = SpikeState.on;
      } else if (s == 'warn') {
        _spikeStates[group.id] = SpikeState.warn;
      } else {
        _spikeStates[group.id] = SpikeState.off;
      }
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _logicTimer?.cancel();
    _countdownTimer?.cancel();
    _unlockBannerTimer?.cancel();
    _bananaTimer?.cancel();
    _foodCtrl.dispose();
    _hitStarCtrl.dispose();
    _portalCtrl.dispose();
    _spikePulseCtrl.dispose();
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

  bool _isOpposite(String a, String b) =>
      (a == 'up' && b == 'down') ||
      (a == 'down' && b == 'up') ||
      (a == 'left' && b == 'right') ||
      (a == 'right' && b == 'left');

  void _setNextDirection(String dir) {
    if (dir == direction || _isOpposite(direction, dir)) return;
    nextDirection = dir;
  }

  @visibleForTesting
  void stepLogicForTest() {
    isPlaying = true;
    _stepLogicOnce();
  }

  @visibleForTesting
  void setDirectionForTest(String d) => _setNextDirection(d);

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

  // ===== Game Lifecycle =====
  void startGame() {
    _logicTimer?.cancel();
    _countdownTimer?.cancel();
    _cancelBananaTimer();
    _fruitsSinceBanana = 0;
    _unlockedThisRound.clear();
    _unlockBannerTimer?.cancel();
    _unlockBannerText = null;
    _snapshotBuffer.clear();
    _tickCount = 0;

    _initLevelHazards();

    setState(() {
      _showingIntro = false;
      _countdownText = null;

      final cx = cols ~/ 2; // 7
      final cy = rows ~/ 2; // 10
      snake = [
        [cx, cy - 1], // [7, 9] facing up
        [cx, cy], // [7, 10]
        [cx, cy + 1], // [7, 11]
      ];
      segIds = [0, 1, 2];
      segDirs = ['up', 'up', 'up'];
      _nextId = 3;

      direction = 'up';
      nextDirection = 'up';
      levelScore = 0;
      pendingGrowth = 0;
      isPlaying = false;
      _hasStarted = true;
      _gameHasEnded = false;
      _showHitStars = false;
      banana = null;

      _createRegularFoodSafe();
    });

    _hitStarCtrl.reset();
    _startCountdownAndResume();
  }

  void _loadLevel(int levelId) {
    widget.campaign.startLevel(levelId, resetRunScore: false);
    _cancelBananaTimer();
    _fruitsSinceBanana = 0;
    setState(() {
      banana = null;
      currentLevel = kLevelCatalog.firstWhere(
        (lvl) => lvl.id == levelId,
        orElse: () => kLevelCatalog.first,
      );
      _showingIntro = true;
    });
  }

  Future<bool> _showConfirmExitDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.dangerSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        height: 46.0,
                        label: 'CANCEL',
                        onPressed: () => Navigator.pop(dialogCtx, false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        height: 46.0,
                        backgroundColor: AppColors.danger,
                        label: confirmLabel,
                        onPressed: () => Navigator.pop(dialogCtx, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  void _pauseGame() {
    _countdownTimer?.cancel();
    setState(() {
      isPlaying = false;
      _countdownText = null;
    });
    _logicTimer?.cancel();
  }

  void _showPauseMenu() {
    _pauseGame();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level ${currentLevel.id}: ${currentLevel.name}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                StatChip(
                  label: 'Score',
                  value: '$levelScore / 100',
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
                      _startCountdownAndResume();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    label: 'RESTART LEVEL',
                    icon: Icons.replay_rounded,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      widget.campaign.retryLevel();
                      startGame();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        height: 46.0,
                        label: 'LEVELS',
                        icon: Icons.grid_view_rounded,
                        borderColor: AppColors.border,
                        textColor: AppColors.primaryDeep,
                        backgroundColor: AppColors.surfaceSubtle,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        fontSize: 13,
                        semanticsLabel: 'Select level',
                        onPressed: () async {
                          final leave = await _showConfirmExitDialog(
                            title: 'Quit to Levels?',
                            message:
                                'Are you sure you want to exit to Level Select? Current level progress will be lost.',
                            confirmLabel: 'EXIT',
                          );
                          if (leave && dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            _goLevelSelect();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SecondaryButton(
                        height: 46.0,
                        label: 'HOME',
                        icon: Icons.home_rounded,
                        borderColor: AppColors.border,
                        textColor: AppColors.textSecondary,
                        backgroundColor: AppColors.surfaceSubtle,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        fontSize: 13,
                        semanticsLabel: 'Return home',
                        onPressed: () async {
                          final leave = await _showConfirmExitDialog(
                            title: 'Quit to Home?',
                            message:
                                'Are you sure you want to return to the Home screen? Current level progress will be lost.',
                            confirmLabel: 'QUIT',
                          );
                          if (leave && dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            _goHome();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goHome() {
    _cancelBananaTimer();
    banana = null;
    _logicTimer?.cancel();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goLevelSelect() {
    _cancelBananaTimer();
    banana = null;
    _logicTimer?.cancel();
    Navigator.of(context).pop();
  }

  void _endGame() {
    _cancelBananaTimer();
    setState(() {
      banana = null;
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

    final isNewBest =
        widget.campaign.currentRunScore > widget.campaign.bestRunScore;

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || !_gameHasEnded) return;
      _showGameOverDialog(isNewBest);
    });
  }

  void _showGameOverDialog(bool isNewBest) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameOverDialog(
        levelId: currentLevel.id,
        levelScore: levelScore,
        runScore: widget.campaign.currentRunScore,
        bestRunScore:
            max(widget.campaign.currentRunScore, widget.campaign.bestRunScore),
        chancesRemaining: max(
            0,
            ChanceService.kMaxChancesPerAttempt -
                widget.campaign.chancesUsedThisAttempt),
        isNewBest: isNewBest,
        unlockedThemes: _unlockedThisRound,
        canvasThemes: widget.canvasThemes,
        onSecondChance: _onSecondChanceRequested,
        onRetry: () {
          widget.campaign.retryLevel();
          startGame();
        },
        onLevelSelect: _goLevelSelect,
        onHome: _goHome,
      ),
    );
  }

  Future<void> _onLevelCleared() async {
    _cancelBananaTimer();
    _logicTimer?.cancel();
    setState(() {
      banana = null;
      isPlaying = false;
    });

    if (widget.settings.soundEnabled) _playStart();
    if (widget.settings.vibrationEnabled) {
      unawaited(HapticFeedback.heavyImpact());
    }

    final starsEarned = await widget.campaign.onLevelComplete(
      levelId: currentLevel.id,
      levelScore: levelScore,
    );

    if (!mounted) return;

    if (currentLevel.id >= 30) {
      // Grand Finale dialog after level 30
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameCompleteDialog(
          totalStars: widget.campaign.totalStars,
          runScore: widget.campaign.currentRunScore,
          bestRunScore: widget.campaign.bestRunScore,
          onPlayAgain: () => _loadLevel(1),
          onLevelSelect: _goLevelSelect,
          onHome: _goHome,
        ),
      );
    } else {
      // Level Complete dialog
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => LevelCompleteDialog(
          levelId: currentLevel.id,
          levelScore: levelScore,
          runScore: widget.campaign.currentRunScore,
          bestRunScore: widget.campaign.bestRunScore,
          earnedStars: starsEarned,
          unlockedThemes: _unlockedThisRound,
          canvasThemes: widget.canvasThemes,
          onNextLevel: () => _loadLevel(currentLevel.id + 1),
          onReplay: () {
            widget.campaign.retryLevel();
            startGame();
          },
          onLevelSelect: _goLevelSelect,
        ),
      );
    }
  }

  // ===== Second Chance Snapshot & Rewind =====
  void _pushSnapshot() {
    if (_snapshotBuffer.length >= LevelRules.snapshotBufferSize) {
      _snapshotBuffer.removeAt(0);
    }
    _snapshotBuffer.add(
      GameSnapshot(
        snake: snake.map((s) => List<int>.from(s)).toList(),
        segIds: List<int>.from(segIds),
        segDirs: List<String>.from(segDirs),
        direction: direction,
        nextDirection: nextDirection,
        food: food,
        banana: banana,
        fruitsSinceBanana: _fruitsSinceBanana,
        pendingGrowth: pendingGrowth,
        levelScore: levelScore,
        runScore: widget.campaign.currentRunScore,
        tickCount: _tickCount,
        patrols: _patrols.map((p) => p.clone()).toList(),
      ),
    );
  }

  Future<void> _onSecondChanceRequested() async {
    final granted = await _chanceService.requestChance();
    if (!granted || !mounted) return;

    widget.campaign.useChance();

    // Find the best snapshot walking back ~3 ticks with 2-move safety lookahead
    GameSnapshot? targetSnapshot;

    if (_snapshotBuffer.isNotEmpty) {
      final startIndex = max(0, _snapshotBuffer.length - 3);
      for (int i = startIndex; i >= 0; i--) {
        final cand = _snapshotBuffer[i];
        if (_isSnapshotSafeForTwoSteps(cand)) {
          targetSnapshot = cand;
          break;
        }
      }
      targetSnapshot ??= _snapshotBuffer.first;
    }

    if (targetSnapshot != null) {
      // Auto-turn to safe direction if needed
      final safeDir = _findSafeDirection(targetSnapshot);

      setState(() {
        snake = targetSnapshot!.snake.map((s) => List<int>.from(s)).toList();
        segIds = List<int>.from(targetSnapshot.segIds);
        final maxExisting = segIds.fold<int>(0, max);
        if (_nextId <= maxExisting) _nextId = maxExisting + 1;
        segDirs = List<String>.from(targetSnapshot.segDirs);
        direction = safeDir;
        nextDirection = safeDir;
        food = targetSnapshot.food;
        banana = targetSnapshot.banana;
        _fruitsSinceBanana = targetSnapshot.fruitsSinceBanana;
        pendingGrowth = targetSnapshot.pendingGrowth;
        levelScore = targetSnapshot.levelScore;
        _tickCount = targetSnapshot.tickCount;

        _patrols.clear();
        for (final p in targetSnapshot.patrols) {
          _patrols.add(p.clone());
        }
        _updateSpikeStates();

        _gameHasEnded = false;
        _showHitStars = false;
        isPlaying = false;
      });

      if (banana != null) {
        _startBananaTimer();
      } else {
        _cancelBananaTimer();
      }
    }

    // Show 3-2-1 "Get Ready" countdown overlay
    _startCountdownAndResume();
  }

  bool _isSnapshotSafeForTwoSteps(GameSnapshot snap) {
    var hx = snap.snake.first[0];
    var hy = snap.snake.first[1];
    final dir = snap.direction;

    for (int step = 1; step <= 2; step++) {
      switch (dir) {
        case 'up':
          hy -= 1;
          break;
        case 'down':
          hy += 1;
          break;
        case 'left':
          hx -= 1;
          break;
        case 'right':
          hx += 1;
          break;
      }
      if (hx < 0 || hx >= cols || hy < 0 || hy >= rows) return false;
      final pKey = '$hx,$hy';
      if (_portalPartners.containsKey(pKey)) {
        final p = _portalPartners[pKey]!;
        hx = p[0];
        hy = p[1];
      }
      if (_rockSet.contains('$hx,$hy')) return false;
      for (final s in snap.snake) {
        if (s[0] == hx && s[1] == hy) return false;
      }
      final futureTick = snap.tickCount + step;
      for (final group in currentLevel.spikeGroups) {
        if (group.stateAtTick(futureTick) == 'on') {
          final spikes = currentLevel.spikes[group.id] ?? [];
          for (final sp in spikes) {
            if (sp[0] == hx && sp[1] == hy) return false;
          }
        }
      }
    }
    return true;
  }

  String _findSafeDirection(GameSnapshot snap) {
    final head = snap.snake.first;
    final candidates = ['up', 'down', 'left', 'right'];
    for (final d in candidates) {
      if (_isOpposite(snap.direction, d)) continue;
      var hx = head[0];
      var hy = head[1];
      switch (d) {
        case 'up':
          hy -= 1;
          break;
        case 'down':
          hy += 1;
          break;
        case 'left':
          hx -= 1;
          break;
        case 'right':
          hx += 1;
          break;
      }
      if (hx < 0 || hx >= cols || hy < 0 || hy >= rows) continue;
      if (_rockSet.contains('$hx,$hy')) continue;
      bool selfHit = false;
      for (final s in snap.snake) {
        if (s[0] == hx && s[1] == hy) {
          selfHit = true;
          break;
        }
      }
      if (selfHit) continue;
      return d;
    }
    return snap.direction;
  }

  void _startCountdownAndResume() {
    _countdownTimer?.cancel();
    _logicTimer?.cancel();
    setState(() {
      isPlaying = false;
      _countdownText = '3';
    });
    if (widget.settings.vibrationEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }

    int step = 3;
    _countdownTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      step--;
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (step == 2) {
        setState(() => _countdownText = '2');
        if (widget.settings.vibrationEnabled) {
          unawaited(HapticFeedback.selectionClick());
        }
      } else if (step == 1) {
        setState(() => _countdownText = '1');
        if (widget.settings.vibrationEnabled) {
          unawaited(HapticFeedback.selectionClick());
        }
      } else if (step == 0) {
        setState(() => _countdownText = 'GO!');
        if (widget.settings.soundEnabled) {
          _playStart();
        }
        if (widget.settings.vibrationEnabled) {
          unawaited(HapticFeedback.mediumImpact());
        }
      } else {
        timer.cancel();
        _countdownTimer = null;
        if (mounted) {
          setState(() {
            _countdownText = null;
            isPlaying = true;
          });
          _activeTick = tick;
          _logicTimer?.cancel();
          _logicTimer = Timer.periodic(tick, (_) => _stepLogicOnce());
        }
      }
    });
  }

  // ===== Engine Tick Order =====
  void _stepLogicOnce() {
    if (!mounted || !isPlaying) return;

    // 1. Apply buffered direction
    direction = nextDirection;

    // 2. Compute raw new head. Wall hit = game over.
    final headOld = snake.first;
    int rawHx = headOld[0];
    int rawHy = headOld[1];

    switch (direction) {
      case 'up':
        rawHy -= 1;
        break;
      case 'down':
        rawHy += 1;
        break;
      case 'left':
        rawHx -= 1;
        break;
      case 'right':
        rawHx += 1;
        break;
    }

    if (rawHx < 0 || rawHx >= cols || rawHy < 0 || rawHy >= rows) {
      _endGame();
      return;
    }

    // 3. If raw head is portal cell, teleport head to partner cell
    int finalHx = rawHx;
    int finalHy = rawHy;
    final portalKey = '$rawHx,$rawHy';
    if (_portalPartners.containsKey(portalKey)) {
      final partner = _portalPartners[portalKey]!;
      finalHx = partner[0];
      finalHy = partner[1];
    }

    // 4. Advance spike phases and patrol positions
    _tickCount++;
    _updateSpikeStates();
    for (final patrol in _patrols) {
      patrol.step(_tickCount);
    }

    // 5. Check collisions on final head cell:
    // a) Rock
    if (_rockSet.contains('$finalHx,$finalHy')) {
      _endGame();
      return;
    }

    // b) Self collision (ignore moving tail if not growing)
    final checkLimit = (pendingGrowth > 0) ? snake.length : snake.length - 1;
    for (int i = 0; i < checkLimit; i++) {
      if (snake[i][0] == finalHx && snake[i][1] == finalHy) {
        _endGame();
        return;
      }
    }

    // c) ON spike collision
    for (final entry in _spikeStates.entries) {
      if (entry.value == SpikeState.on) {
        final spikeCells = currentLevel.spikes[entry.key] ?? [];
        for (final sp in spikeCells) {
          if (sp[0] == finalHx && sp[1] == finalHy) {
            _endGame();
            return;
          }
        }
      }
    }

    // d) Patrol collision & Patrol swap collision
    for (final patrol in _patrols) {
      if (patrol.occupies(finalHx, finalHy)) {
        _endGame();
        return;
      }
      if (patrol.swapped(headOld, [finalHx, finalHy])) {
        _endGame();
        return;
      }
    }

    // 6. Food and growth, then update levelScore and runScore, then check level clear
    final ateRegular = (finalHx == food.x && finalHy == food.y);
    final ateBanana =
        (banana != null && finalHx == banana!.x && finalHy == banana!.y);

    setState(() {
      snake.insert(0, [finalHx, finalHy]);
      segDirs.insert(0, direction);
      final newId = _nextId++;
      segIds.insert(0, newId);
    });

    if (ateBanana) {
      _cancelBananaTimer();
      setState(() => banana = null);
      const pts = 10;
      levelScore += pts;
      pendingGrowth += 1;
      widget.campaign.updateRunScore(pts);

      if (widget.settings.soundEnabled) _playEat();
      if (widget.settings.vibrationEnabled) {
        unawaited(HapticFeedback.selectionClick());
      }

      // Check canvas unlocks against runScore
      final newlyUnlocked =
          widget.canvasThemes.checkUnlock(widget.campaign.currentRunScore);
      for (final t in newlyUnlocked) {
        if (!_unlockedThisRound.any((u) => u.id == t.id)) {
          _unlockedThisRound.add(t);
        }
        _showUnlockBanner(t.name);
      }

      // Check Level Clear condition
      if (levelScore >= LevelRules.targetScore) {
        _onLevelCleared();
        return;
      }
    }

    if (ateRegular) {
      const pts = 1;
      levelScore += pts;
      pendingGrowth += 1;
      widget.campaign.updateRunScore(pts);
      _fruitsSinceBanana++;

      if (widget.settings.soundEnabled) _playEat();
      if (widget.settings.vibrationEnabled) {
        unawaited(HapticFeedback.selectionClick());
      }

      // Check canvas unlocks against runScore
      final newlyUnlocked =
          widget.canvasThemes.checkUnlock(widget.campaign.currentRunScore);
      for (final t in newlyUnlocked) {
        if (!_unlockedThisRound.any((u) => u.id == t.id)) {
          _unlockedThisRound.add(t);
        }
        _showUnlockBanner(t.name);
      }

      // Check Level Clear condition
      if (levelScore >= LevelRules.targetScore) {
        _onLevelCleared();
        return;
      }

      // Spawn next regular fruit
      _createRegularFoodSafe();

      // Spawn banana booster based on level threshold:
      // Level 1-10: 5 fruits, 11-15: 7 fruits, 16-20: 10 fruits, 21-29: 15 fruits, 30: 30 fruits
      final threshold = LevelRules.bananaThresholdForLevel(currentLevel.id);
      if (_fruitsSinceBanana >= threshold && banana == null) {
        _fruitsSinceBanana = 0;
        _createBananaSafe();
      }
    }

    if (pendingGrowth > 0) {
      pendingGrowth -= 1;
    } else {
      setState(() {
        snake.removeLast();
        segIds.removeLast();
        segDirs.removeLast();
      });
    }

    _pushSnapshot();
  }

  // ===== Food Spawning =====
  FoodType _rollRegularFoodType() {
    final r = randomGen.nextDouble();
    if (r < 0.45) return FoodType.red;
    if (r < 0.75) return FoodType.blue;
    return FoodType.purple;
  }

  void _cancelBananaTimer() {
    _bananaTimer?.cancel();
    _bananaTimer = null;
    _bananaRemainingMs = 0;
  }

  void _startBananaTimer() {
    _cancelBananaTimer();
    _bananaRemainingMs = 5000; // 5-second booster timer
    _bananaTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!isPlaying) return; // Freeze countdown while paused or counting down

      setState(() {
        _bananaRemainingMs -= 100;
        if (_bananaRemainingMs <= 0) {
          timer.cancel();
          _bananaTimer = null;
          banana = null; // Auto-hide bonus banana booster!
          _bananaRemainingMs = 0;
        }
      });
    });
  }

  void _createRegularFoodSafe() {
    final blocked = <String>{};
    for (final s in snake) {
      blocked.add('${s[0]},${s[1]}');
    }
    blocked.addAll(_rockSet);
    blocked.addAll(_portalPartners.keys);
    for (final spikes in currentLevel.spikes.values) {
      for (final sp in spikes) {
        blocked.add('${sp[0]},${sp[1]}');
      }
    }
    for (final patrol in currentLevel.patrols) {
      for (final p in patrol.path) {
        blocked.add('${p[0]},${p[1]}');
      }
    }
    if (banana != null) {
      blocked.add('${banana!.x},${banana!.y}');
    }

    final available = <List<int>>[];
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (!blocked.contains('$x,$y')) {
          available.add([x, y]);
        }
      }
    }

    final foodType = _rollRegularFoodType();
    if (available.isEmpty) {
      food = Food(0, 0, foodType);
    } else {
      final pick = available[randomGen.nextInt(available.length)];
      food = Food(pick[0], pick[1], foodType);
    }
  }

  void _createBananaSafe() {
    _cancelBananaTimer();

    final blocked = <String>{};
    for (final s in snake) {
      blocked.add('${s[0]},${s[1]}');
    }
    blocked.addAll(_rockSet);
    blocked.addAll(_portalPartners.keys);
    for (final spikes in currentLevel.spikes.values) {
      for (final sp in spikes) {
        blocked.add('${sp[0]},${sp[1]}');
      }
    }
    for (final patrol in currentLevel.patrols) {
      for (final p in patrol.path) {
        blocked.add('${p[0]},${p[1]}');
      }
    }
    blocked.add('${food.x},${food.y}');

    final available = <List<int>>[];
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (!blocked.contains('$x,$y')) {
          available.add([x, y]);
        }
      }
    }

    if (available.isNotEmpty) {
      final pick = available[randomGen.nextInt(available.length)];
      setState(() {
        banana = Food(pick[0], pick[1], FoodType.yellow);
      });
      _startBananaTimer();
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

  // ===== Sprite Mapping =====
  bool _eq(List<int> a, List<int> b) => a[0] == b[0] && a[1] == b[1];

  int _dist(List<int> a, List<int> b) =>
      (a[0] - b[0]).abs() + (a[1] - b[1]).abs();

  String _headForDir(String dir) {
    switch (dir) {
      case 'up':
        return '${_kSnakeDir}head_up.png';
      case 'down':
        return '${_kSnakeDir}head_down.png';
      case 'left':
        return '${_kSnakeDir}head_left.png';
      default:
        return '${_kSnakeDir}head_right.png';
    }
  }

  String _tailForDir(String dir) {
    switch (dir) {
      case 'up':
        return '${_kSnakeDir}tail_up.png';
      case 'down':
        return '${_kSnakeDir}tail_down.png';
      case 'left':
        return '${_kSnakeDir}tail_left.png';
      default:
        return '${_kSnakeDir}tail_right.png';
    }
  }

  String _headPath(List<int> head, List<int> neck, String dir) {
    if (_dist(head, neck) > 1) return _headForDir(dir);
    final dx = head[0] - neck[0], dy = head[1] - neck[1];
    if (dx == 1 && dy == 0) return '${_kSnakeDir}head_right.png';
    if (dx == -1 && dy == 0) return '${_kSnakeDir}head_left.png';
    if (dx == 0 && dy == -1) return '${_kSnakeDir}head_up.png';
    return '${_kSnakeDir}head_down.png';
  }

  String _tailPath(List<int> beforeTail, List<int> tail, String tailDir) {
    if (_dist(beforeTail, tail) > 1) return _tailForDir(tailDir);
    final dx = tail[0] - beforeTail[0], dy = tail[1] - beforeTail[1];
    if (dx == 1 && dy == 0) return '${_kSnakeDir}tail_right.png';
    if (dx == -1 && dy == 0) return '${_kSnakeDir}tail_left.png';
    if (dx == 0 && dy == 1) return '${_kSnakeDir}tail_down.png';
    return '${_kSnakeDir}tail_up.png';
  }

  String _bodyPath(
      List<int> prev, List<int> cur, List<int> next, String curDir) {
    if (_dist(prev, cur) > 1 || _dist(cur, next) > 1) {
      if (curDir == 'left' || curDir == 'right') {
        return '${_kSnakeDir}body_horizontal.png';
      }
      return '${_kSnakeDir}body_vertical.png';
    }

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

  String _bodyForTwo(List<int> head, List<int> body, String dir) {
    if (_dist(head, body) > 1) {
      if (dir == 'left' || dir == 'right') {
        return '${_kSnakeDir}body_horizontal.png';
      }
      return '${_kSnakeDir}body_vertical.png';
    }
    final dx = head[0] - body[0];
    if (dx != 0) return '${_kSnakeDir}body_horizontal.png';
    return '${_kSnakeDir}body_vertical.png';
  }

  // ===== UI Build =====
  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);

    return AnimatedBuilder(
      animation: Listenable.merge([widget.canvasThemes, widget.campaign]),
      builder: (context, child) {
        final activeTheme = widget.canvasThemes.selectedTheme;
        final backdropColor = Color.alphaBlend(
          activeTheme.boardFrame.withOpacity(0.04),
          AppColors.background,
        );

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final nav = Navigator.of(context);
            if (isPlaying) _pauseGame();
            final leave = await _showConfirmExitDialog(
              title: 'Quit Game?',
              message:
                  'Are you sure you want to exit? Your current level progress will be lost.',
              confirmLabel: 'EXIT',
            );
            if (leave) {
              nav.pop();
            } else if (mounted && _hasStarted && !_gameHasEnded) {
              _startCountdownAndResume();
            }
          },
          child: RawKeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKey: _onKey,
            child: ResponsiveScaffold(
              centerContent: false,
              backgroundColor: backdropColor,
              appBar: AppBar(
                backgroundColor: backdropColor,
                leading: IconButton(
                  tooltip: 'Levels',
                  onPressed: () async {
                    if (isPlaying) _pauseGame();
                    final leave = await _showConfirmExitDialog(
                      title: 'Quit to Levels?',
                      message:
                          'Are you sure you want to exit to Level Select? Current level progress will be lost.',
                      confirmLabel: 'EXIT',
                    );
                    if (leave) {
                      _goLevelSelect();
                    } else if (mounted && _hasStarted && !_gameHasEnded) {
                      _startCountdownAndResume();
                    }
                  },
                  icon: const Icon(Icons.grid_view_rounded),
                ),
                title: const Text('SNAKE BUDDY'),
                actions: [
                  IconButton(
                    tooltip: isPlaying ? 'Pause' : 'Resume',
                    onPressed: isPlaying
                        ? _showPauseMenu
                        : (_hasStarted && !_gameHasEnded
                            ? _startCountdownAndResume
                            : startGame),
                    icon: Icon(isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  isLandscape
                      ? _buildLandscapeLayout()
                      : _buildPortraitLayout(),

                  // Level Intro Overlay
                  if (_showingIntro)
                    Positioned.fill(
                      child: LevelIntroCard(
                        level: currentLevel,
                        onDismiss: startGame,
                      ),
                    ),

                  // 3-2-1 GO Countdown Overlay
                  if (_countdownText != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Column(
                            key: ValueKey(_countdownText),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _countdownText!,
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: _countdownText == 'GO!'
                                      ? AppColors.accentLime
                                      : Colors.white,
                                  fontSize: _countdownText == 'GO!' ? 86 : 76,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 16,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _countdownText == 'GO!'
                                    ? "LET'S GO!"
                                    : 'GET READY',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: _countdownText == 'GO!'
                                      ? AppColors.accentLime
                                      : AppColors.surface,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildHud(),
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
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swipe_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Swipe anywhere to steer',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
        SizedBox(
          width: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHud(),
              const SizedBox(height: AppSpacing.md),
              if (widget.settings.controls == ControlType.buttons)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildDpad(isCompact: true),
                ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell = Responsive.calculateCellSize(
                  availableWidth: constraints.maxWidth - AppSpacing.md,
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
      ],
    );
  }

  Widget _buildHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: LV chip, Score chip (runScore), Best chip
          Row(
            children: [
              Expanded(
                flex: 3,
                child: StatChip(
                  label: 'LV',
                  value: '${currentLevel.id}',
                  icon: const Icon(
                    Icons.flag_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 4,
                child: StatChip(
                  label: 'Score',
                  value: '${widget.campaign.currentRunScore}',
                  icon: const Icon(
                    Icons.circle,
                    size: 10,
                    color: AppColors.foodApple,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 4,
                child: StatChip(
                  label: 'Best',
                  value:
                      '${max(widget.campaign.currentRunScore, widget.campaign.bestRunScore)}',
                  icon: const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.foodBananaText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Animated progress bar (0 - 100)
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.pillRadius,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  LayoutBuilder(
                    builder: (context, barConstraints) {
                      final progress =
                          (levelScore / LevelRules.targetScore).clamp(0.0, 1.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: barConstraints.maxWidth * progress,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.accentLime,
                          borderRadius: AppRadius.pillRadius,
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Text(
                      '$levelScore / ${LevelRules.targetScore}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(double cell, double boardW, double boardH) {
    final activeTheme = widget.canvasThemes.selectedTheme;

    // Convert patrols for PatrolLayer
    final patrolBlocks = <PatrolBlockData>[];
    for (final p in _patrols) {
      patrolBlocks.add(
        PatrolBlockData(
          id: p.id,
          x: p.currentPos[0],
          y: p.currentPos[1],
          size: p.config.size,
          direction: p.moveDirection,
        ),
      );
    }

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
                // 1. Two-tone checkerboard
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

                // 2. Obstacles Layer (Rocks, Spikes, Portals)
                AnimatedBuilder(
                  animation: Listenable.merge([_portalCtrl, _spikePulseCtrl]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(boardW, boardH),
                      painter: ObstaclePainter(
                        level: currentLevel,
                        theme: activeTheme,
                        cell: cell,
                        portalAngle: _portalCtrl.value * 2 * pi,
                        spikePulse: _spikePulseCtrl.value,
                        spikeStates: _spikeStates,
                      ),
                    );
                  },
                ),

                // 3. Moving Patrols Layer
                PatrolLayer(
                  patrols: patrolBlocks,
                  cell: cell,
                  duration: tick,
                  theme: activeTheme,
                ),

                // 4. Food Pickups
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

                // 4b. Banana Booster Item (5-second limited bonus)
                if (banana != null)
                  AnimatedPositioned(
                    left: banana!.x * cell,
                    top: banana!.y * cell,
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
                                    color: foodHaloColor(FoodType.yellow)
                                        .withOpacity(
                                            activeTheme.haloOpacity * 1.5),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            // 5-second circular progress indicator ring around the banana
                            SizedBox(
                              width: cell * 0.95,
                              height: cell * 0.95,
                              child: CircularProgressIndicator(
                                value: (_bananaRemainingMs / 5000.0)
                                    .clamp(0.0, 1.0),
                                strokeWidth: 2.2,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                valueColor: AlwaysStoppedAnimation(
                                  _bananaRemainingMs > 1500
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFFFF3D00),
                                ),
                              ),
                            ),
                            Image.asset(
                              foodAsset(FoodType.yellow),
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

                // 5. Snake Segments
                Positioned.fill(child: snakeLayer),

                // 6. Hit Stars on Collision
                if (_showHitStars) _buildHitStars(cell),

                // 7. Floating Canvas Unlock Banner
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
      final segDir = segDirs[i];

      late String path;
      if (i == 0) {
        if (snake.length >= 2) {
          path = _headPath(snake[0], snake[1], direction);
        } else {
          path = _headForDir(direction);
        }
      } else if (snake.length == 2 && i == 1) {
        path = _bodyForTwo(snake[0], snake[1], segDir);
      } else if (i == snake.length - 1 && snake.length >= 3) {
        path = _tailPath(snake[i - 1], snake[i], segDir);
      } else {
        path = _bodyPath(snake[i - 1], snake[i], snake[i + 1], segDir);
      }

      // If segment just teleported (>1 cell away from adjacent segment), snap without tween
      final isTeleportJump = (i > 0 && _dist(snake[i], snake[i - 1]) > 1);
      final segDuration = isTeleportJump ? Duration.zero : tick;

      w.add(
        AnimatedPositioned(
          key: ValueKey('seg_$id'),
          left: seg[0] * cell,
          top: seg[1] * cell,
          width: cell,
          height: cell,
          duration: segDuration,
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
