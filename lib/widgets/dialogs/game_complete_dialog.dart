// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';
import 'package:snake_game/widgets/primary_button.dart';
import 'package:snake_game/widgets/secondary_button.dart';
import 'package:snake_game/widgets/stat_chip.dart';

class GameCompleteDialog extends StatefulWidget {
  final int totalStars;
  final int runScore;
  final int bestRunScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onLevelSelect;
  final VoidCallback onHome;

  const GameCompleteDialog({
    super.key,
    required this.totalStars,
    required this.runScore,
    required this.bestRunScore,
    required this.onPlayAgain,
    required this.onLevelSelect,
    required this.onHome,
  });

  @override
  State<GameCompleteDialog> createState() => _GameCompleteDialogState();
}

class _GameCompleteDialogState extends State<GameCompleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  static const _fruitImages = [
    'assets/images/apple.png',
    'assets/images/blueberry.png',
    'assets/images/grape.png',
    'assets/images/banana.png',
  ];

  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(28, (index) {
      return _ConfettiParticle(
        asset: _fruitImages[rng.nextInt(_fruitImages.length)],
        startX: rng.nextDouble(),
        speedY: 0.6 + rng.nextDouble() * 0.8,
        speedX: (rng.nextDouble() - 0.5) * 0.4,
        size: 16.0 + rng.nextDouble() * 16.0,
        rotationSpeed: (rng.nextDouble() - 0.5) * 4.0,
      );
    });

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Stack(
      children: [
        if (!disableAnimations)
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (context, child) {
              final t = _confettiCtrl.value;
              return IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: t,
                  ),
                ),
              );
            },
          ),
        Center(
          child: Dialog(
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
                    // Giant Trophy
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.foodBananaText,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'YOU WIN!',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'ALL 30 LEVELS CLEARED',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: StatChip(
                            compact: true,
                            label: 'Stars',
                            value: '${widget.totalStars}/90',
                            icon: const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.foodBananaText,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: StatChip(
                            compact: true,
                            label: 'Final Score',
                            value: '${widget.runScore}',
                            icon: const Icon(
                              Icons.circle,
                              size: 8,
                              color: AppColors.foodApple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatChip(
                      compact: true,
                      label: 'Best Run Score',
                      value: '${widget.bestRunScore}',
                      icon: const Icon(
                      Icons.emoji_events_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'PLAY AGAIN',
                      icon: Icons.replay_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onPlayAgain();
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
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final String asset;
  final double startX;
  final double speedY;
  final double speedX;
  final double size;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.asset,
    required this.startX,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    for (final p in particles) {
      final x = (p.startX + p.speedX * progress) * size.width;
      final y = -p.size + (p.speedY * progress * (size.height + p.size * 2));
      final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * math.pi * 2);
      final r = p.size / 2;
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..color = AppColors.foodApple.withOpacity(opacity * 0.7)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
