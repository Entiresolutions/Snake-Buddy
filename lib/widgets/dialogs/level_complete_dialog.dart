import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/theme/canvas_themes.dart';
import 'package:snake_game/widgets/primary_button.dart';
import 'package:snake_game/widgets/secondary_button.dart';
import 'package:snake_game/widgets/stat_chip.dart';

class LevelCompleteDialog extends StatefulWidget {
  final int levelId;
  final int levelScore;
  final int runScore;
  final int bestRunScore;
  final int earnedStars;
  final List<CanvasTheme> unlockedThemes;
  final CanvasThemeController canvasThemes;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onLevelSelect;

  const LevelCompleteDialog({
    super.key,
    required this.levelId,
    required this.levelScore,
    required this.runScore,
    required this.bestRunScore,
    required this.earnedStars,
    required this.unlockedThemes,
    required this.canvasThemes,
    required this.onNextLevel,
    required this.onReplay,
    required this.onLevelSelect,
  });

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  int _visibleStars = 0;
  final List<Timer> _starTimers = [];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
    );
    _anim.forward();

    // Staggered star appearance (every 250ms)
    for (int i = 1; i <= widget.earnedStars; i++) {
      final timer = Timer(Duration(milliseconds: 300 + i * 250), () {
        if (mounted) {
          setState(() => _visibleStars = i);
        }
      });
      _starTimers.add(timer);
    }
  }

  @override
  void dispose() {
    for (final t in _starTimers) {
      t.cancel();
    }
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ScaleTransition(
          scale: _scale,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Gold Trophy Badge
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.foodBananaText,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'LEVEL ${widget.levelId} CLEARED!',
                textAlign: TextAlign.center,
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.primaryDeep,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 3 Stars Row (sequentially filled)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final filled = index < _visibleStars;
                  return AnimatedScale(
                    scale: filled ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.star_rounded,
                        size: 36,
                        color: filled
                            ? AppColors.foodBananaText
                            : AppColors.border,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              // Next level unlocked pill
              if (widget.levelId < 30)
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
                    'Level ${widget.levelId + 1} Unlocked!',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // Stat chips
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: StatChip(
                      compact: true,
                      label: 'Score',
                      value: '${widget.levelScore}',
                      icon: const Icon(
                        Icons.circle,
                        size: 8,
                        color: AppColors.foodApple,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 3,
                    child: StatChip(
                      compact: true,
                      label: 'Total',
                      value: '${widget.runScore}',
                      icon: const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.foodBananaText,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 3,
                    child: StatChip(
                      compact: true,
                      label: 'Best',
                      value: '${widget.bestRunScore}',
                      icon: const Icon(
                        Icons.emoji_events_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              // Canvas unlocks
              if (widget.unlockedThemes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final unlockedTheme in widget.unlockedThemes)
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
                        Expanded(
                          child: Text(
                            'Unlocked: ${unlockedTheme.name}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.canvasThemes.selectTheme(unlockedTheme.id);
                            setState(() {});
                          },
                          child: Text(
                            widget.canvasThemes.selectedThemeId == unlockedTheme.id
                                ? 'ACTIVE'
                                : 'USE NOW',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: widget.levelId < 30 ? 'NEXT LEVEL' : 'CONTINUE',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onNextLevel();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      height: 46.0,
                      label: 'REPLAY',
                      icon: Icons.replay_rounded,
                      borderColor: AppColors.border,
                      textColor: AppColors.primaryDeep,
                      backgroundColor: AppColors.surfaceSubtle,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      fontSize: 13,
                      semanticsLabel: 'Replay level',
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onReplay();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      height: 46.0,
                      label: 'LEVELS',
                      icon: Icons.grid_view_rounded,
                      borderColor: AppColors.border,
                      textColor: AppColors.textSecondary,
                      backgroundColor: AppColors.surfaceSubtle,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      fontSize: 13,
                      semanticsLabel: 'Select level',
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onLevelSelect();
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
}

