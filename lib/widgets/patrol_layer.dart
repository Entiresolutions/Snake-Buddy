// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_radius.dart';
import 'package:snake_game/theme/canvas_themes.dart';

class PatrolBlockData {
  final int id;
  final int x;
  final int y;
  final int size; // 1 or 2
  final String direction; // 'up', 'down', 'left', 'right'

  const PatrolBlockData({
    required this.id,
    required this.x,
    required this.y,
    this.size = 1,
    required this.direction,
  });
}

class PatrolLayer extends StatelessWidget {
  final List<PatrolBlockData> patrols;
  final double cell;
  final Duration duration;
  final CanvasTheme? theme;

  const PatrolLayer({
    super.key,
    required this.patrols,
    required this.cell,
    required this.duration,
    this.theme,
  });

  IconData _iconForDirection(String dir) {
    switch (dir) {
      case 'up':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'down':
        return Icons.keyboard_double_arrow_down_rounded;
      case 'left':
        return Icons.keyboard_double_arrow_left_rounded;
      case 'right':
        return Icons.keyboard_double_arrow_right_rounded;
      default:
        return Icons.double_arrow_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor = theme?.obstaclePatrolColor ?? AppColors.obstaclePatrol;
    final borderColor = theme?.obstaclePatrolBorder ?? Colors.white.withOpacity(0.9);
    final chevronColor = theme?.obstaclePatrolChevron ?? AppColors.obstaclePatrolChevron;

    return Stack(
      children: [
        for (final p in patrols)
          AnimatedPositioned(
            key: ValueKey('patrol_${p.id}'),
            left: p.x * cell + 1.0,
            top: p.y * cell + 1.0,
            width: (p.direction == 'left' || p.direction == 'right'
                    ? (p.size * cell)
                    : cell) -
                2.0,
            height: (p.direction == 'up' || p.direction == 'down'
                    ? (p.size * cell)
                    : cell) -
                2.0,
            duration: duration,
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: borderColor,
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _iconForDirection(p.direction),
                  color: chevronColor,
                  size: cell * 0.65,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
