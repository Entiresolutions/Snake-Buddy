// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snake_game/levels/level_model.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/widgets/app_card.dart';

class LevelIntroCard extends StatefulWidget {
  final LevelConfig level;
  final VoidCallback onDismiss;

  const LevelIntroCard({
    super.key,
    required this.level,
    required this.onDismiss,
  });

  @override
  State<LevelIntroCard> createState() => _LevelIntroCardState();
}

class _LevelIntroCardState extends State<LevelIntroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );

    _anim.forward();

    _autoDismissTimer = Timer(const Duration(milliseconds: 1800), () {
      _close();
    });
  }

  void _close() {
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    _anim.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: Container(
        color: Colors.black.withOpacity(0.35),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: child,
              ),
            );
          },
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    widget.level.tierName.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'LEVEL ${widget.level.id}',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.level.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'GOAL: Score 100 points',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.level.newMechanicHint != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.foodBananaHalo,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: AppColors.foodBanana.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          size: 20,
                          color: AppColors.foodBananaText,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            widget.level.newMechanicHint!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tap anywhere to start',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
