import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/theme/canvas_themes.dart';
import 'package:snake_game/widgets/app_card.dart';
import 'package:snake_game/widgets/responsive.dart';
import 'package:snake_game/widgets/responsive_scaffold.dart';

class ThemeScreen extends StatefulWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;

  const ThemeScreen({
    super.key,
    required this.settings,
    required this.canvasThemes,
  });

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  String? _shakingThemeId;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    // Mark newly unlocked themes as viewed once page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.canvasThemes.markAllAsViewed();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onTapTheme(CanvasTheme theme) async {
    final isUnlocked = widget.canvasThemes.isUnlocked(theme.id);
    if (!isUnlocked) {
      if (widget.settings.vibrationEnabled) {
        HapticFeedback.lightImpact();
      }

      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (!reduceMotion) {
        setState(() => _shakingThemeId = theme.id);
        _shakeController.forward(from: 0).then((_) {
          if (mounted) setState(() => _shakingThemeId = null);
        });
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Score ${theme.unlockScore} points to unlock ${theme.name}.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.settings.vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
    await widget.canvasThemes.selectTheme(theme.id);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('THEME'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([widget.settings, widget.canvasThemes]),
        builder: (context, _) {
          final selectedTheme = widget.canvasThemes.selectedTheme;
          final unlockedCount = widget.canvasThemes.unlockedCount;
          final totalCount = widget.canvasThemes.totalCount;
          final highScore = widget.settings.highScore;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = Responsive.isLandscape(context);
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final cardHeight =
                  (220.0 + (textScale - 1.0) * 55.0).clamp(215.0, 270.0);

              return SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== Header Card =====
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: const Icon(
                                  Icons.palette_rounded,
                                  color: AppColors.primaryDeep,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Best Score: $highScore',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primaryDeep,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '$unlockedCount / $totalCount canvases unlocked',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ClipRRect(
                            borderRadius: AppRadius.pillRadius,
                            child: LinearProgressIndicator(
                              value: unlockedCount / totalCount,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceMuted,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accentLime,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ===== Live Preview Card =====
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'ACTIVE CANVAS',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryDeep,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  selectedTheme.name,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryDeep,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedTheme.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _MiniBoardPreview(
                              key: ValueKey('preview_${selectedTheme.id}'),
                              theme: selectedTheme,
                              height: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ===== Section Title =====
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        'CANVAS COLLECTION',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDeep,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // ===== Grid of Canvas Cards =====
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isLandscape ? 340 : 260,
                        mainAxisExtent: cardHeight,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemCount: kCanvasThemes.length,
                      itemBuilder: (context, index) {
                        final theme = kCanvasThemes[index];
                        final isUnlocked =
                            widget.canvasThemes.isUnlocked(theme.id);
                        final isSelected =
                            widget.canvasThemes.selectedThemeId == theme.id;
                        final isNew = widget.canvasThemes.isNew(theme.id);
                        final isShaking = _shakingThemeId == theme.id;

                        Widget card = _CanvasCard(
                          theme: theme,
                          isUnlocked: isUnlocked,
                          isSelected: isSelected,
                          isNew: isNew,
                          highScore: highScore,
                          onTap: () => _onTapTheme(theme),
                        );

                        if (isShaking) {
                          card = AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              final offset = math.sin(
                                      _shakeAnimation.value * math.pi * 4) *
                                  7.0;
                              return Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
                              );
                            },
                            child: card,
                          );
                        }

                        return card;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CanvasCard extends StatefulWidget {
  final CanvasTheme theme;
  final bool isUnlocked;
  final bool isSelected;
  final bool isNew;
  final int highScore;
  final VoidCallback onTap;

  const _CanvasCard({
    required this.theme,
    required this.isUnlocked,
    required this.isSelected,
    required this.isNew,
    required this.highScore,
    required this.onTap,
  });

  @override
  State<_CanvasCard> createState() => _CanvasCardState();
}

class _CanvasCardState extends State<_CanvasCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.theme.unlockScore > 0
        ? (widget.highScore / widget.theme.unlockScore).clamp(0.0, 1.0)
        : 1.0;

    String semanticsLabel = widget.theme.name;
    if (widget.isSelected) {
      semanticsLabel += ', selected';
    } else if (widget.isUnlocked) {
      semanticsLabel += ', unlocked, tap to use';
    } else {
      semanticsLabel +=
          ', locked, reach ${widget.theme.unlockScore} points to unlock';
    }

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: widget.isSelected,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            border: widget.isSelected
                ? Border.all(color: AppColors.primary, width: 2.0)
                : Border.all(color: AppColors.border, width: 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mini Board Preview
                Stack(
                  children: [
                    _MiniBoardPreview(
                      theme: widget.theme,
                      isLocked: !widget.isUnlocked,
                      height: 80,
                    ),
                    if (widget.isNew)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLime,
                            borderRadius: AppRadius.pillRadius,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'NEW',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Name and Swatch Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.theme.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _MiniColorDots(theme: widget.theme),
                  ],
                ),
                const Spacer(),

                // Status Area
                if (widget.isSelected) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Selected',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else if (widget.isUnlocked) ...[
                  Text(
                    'Tap to use',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    'Reach ${widget.theme.unlockScore} pts to unlock',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniColorDots extends StatelessWidget {
  final CanvasTheme theme;

  const _MiniColorDots({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = [
      theme.boardLight,
      theme.boardFrame,
      theme.snakePreviewColor,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((c) {
        return Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 2,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MiniBoardPreview extends StatelessWidget {
  final CanvasTheme theme;
  final bool isLocked;
  final double height;

  const _MiniBoardPreview({
    super.key,
    required this.theme,
    this.isLocked = false,
    this.height = 75,
  });

  @override
  Widget build(BuildContext context) {
    Widget board = Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.boardLight,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: theme.boardFrame, width: 2.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Custom checkerboard background
            CustomPaint(
              size: Size.infinite,
              painter: _MiniCheckerPainter(
                boardLight: theme.boardLight,
                boardDark: theme.boardDark,
              ),
            ),

            // Mini Fruit with halo
            Positioned(
              right: 18,
              top: height * 0.28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.foodAppleHalo
                              .withValues(alpha: theme.haloOpacity),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/apple.png',
                    width: 18,
                    height: 18,
                    filterQuality: FilterQuality.none,
                  ),
                ],
              ),
            ),

            // Mini Snake (Tail, Body, Head)
            Positioned(
              left: 14,
              top: height * 0.26,
              child: _buildMiniSnake(),
            ),
          ],
        ),
      ),
    );

    if (isLocked) {
      board = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.213,
          0.715,
          0.072,
          0,
          0,
          0.213,
          0.715,
          0.072,
          0,
          0,
          0.213,
          0.715,
          0.072,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Stack(
          children: [
            board,
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.42),
                  borderRadius: AppRadius.smRadius,
                ),
                child: const Center(
                  child: ContainerBadgeLock(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return board;
  }

  Widget _buildMiniSnake() {
    Widget snake = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/sprites/clearcode/tail_left.png',
          width: 22,
          height: 22,
          filterQuality: FilterQuality.none,
        ),
        Image.asset(
          'assets/sprites/clearcode/body_horizontal.png',
          width: 22,
          height: 22,
          filterQuality: FilterQuality.none,
        ),
        Image.asset(
          'assets/sprites/clearcode/head_right.png',
          width: 22,
          height: 22,
          filterQuality: FilterQuality.none,
        ),
      ],
    );

    if (theme.snakeColorFilter != null) {
      snake = ColorFiltered(
        colorFilter: theme.snakeColorFilter!,
        child: snake,
      );
    }

    return snake;
  }
}

class ContainerBadgeLock extends StatelessWidget {
  const ContainerBadgeLock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_rounded,
        size: 18,
        color: AppColors.primaryDeep,
      ),
    );
  }
}

class _MiniCheckerPainter extends CustomPainter {
  final Color boardLight;
  final Color boardDark;

  _MiniCheckerPainter({
    required this.boardLight,
    required this.boardDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 9;
    const rows = 5;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final lightPaint = Paint()..color = boardLight;
    final darkPaint = Paint()..color = boardDark;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final fill = ((r + c) % 2 == 0) ? lightPaint : darkPaint;
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
          fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCheckerPainter old) =>
      old.boardLight != boardLight || old.boardDark != boardDark;
}
