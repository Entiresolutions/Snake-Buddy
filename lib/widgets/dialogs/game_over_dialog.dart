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

class GameOverDialog extends StatefulWidget {
  final int levelId;
  final int levelScore;
  final int runScore;
  final int bestRunScore;
  final int chancesRemaining;
  final bool isNewBest;
  final List<CanvasTheme> unlockedThemes;
  final CanvasThemeController canvasThemes;
  final VoidCallback onSecondChance;
  final VoidCallback onRetry;
  final VoidCallback onLevelSelect;
  final VoidCallback onHome;

  const GameOverDialog({
    super.key,
    required this.levelId,
    required this.levelScore,
    required this.runScore,
    required this.bestRunScore,
    required this.chancesRemaining,
    required this.isNewBest,
    required this.unlockedThemes,
    required this.canvasThemes,
    required this.onSecondChance,
    required this.onRetry,
    required this.onLevelSelect,
    required this.onHome,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  @override
  Widget build(BuildContext context) {
    final hasChances = widget.chancesRemaining > 0;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: widget.isNewBest
                      ? AppColors.primarySoft
                      : AppColors.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isNewBest
                      ? Icons.emoji_events_rounded
                      : Icons.heart_broken_rounded,
                  color: widget.isNewBest
                      ? AppColors.primaryDeep
                      : AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'GAME OVER',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Level ${widget.levelId}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (widget.isNewBest) ...[
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

              // Stat chips
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: StatChip(
                      compact: true,
                      label: 'Level',
                      value: '${widget.levelScore}/100',
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

            // Canvas unlock row
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
            const SizedBox(height: AppSpacing.xl),

            // Primary: Second Chance
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: hasChances
                    ? 'SECOND CHANCE (${widget.chancesRemaining} LEFT)'
                    : 'NO CHANCES LEFT',
                icon: Icons.favorite_rounded,
                semanticsLabel: 'Use second chance',
                onPressed: hasChances
                    ? () {
                        Navigator.of(context).pop();
                        widget.onSecondChance();
                      }
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Secondary: Retry Level
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'RETRY LEVEL',
                icon: Icons.replay_rounded,
                semanticsLabel: 'Retry level',
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRetry();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Actions row: LEVELS and HOME
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    fontSize: 13,
                    semanticsLabel: 'Select level',
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onLevelSelect();
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    fontSize: 13,
                    semanticsLabel: 'Return home',
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onHome();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
