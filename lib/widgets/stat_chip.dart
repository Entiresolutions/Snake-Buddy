import 'package:flutter/material.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/app_spacing.dart';
import 'package:snake_game/theme/app_text_styles.dart';

class StatChip extends StatefulWidget {
  final String label;
  final String value;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? valueColor;
  final bool animateOnChange;
  final String? semanticsLabel;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.valueColor,
    this.animateOnChange = true,
    this.semanticsLabel,
  });

  @override
  State<StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<StatChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_popController);
  }

  @override
  void didUpdateWidget(StatChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateOnChange && oldWidget.value != widget.value) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColors.surface;
    final border = widget.borderColor ?? AppColors.border;
    final valColor = widget.valueColor ?? AppColors.primaryDeep;

    return Semantics(
      label: widget.semanticsLabel ?? '${widget.label}: ${widget.value}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: border, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Text(
                widget.label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedBuilder(
                animation: _popAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _popAnimation.value,
                  child: child,
                ),
                child: Text(
                  widget.value,
                  style: AppTextStyles.scoreChip.copyWith(
                    color: valColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
