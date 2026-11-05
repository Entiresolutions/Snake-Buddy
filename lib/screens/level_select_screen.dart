// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/levels/level_catalog.dart';
import 'package:snake_game/levels/level_model.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/ui/screens/snake/snake_play_screen.dart';
import 'package:snake_game/widgets/app_card.dart';
import 'package:snake_game/widgets/responsive_scaffold.dart';
import 'package:snake_game/widgets/stat_chip.dart';

class LevelSelectScreen extends StatefulWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;
  final CampaignController campaign;

  const LevelSelectScreen({
    super.key,
    required this.settings,
    required this.canvasThemes,
    required this.campaign,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int? _shakingLevelId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onLevelTap(LevelConfig level) {
    final isUnlocked = widget.campaign.isLevelUnlocked(level.id);
    if (!isUnlocked) {
      setState(() => _shakingLevelId = level.id);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _shakingLevelId = null);
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clear Level ${level.id - 1} to unlock!',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDeep,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      );
      return;
    }

    widget.campaign.startLevel(level.id, resetRunScore: true);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SnakePlayScreen(
          settings: widget.settings,
          canvasThemes: widget.canvasThemes,
          campaign: widget.campaign,
          initialLevelId: level.id,
          showIntro: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.campaign,
      builder: (context, child) {
        return ResponsiveScaffold(
          centerContent: false,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back to Home',
            ),
            title: const Text('SELECT LEVEL'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(
                  child: StatChip(
                    label: 'Stars',
                    value: '${widget.campaign.totalStars}/90',
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final crossAxisCount = isWide ? 5 : 3;

              // Group levels by tier (1 to 6)
              final tiers = <int, List<LevelConfig>>{};
              for (final lvl in kLevelCatalog) {
                tiers.putIfAbsent(lvl.tier, () => []).add(lvl);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: tiers.length,
                itemBuilder: (context, index) {
                  final tierNumber = index + 1;
                  final tierLevels = tiers[tierNumber] ?? [];
                  final tierName = tierLevels.first.tierName;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Center(
                                  child: Text(
                                    '$tierNumber',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primaryDeep,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                tierName.toUpperCase(),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.primaryDeep,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: AppSpacing.sm,
                              mainAxisSpacing: AppSpacing.sm,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: tierLevels.length,
                            itemBuilder: (context, itemIdx) {
                              final level = tierLevels[itemIdx];
                              return _buildLevelTile(level);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLevelTile(LevelConfig level) {
    final isUnlocked = widget.campaign.isLevelUnlocked(level.id);
    final isCurrent = level.id == widget.campaign.highestUnlockedLevel;
    final stars = widget.campaign.getStarsForLevel(level.id);
    final isShaking = _shakingLevelId == level.id;

    Widget tile = Container(
      key: ValueKey('level_tile_${level.id}'),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isCurrent ? AppColors.surface : AppColors.surfaceSubtle)
            : AppColors.surfaceMuted.withOpacity(0.5),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: isCurrent
              ? AppColors.primary
              : (isUnlocked ? AppColors.border : AppColors.border.withOpacity(0.4)),
          width: isCurrent ? 2.2 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.mdRadius,
          onTap: () => _onLevelTap(level),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Badge in top right: Crown for Boss, Flag for mini-boss
              if (level.isBoss)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.foodBanana,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (level.id % 5 == 0)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.accentLime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isUnlocked) ...[
                    Text(
                      '${level.id}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isCurrent
                            ? AppColors.primaryDeep
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Stars row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (sIdx) {
                        final earned = sIdx < stars;
                        return Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: earned
                              ? AppColors.foodBananaText
                              : AppColors.border,
                        );
                      }),
                    ),
                  ] else ...[
                    Icon(
                      Icons.lock_rounded,
                      size: 24,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${level.id}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (isShaking) {
      tile = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        builder: (context, value, child) {
          final offset = sin(value * pi * 4) * 6;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: tile,
      );
    }

    return tile;
  }
}
