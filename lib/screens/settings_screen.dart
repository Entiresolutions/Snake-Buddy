import 'dart:math';
import 'package:flutter/material.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/theme_screen.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/widgets/app_card.dart';
import 'package:snake_game/widgets/responsive_scaffold.dart';
import 'package:snake_game/widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;

  SettingsScreen({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
  }) : canvasThemes = canvasThemes ?? CanvasThemeController();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([settings, canvasThemes]),
        builder: (context, child) => ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const _SectionHeading('APPEARANCE'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: SettingsTile(
                title: 'Theme',
                subtitle:
                    '${canvasThemes.selectedTheme.name} · ${canvasThemes.unlockedCount}/${canvasThemes.totalCount} unlocked',
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.primaryDeep,
                    size: 20,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        canvasThemes.selectedTheme.boardLight,
                        canvasThemes.selectedTheme.boardFrame,
                        canvasThemes.selectedTheme.snakePreviewColor,
                      ].map((c) {
                        return Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 3),
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
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ThemeScreen(
                        settings: settings,
                        canvasThemes: canvasThemes,
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slide,
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeading('AUDIO & FEEDBACK'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  SettingsTile(
                    title: 'Sound effects',
                    leading: const Icon(
                      Icons.volume_up_outlined,
                      color: AppColors.primary,
                    ),
                    trailing: Switch.adaptive(
                      value: settings.soundEnabled,
                      onChanged: settings.setSoundEnabled,
                    ),
                  ),
                  const Divider(height: 1, indent: 48, color: AppColors.surfaceMuted),
                  SettingsTile(
                    title: 'Vibration',
                    leading: const Icon(
                      Icons.vibration_outlined,
                      color: AppColors.primary,
                    ),
                    trailing: Switch.adaptive(
                      value: settings.vibrationEnabled,
                      onChanged: settings.setVibrationEnabled,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeading('GAMEPLAY'),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Difficulty',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Easy: 300ms · Normal: 240ms · Hard: 160ms',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: max(constraints.maxWidth, 290.0),
                        child: SegmentedButton<GameDifficulty>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: GameDifficulty.easy,
                              label: Text('Easy'),
                            ),
                            ButtonSegment(
                              value: GameDifficulty.normal,
                              label: Text('Normal'),
                            ),
                            ButtonSegment(
                              value: GameDifficulty.hard,
                              label: Text('Hard'),
                            ),
                          ],
                          selected: {settings.difficulty},
                          onSelectionChanged: (selected) {
                            if (selected.isNotEmpty) {
                              settings.setDifficulty(selected.first);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1, color: AppColors.surfaceMuted),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.gamepad_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Control Type',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: max(constraints.maxWidth, 290.0),
                        child: SegmentedButton<ControlType>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: ControlType.swipe,
                              label: Text('Swipe'),
                              icon: Icon(Icons.swipe_outlined),
                            ),
                            ButtonSegment(
                              value: ControlType.buttons,
                              label: Text('D-Pad'),
                              icon: Icon(Icons.touch_app_outlined),
                            ),
                          ],
                          selected: {settings.controls},
                          onSelectionChanged: (selected) {
                            if (selected.isNotEmpty) {
                              settings.setControls(selected.first);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1, color: AppColors.surfaceMuted),
                  SettingsTile(
                    title: 'Show grid lines',
                    leading: const Icon(
                      Icons.grid_4x4_rounded,
                      color: AppColors.primary,
                    ),
                    trailing: Switch.adaptive(
                      value: settings.showGridLines,
                      onChanged: settings.setShowGridLines,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                'Snake Buddy · Fresh Meadow Light · Version 2.0',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primaryDeep,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
