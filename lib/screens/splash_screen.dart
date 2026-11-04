import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/home_screen.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/widgets/responsive_scaffold.dart';

class SplashScreen extends StatefulWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;

  SplashScreen({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
  }) : canvasThemes = canvasThemes ?? CanvasThemeController();

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _minimumDuration = Duration(milliseconds: 2700);
  static const _assets = [
    'assets/sprites/clearcode/head_up.png',
    'assets/sprites/clearcode/head_down.png',
    'assets/sprites/clearcode/head_left.png',
    'assets/sprites/clearcode/head_right.png',
    'assets/sprites/clearcode/tail_up.png',
    'assets/sprites/clearcode/tail_down.png',
    'assets/sprites/clearcode/tail_left.png',
    'assets/sprites/clearcode/tail_right.png',
    'assets/sprites/clearcode/body_horizontal.png',
    'assets/sprites/clearcode/body_vertical.png',
    'assets/sprites/clearcode/body_topleft.png',
    'assets/sprites/clearcode/body_topright.png',
    'assets/sprites/clearcode/body_bottomleft.png',
    'assets/sprites/clearcode/body_bottomright.png',
    'assets/images/apple.png',
    'assets/images/blueberry.png',
    'assets/images/grape.png',
    'assets/images/banana.png',
  ];

  late final AnimationController _timelineController;
  late final Animation<double> _snakeTravel;
  late final Animation<double> _fruitOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleScale;
  late final AnimationController _fruitPulseController;
  late final Animation<double> _fruitScale;

  String? _initializationError;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _timelineController = AnimationController(
      vsync: this,
      duration: _minimumDuration,
    );
    _snakeTravel = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0, 0.68, curve: Curves.easeInOutCubic),
    );
    _fruitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.55, 0.70, curve: Curves.easeIn),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.60, 0.86, curve: Curves.easeOut),
    );
    _titleScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.60, 0.88, curve: Curves.easeOutBack),
      ),
    );
    _fruitPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _fruitScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _fruitPulseController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startSplash());
  }

  Future<void> _initialize() async {
    await widget.settings.load();
    await widget.canvasThemes.load(highScore: widget.settings.highScore);
    await Future.wait(
      _assets.map((asset) => precacheImage(AssetImage(asset), context)),
    );
  }

  Future<void> _startSplash() async {
    if (!mounted || _isNavigating) return;
    setState(() => _initializationError = null);
    try {
      await Future.wait([
        _initialize(),
        _timelineController.forward(from: 0),
        Future<void>.delayed(_minimumDuration),
      ]);
      if (mounted) _navigateToHome();
    } catch (error) {
      if (mounted) setState(() => _initializationError = error.toString());
    }
  }

  void _navigateToHome() {
    if (_isNavigating) return;
    _isNavigating = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          settings: widget.settings,
          canvasThemes: widget.canvasThemes,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _fruitPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final areaWidth = constraints.maxWidth;
          final areaHeight = constraints.maxHeight;
          final cellSize = math.min(areaWidth * 0.12, 44.0);
          final snakeWidth = cellSize * 4;
          final start = -snakeWidth;
          final end = areaWidth - 28 - snakeWidth;

          return AnimatedBuilder(
            animation: _timelineController,
            builder: (context, child) => Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: areaHeight * 0.20,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: ScaleTransition(
                      scale: _titleScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SNAKE',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displayLarge.copyWith(
                              color: AppColors.primaryDeep,
                              fontSize: 48,
                              letterSpacing: 4.0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            width: 68,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.accentLime,
                              borderRadius: AppRadius.pillRadius,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: areaHeight * 0.47,
                  left: start + (end - start) * _snakeTravel.value,
                  child: _buildSlidingSnake(cellSize),
                ),
                Positioned(
                  top: areaHeight * 0.47 + cellSize * 0.1,
                  right: 28,
                  child: FadeTransition(
                    opacity: _fruitOpacity,
                    child: ScaleTransition(
                      scale: _fruitScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: cellSize * 0.7,
                            height: cellSize * 0.7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.foodAppleHalo,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/images/apple.png',
                            width: cellSize * 0.85,
                            height: cellSize * 0.85,
                            filterQuality: FilterQuality.none,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xxl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Loading...',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: AppRadius.pillRadius,
                        child: LinearProgressIndicator(
                          value: _timelineController.value,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.accentLime,
                          ),
                        ),
                      ),
                      if (_initializationError != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Unable to load game: $_initializationError',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextButton(
                          onPressed: () {
                            if (_timelineController.isCompleted) {
                              unawaited(_startSplash());
                            }
                          },
                          child: Text(
                            'RETRY',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlidingSnake(double cellSize) {
    Widget snake = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sprite('assets/sprites/clearcode/tail_left.png', cellSize),
        _sprite('assets/sprites/clearcode/body_horizontal.png', cellSize),
        _sprite('assets/sprites/clearcode/body_horizontal.png', cellSize),
        _sprite('assets/sprites/clearcode/head_right.png', cellSize),
      ],
    );
    final activeTheme = widget.canvasThemes.selectedTheme;
    if (activeTheme.snakeColorFilter != null) {
      snake = ColorFiltered(
        colorFilter: activeTheme.snakeColorFilter!,
        child: snake,
      );
    }
    return snake;
  }

  Widget _sprite(String asset, double size) => Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
}
