import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snake_game/theme/app_colors.dart';

/// Canvas Theme configuration defining board aesthetics and snake recoloring.
class CanvasTheme {
  final String id;
  final String name;
  final String description;
  final int unlockScore;
  final Color boardLight;
  final Color boardDark;
  final Color boardFrame;
  final Color boardGrid;
  final double? snakeTargetHue; // degrees, null = original sprite colors
  final double snakeSaturation;
  final double snakeBrightness;
  final double haloOpacity;
  final Color snakePreviewColor;

  const CanvasTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockScore,
    required this.boardLight,
    required this.boardDark,
    required this.boardFrame,
    required this.boardGrid,
    this.snakeTargetHue,
    this.snakeSaturation = 1.0,
    this.snakeBrightness = 1.0,
    this.haloOpacity = 0.24,
    required this.snakePreviewColor,
  });

  /// Detected dominant hue of the ClearCode snake body sprite (#5B7BF9 = 227.85 deg).
  static const double baseSnakeHue = 227.85;

  ColorFilter? get snakeColorFilter {
    if (snakeTargetHue == null) return null;
    return ColorFilter.matrix(colorFilterMatrix);
  }

  List<double> get colorFilterMatrix {
    if (snakeTargetHue == null) {
      return const [
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ];
    }
    return _buildMatrix(snakeTargetHue!, snakeSaturation, snakeBrightness);
  }

  static List<double> _buildMatrix(
    double targetHue,
    double sat,
    double bright,
  ) {
    final deltaDeg = targetHue - baseSnakeHue;
    final rad = deltaDeg * math.pi / 180.0;
    final c = math.cos(rad);
    final s = math.sin(rad);

    const lumR = 0.213;
    const lumG = 0.715;
    const lumB = 0.072;

    final hMat = [
      lumR + c * (1.0 - lumR) - s * lumR,
      lumG - c * lumG - s * lumG,
      lumB - c * lumB + s * (1.0 - lumB),
      0.0,
      0.0,
      lumR - c * lumR + s * 0.143,
      lumG + c * (1.0 - lumG) + s * 0.140,
      lumB - c * lumB - s * 0.283,
      0.0,
      0.0,
      lumR - c * lumR - s * (1.0 - lumR),
      lumG - c * lumG + s * 0.715,
      lumB + c * (1.0 - lumB) + s * 0.072,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];

    final sMat = [
      lumR * (1.0 - sat) + sat,
      lumG * (1.0 - sat),
      lumB * (1.0 - sat),
      0.0,
      0.0,
      lumR * (1.0 - sat),
      lumG * (1.0 - sat) + sat,
      lumB * (1.0 - sat),
      0.0,
      0.0,
      lumR * (1.0 - sat),
      lumG * (1.0 - sat),
      lumB * (1.0 - sat) + sat,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];

    // Multiply sMat x hMat
    final combined = List<double>.filled(20, 0.0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += sMat[row * 5 + k] * hMat[k * 5 + col];
        }
        if (col == 4) sum += sMat[row * 5 + 4];
        combined[row * 5 + col] = sum;
      }
    }

    // Scale RGB rows by brightness
    for (int i = 0; i < 15; i++) {
      combined[i] *= bright;
    }

    return combined;
  }
}

/// The available canvas themes in progression order.
const List<CanvasTheme> kCanvasThemes = [
  CanvasTheme(
    id: 'meadow',
    name: 'Fresh Meadow',
    description: 'Lush grass & classic periwinkle snake',
    unlockScore: 0,
    boardLight: AppColors.boardLight,
    boardDark: AppColors.boardDark,
    boardFrame: AppColors.boardFrame,
    boardGrid: AppColors.boardGrid,
    snakeTargetHue: null,
    snakeSaturation: 1.0,
    snakeBrightness: 1.0,
    haloOpacity: 0.24,
    snakePreviewColor: Color(0xFF5B7BF9),
  ),
  CanvasTheme(
    id: 'ocean',
    name: 'Ocean Breeze',
    description: 'Soothing tide & coral orange snake',
    unlockScore: 15,
    boardLight: Color(0xFFA9DDF0),
    boardDark: Color(0xFF9AD3E8),
    boardFrame: Color(0xFF4FA3C7),
    boardGrid: Color(0x332B6F8F),
    snakeTargetHue: 18.0,
    snakeSaturation: 1.0,
    snakeBrightness: 1.0,
    haloOpacity: 0.24,
    snakePreviewColor: Color(0xFFD96B23),
  ),
  CanvasTheme(
    id: 'desert',
    name: 'Sunset Desert',
    description: 'Warm golden sands & regal purple snake',
    unlockScore: 35,
    boardLight: Color(0xFFF4DDA8),
    boardDark: Color(0xFFEDD398),
    boardFrame: Color(0xFFC99A4A),
    boardGrid: Color(0x33A8793A),
    snakeTargetHue: 275.0,
    snakeSaturation: 1.0,
    snakeBrightness: 1.0,
    haloOpacity: 0.24,
    snakePreviewColor: Color(0xFFC15EEB),
  ),
  CanvasTheme(
    id: 'candy',
    name: 'Candy Pop',
    description: 'Pastel sugar & vibrant aqua snake',
    unlockScore: 60,
    boardLight: Color(0xFFFBCFE3),
    boardDark: Color(0xFFF7C0DA),
    boardFrame: Color(0xFFE58AB5),
    boardGrid: Color(0x33B84C80),
    snakeTargetHue: 185.0,
    snakeSaturation: 1.0,
    snakeBrightness: 1.0,
    haloOpacity: 0.24,
    snakePreviewColor: Color(0xFF1097C1),
  ),
  CanvasTheme(
    id: 'frost',
    name: 'Frosty Peak',
    description: 'Glacial peaks & brilliant magenta snake',
    unlockScore: 100,
    boardLight: Color(0xFFE6F1F9),
    boardDark: Color(0xFFD8E8F4),
    boardFrame: Color(0xFF9DBBD3),
    boardGrid: Color(0x33426E8F),
    snakeTargetHue: 320.0,
    snakeSaturation: 1.0,
    snakeBrightness: 1.0,
    haloOpacity: 0.24,
    snakePreviewColor: Color(0xFFFA559B),
  ),
  CanvasTheme(
    id: 'midnight',
    name: 'Midnight Neon',
    description: 'Deep night sky & glowing neon lime snake',
    unlockScore: 150,
    boardLight: Color(0xFF2E3B5A),
    boardDark: Color(0xFF27334F),
    boardFrame: Color(0xFF141C30),
    boardGrid: Color(0x26AAB8E0),
    snakeTargetHue: 90.0,
    snakeSaturation: 1.15,
    snakeBrightness: 1.1,
    haloOpacity: 0.35,
    snakePreviewColor: Color(0xFF41AE00),
  ),
];
