import 'dart:math' as math;
import 'package:flutter/material.dart';

enum DeviceSizeClass {
  compact,
  medium,
  expanded;

  static DeviceSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return DeviceSizeClass.compact;
    if (width < 840) return DeviceSizeClass.medium;
    return DeviceSizeClass.expanded;
  }
}

abstract final class Responsive {
  static const double maxContentWidth = 640.0;
  static const int boardCols = 15;
  static const int boardRows = 20;

  static bool isTablet(BuildContext context) =>
      DeviceSizeClass.of(context) != DeviceSizeClass.compact;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static double textScaleFactor(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 1.3);
  }

  /// Exact integer cell size calculation per DESIGN.md section 8.1:
  /// clamp(floor(min(availW / 15, availH / 20)), 16, 44)
  static double calculateCellSize({
    required double availableWidth,
    required double availableHeight,
    int cols = boardCols,
    int rows = boardRows,
    double minCell = 16.0,
    double maxCell = 44.0,
  }) {
    if (availableWidth <= 0 || availableHeight <= 0) return minCell;
    final fitW = availableWidth / cols;
    final fitH = availableHeight / rows;
    final raw = math.min(fitW, fitH).floorToDouble();
    return raw.clamp(minCell, maxCell);
  }

  static Size calculateBoardSize({
    required double availableWidth,
    required double availableHeight,
    int cols = boardCols,
    int rows = boardRows,
    double minCell = 16.0,
    double maxCell = 44.0,
  }) {
    final cell = calculateCellSize(
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      cols: cols,
      rows: rows,
      minCell: minCell,
      maxCell: maxCell,
    );
    return Size(cell * cols, cell * rows);
  }
}
