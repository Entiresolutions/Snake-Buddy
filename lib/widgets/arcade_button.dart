import 'package:flutter/material.dart';
import 'package:snake_game/widgets/primary_button.dart';
import 'package:snake_game/widgets/secondary_button.dart';

@Deprecated('Use PrimaryButton or SecondaryButton instead')
class ArcadeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final IconData? icon;

  const ArcadeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SecondaryButton(
        label: label,
        icon: icon,
        onPressed: onPressed,
      );
    }
    return PrimaryButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }
}
