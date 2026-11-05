import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/level_select_screen.dart';
import 'package:snake_game/screens/settings_screen.dart';
import 'package:snake_game/screens/theme_screen.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/widgets/app_card.dart';
import 'package:snake_game/widgets/primary_button.dart';
import 'package:snake_game/widgets/responsive_scaffold.dart';
import 'package:snake_game/widgets/secondary_button.dart';
import 'package:snake_game/widgets/stat_chip.dart';

class HomeScreen extends StatefulWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;
  final CampaignController campaign;

  HomeScreen({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
    CampaignController? campaign,
  })  : canvasThemes = canvasThemes ?? CanvasThemeController(),
        campaign = campaign ?? CampaignController();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fruitController;
  late final Animation<double> _fruitScale;
  late final AnimationController _snakeController;

  static const _fruits = [
    ('assets/images/apple.png', AppColors.foodAppleHalo),
    ('assets/images/blueberry.png', AppColors.foodBlueberryHalo),
    ('assets/images/grape.png', AppColors.foodGrapeHalo),
    ('assets/images/banana.png', AppColors.foodBananaHalo),
  ];

  @override
  void initState() {
    super.initState();
    _fruitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _fruitScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fruitController, curve: Curves.easeInOut),
    );

    _snakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _fruitController.dispose();
    _snakeController.dispose();
    super.dispose();
  }

  Route<void> _route(Widget page) => PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      );

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'SNAKE BUDDY',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primaryDeep,
                            fontSize: 42,
                            letterSpacing: 3.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 76,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.accentLime,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Hero Card with Animated Snake and Fruits
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          _buildAnimatedSnake(),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _fruits.map((item) {
                              final asset = item.$1;
                              final halo = item.$2;
                              return ScaleTransition(
                                scale: _fruitScale,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: halo,
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Image.asset(
                                      asset,
                                      width: 36,
                                      height: 36,
                                      filterQuality: FilterQuality.none,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // High score & Levels chips
                    AnimatedBuilder(
                      animation: Listenable.merge([widget.settings, widget.campaign]),
                      builder: (context, child) => Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          StatChip(
                            label: 'High Score',
                            value: '${math.max(widget.settings.highScore, widget.campaign.bestRunScore)}',
                            icon: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.foodBananaText,
                              size: 18,
                            ),
                            backgroundColor: AppColors.surface,
                            borderColor: AppColors.border,
                            valueColor: AppColors.primaryDeep,
                          ),
                          StatChip(
                            label: 'Levels',
                            value: '${widget.campaign.highestUnlockedLevel}/30',
                            icon: const Icon(
                              Icons.flag_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            backgroundColor: AppColors.surface,
                            borderColor: AppColors.border,
                            valueColor: AppColors.primaryDeep,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Play Button
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'PLAY',
                        icon: Icons.play_arrow_rounded,
                        semanticsLabel: 'Start game',
                        onPressed: () => Navigator.of(context).push(
                          _route(
                            LevelSelectScreen(
                              settings: widget.settings,
                              canvasThemes: widget.canvasThemes,
                              campaign: widget.campaign,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Settings Button
                    SizedBox(
                      width: double.infinity,
                      child: SecondaryButton(
                        label: 'SETTINGS',
                        icon: Icons.settings_outlined,
                        semanticsLabel: 'Open settings',
                        onPressed: () => Navigator.of(context).push(
                          _route(
                            SettingsScreen(
                              settings: widget.settings,
                              canvasThemes: widget.canvasThemes,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),

          // Top Left Theme Button
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _buildThemeButton(context),
          ),

          // Top Right Unlock All Button (for testing)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _buildUnlockAllButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockAllButton(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.campaign, widget.canvasThemes]),
      builder: (context, _) {
        final allLevelsUnlocked = widget.campaign.highestUnlockedLevel >= 30;
        final allThemesUnlocked =
            widget.canvasThemes.unlockedCount >= widget.canvasThemes.totalCount;
        final isAllUnlocked = allLevelsUnlocked && allThemesUnlocked;

        return Semantics(
          button: true,
          label: isAllUnlocked
              ? 'All levels and themes unlocked for testing'
              : 'Unlock all levels and themes for testing',
          child: Tooltip(
            message: isAllUnlocked
                ? 'All levels & themes unlocked (Tap to reset)'
                : 'Unlock all levels & themes for testing',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (isAllUnlocked) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'All 30 levels & themes are currently unlocked.',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primaryDeep,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'RESET',
                          textColor: AppColors.accentLime,
                          onPressed: () async {
                            await widget.campaign.resetCampaign();
                            await widget.canvasThemes.resetThemesForTesting();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reset levels & themes to default.',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.primaryDeep,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  } else {
                    await widget.campaign.unlockAllLevelsForTesting();
                    await widget.canvasThemes.unlockAllThemesForTesting();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'All 30 levels and all themes unlocked!',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: AppColors.primaryDeep,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                borderRadius: AppRadius.pillRadius,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isAllUnlocked
                        ? AppColors.primarySoft
                        : AppColors.surface,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: isAllUnlocked
                          ? AppColors.primary
                          : AppColors.border,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllUnlocked
                            ? Icons.lock_open_rounded
                            : Icons.key_rounded,
                        color: isAllUnlocked
                            ? AppColors.primary
                            : AppColors.primaryDeep,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isAllUnlocked ? 'UNLOCKED' : 'UNLOCK ALL',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isAllUnlocked
                              ? AppColors.primary
                              : AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open theme canvas gallery',
      child: AnimatedBuilder(
        animation: widget.canvasThemes,
        builder: (context, _) {
          final activeTheme = widget.canvasThemes.selectedTheme;
          final hasNew = widget.canvasThemes.hasNewThemes;

          return Tooltip(
            message: 'Themes (${activeTheme.name})',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  _route(
                    ThemeScreen(
                      settings: widget.settings,
                      canvasThemes: widget.canvasThemes,
                    ),
                  ),
                ),
                borderRadius: AppRadius.pillRadius,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.palette_rounded,
                            color: AppColors.primaryDeep,
                            size: 20,
                          ),
                          if (hasNew)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentLime,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'THEME',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedSnake() {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.canvasThemes, _snakeController]),
      builder: (context, _) {
        final activeTheme = widget.canvasThemes.selectedTheme;
        final t = _snakeController.value;
        final disableAnimations =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        final double phase = t * 2 * math.pi;

        // Smooth continuous floating glide (no rotation or scaling to keep pixel lines perfectly smooth)
        final double crawlX =
            disableAnimations ? 0.0 : math.sin(phase) * 12.0;
        final double crawlY =
            disableAnimations ? 0.0 : math.sin(phase * 2) * 2.5;

        const double segSize = 38.0;
        const double overlap = 2.5;
        const double step = segSize - overlap; // 35.5
        const double totalWidth = segSize + step * 3; // 144.5

        // Seamless unified snake: solid underlay eliminates any potential seam,
        // while 2.5dp overlap guarantees segments fuse into a single continuous body.
        Widget unifiedSnakeBody = SizedBox(
          width: totalWidth,
          height: segSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Solid underlay matching exact body color (0xFF5B7BF9)
              Positioned(
                left: 12.0,
                right: 14.0,
                top: 4.75,
                bottom: 4.75,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B7BF9),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
              ),

              // 2. Tail segment (left)
              Positioned(
                left: 0,
                top: 0,
                width: segSize,
                height: segSize,
                child: _sprite('assets/sprites/clearcode/tail_left.png', segSize),
              ),

              // 3. Middle body segment 1
              Positioned(
                left: step,
                top: 0,
                width: segSize,
                height: segSize,
                child: _sprite('assets/sprites/clearcode/body_horizontal.png', segSize),
              ),

              // 4. Middle body segment 2
              Positioned(
                left: step * 2,
                top: 0,
                width: segSize,
                height: segSize,
                child: _sprite('assets/sprites/clearcode/body_horizontal.png', segSize),
              ),

              // 5. Head segment (right, eyes facing forward)
              Positioned(
                left: step * 3,
                top: 0,
                width: segSize,
                height: segSize,
                child: _sprite('assets/sprites/clearcode/head_right.png', segSize),
              ),
            ],
          ),
        );

        if (activeTheme.snakeColorFilter != null) {
          unifiedSnakeBody = ColorFiltered(
            colorFilter: activeTheme.snakeColorFilter!,
            child: unifiedSnakeBody,
          );
        }

        // Translate the unified snake as one solid piece
        final Widget animatedSnake = Transform.translate(
          offset: Offset(crawlX, crawlY),
          child: unifiedSnakeBody,
        );

        final double shadowWidth =
            140.0 + (disableAnimations ? 0.0 : math.cos(phase * 2) * 4.0);

        return SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft ground shadow beneath the unified snake
              Transform.translate(
                offset: Offset(crawlX, 20),
                child: Container(
                  width: shadowWidth,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0x161A2E1C),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x121A2E1C),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              animatedSnake,
            ],
          ),
        );
      },
    );
  }

  Widget _sprite(String asset, double size) => Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.none,
      );
}
