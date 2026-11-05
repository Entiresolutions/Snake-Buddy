// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snake_game/levels/level_model.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/canvas_themes.dart';

enum SpikeState { off, warn, on }

Color portalColorForLetter(String letter) {
  switch (letter.toUpperCase()) {
    case 'A':
      return AppColors.portalPairA;
    case 'B':
      return AppColors.portalPairB;
    case 'C':
      return AppColors.portalPairC;
    case 'D':
      return AppColors.portalPairD;
    default:
      return AppColors.portalPairA;
  }
}

class ObstaclePainter extends CustomPainter {
  final LevelConfig level;
  final CanvasTheme theme;
  final double cell;
  final double portalAngle;
  final double spikePulse;
  final Map<int, SpikeState> spikeStates;

  ObstaclePainter({
    required this.level,
    required this.theme,
    required this.cell,
    required this.portalAngle,
    required this.spikePulse,
    required this.spikeStates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintRocks(canvas);
    _paintSpikes(canvas);
    _paintPortals(canvas);
  }

  void _paintRocks(Canvas canvas) {
    final rockPaint = Paint()
      ..color = theme.obstacleRockColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.obstacleRockBorder
      ..strokeWidth = math.max(1.4, cell * 0.08)
      ..style = PaintingStyle.stroke;

    final bevelPaint = Paint()
      ..color = theme.obstacleRockBevel
      ..strokeWidth = math.max(1.5, cell * 0.1)
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = theme.obstacleRockShadow
      ..strokeWidth = math.max(1.5, cell * 0.1)
      ..style = PaintingStyle.stroke;

    final radius = Radius.circular(cell * 0.22);

    for (final rock in level.rocks) {
      final rect = Rect.fromLTWH(
        rock[0] * cell + 1.0,
        rock[1] * cell + 1.0,
        cell - 2.0,
        cell - 2.0,
      );
      final rrect = RRect.fromRectAndRadius(rect, radius);

      // Drop shadow below rock
      canvas.drawRRect(
        rrect.shift(const Offset(0, 1.8)),
        Paint()..color = Colors.black.withOpacity(0.28),
      );

      // Base stone fill
      canvas.drawRRect(rrect, rockPaint);

      // Top-left bevel highlight & bottom-right shadow
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawLine(
        Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.top),
        bevelPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.top),
        bevelPaint,
      );

      canvas.drawLine(
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.bottom),
        shadowPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.bottom),
        Offset(rect.right, rect.bottom),
        shadowPaint,
      );
      canvas.restore();

      // Outer border stroke for crisp silhouette
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  void _paintSpikes(Canvas canvas) {
    for (int groupIdx = 1; groupIdx <= 4; groupIdx++) {
      final cells = level.spikes[groupIdx];
      if (cells == null || cells.isEmpty) continue;

      final state = spikeStates[groupIdx] ?? SpikeState.off;

      for (final pt in cells) {
        final cx = (pt[0] + 0.5) * cell;
        final cy = (pt[1] + 0.5) * cell;
        final half = (cell - 4.0) / 2;

        if (state == SpikeState.off) {
          // Safe state: visible retracted trap plate
          final baseRect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: cell * 0.74, height: cell * 0.74),
            Radius.circular(cell * 0.15),
          );
          // Base plate fill
          canvas.drawRRect(
            baseRect,
            Paint()
              ..color = theme.obstacleSpikeBaseColor
              ..style = PaintingStyle.fill,
          );
          // Base plate border
          canvas.drawRRect(
            baseRect,
            Paint()
              ..color = theme.obstacleSpikeOffColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
          // Recessed center dot showing inactive pit
          canvas.drawCircle(
            Offset(cx, cy),
            cell * 0.10,
            Paint()..color = theme.obstacleSpikeOffColor,
          );
        } else if (state == SpikeState.warn) {
          // Warning state: pulsing amber / orange
          final pulseAlpha = (0.5 + 0.5 * spikePulse).clamp(0.0, 1.0);
          final color = AppColors.obstacleSpikeWarn.withOpacity(pulseAlpha);

          final warnRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: cell * (0.75 + 0.08 * spikePulse),
              height: cell * (0.75 + 0.08 * spikePulse),
            ),
            Radius.circular(cell * 0.18),
          );
          canvas.drawRRect(
            warnRect,
            Paint()
              ..color = color.withOpacity(0.2)
              ..style = PaintingStyle.fill,
          );
          canvas.drawRRect(
            warnRect,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );

          // Warning hazard triangle / diamond
          final path = Path()
            ..moveTo(cx, cy - half * 0.6)
            ..lineTo(cx + half * 0.6, cy + half * 0.6)
            ..lineTo(cx - half * 0.6, cy + half * 0.6)
            ..close();
          canvas.drawPath(path, Paint()..color = color);
        } else {
          // Deadly ON state: solid danger red with 4 sharp protruding spikes
          final onColor = AppColors.obstacleSpikeOn;

          // Danger base
          final baseRect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: cell * 0.82, height: cell * 0.82),
            Radius.circular(cell * 0.15),
          );
          canvas.drawRRect(
            baseRect,
            Paint()..color = onColor.withOpacity(0.25),
          );
          canvas.drawRRect(
            baseRect,
            Paint()
              ..color = onColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );

          // 4 menacing spike points radiating from center
          final spikePath = Path();
          final tipDist = half * 0.85;
          final baseDist = half * 0.35;

          // Up spike
          spikePath.moveTo(cx, cy - tipDist);
          spikePath.lineTo(cx - baseDist, cy);
          spikePath.lineTo(cx + baseDist, cy);
          spikePath.close();

          // Down spike
          spikePath.moveTo(cx, cy + tipDist);
          spikePath.lineTo(cx - baseDist, cy);
          spikePath.lineTo(cx + baseDist, cy);
          spikePath.close();

          // Left spike
          spikePath.moveTo(cx - tipDist, cy);
          spikePath.lineTo(cx, cy - baseDist);
          spikePath.lineTo(cx, cy + baseDist);
          spikePath.close();

          // Right spike
          spikePath.moveTo(cx + tipDist, cy);
          spikePath.lineTo(cx, cy - baseDist);
          spikePath.lineTo(cx, cy + baseDist);
          spikePath.close();

          canvas.drawPath(spikePath, Paint()..color = onColor);

          // Sharp metallic core
          canvas.drawCircle(
            Offset(cx, cy),
            cell * 0.14,
            Paint()..color = Colors.white.withOpacity(0.9),
          );
        }
      }
    }
  }

  void _paintPortals(Canvas canvas) {
    for (final entry in level.portals.entries) {
      final pairLetter = entry.key;
      final points = entry.value;
      final pairColor = portalColorForLetter(pairLetter);

      for (final pt in points) {
        final cx = (pt[0] + 0.5) * cell;
        final cy = (pt[1] + 0.5) * cell;
        final r = cell * 0.42;

        // Outer soft glow
        canvas.drawCircle(
          Offset(cx, cy),
          r + 2.0,
          Paint()
            ..color = pairColor.withOpacity(0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
        );

        // Dark portal void center
        canvas.drawCircle(
          Offset(cx, cy),
          r * 0.75,
          Paint()..color = const Color(0xFF10141D),
        );

        // Animated swirling rings
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(portalAngle);

        final ringPaint = Paint()
          ..color = pairColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2.0, cell * 0.1);

        // Arc 1
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.8),
          0,
          math.pi * 0.85,
          false,
          ringPaint,
        );

        // Arc 2
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.8),
          math.pi,
          math.pi * 0.85,
          false,
          ringPaint,
        );

        // Counter-rotating inner arc
        canvas.rotate(-portalAngle * 2.2);
        final innerRingPaint = Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.5, cell * 0.07);

        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.48),
          0,
          math.pi * 0.9,
          false,
          innerRingPaint,
        );

        canvas.restore();

        // Glowing center core
        canvas.drawCircle(
          Offset(cx, cy),
          r * 0.22,
          Paint()..color = pairColor.withOpacity(0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ObstaclePainter old) =>
      old.portalAngle != portalAngle ||
      old.spikePulse != spikePulse ||
      old.spikeStates != spikeStates ||
      old.cell != cell ||
      old.theme != theme ||
      old.level != level;
}
