import 'package:flutter/material.dart';

/// Design tokens for the "Fresh Meadow Light" theme.
/// Single source of truth for colors in the application.
abstract final class AppColors {
  // Background & Surfaces
  static const background = Color(0xFFF5F9EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEAF2DE);
  static const surfaceSubtle = Color(0xFFF0F5E8);
  static const border = Color(0xFFD5E2C7);

  // Brand & Greens
  static const primary = Color(0xFF2E7D32);
  static const primaryDeep = Color(0xFF1B5E20);
  static const primarySoft = Color(0xFFC8E6C9);
  static const accentLime = Color(0xFF76BA1B);
  static const onAccent = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFFFFFFFF);

  // Typography & Content
  static const textPrimary = Color(0xFF1A2E1C);
  static const textSecondary = Color(0xFF4A614D);
  static const textMuted = Color(0xFF728876);

  // Board (Checkerboard)
  static const boardLight = Color(0xFFAAD751);
  static const boardDark = Color(0xFFA2D149);
  static const boardFrame = Color(0xFF87B334);
  static const boardGrid = Color(0x334A752C);

  // Food Pickups & Text Variants
  static const foodApple = Color(0xFFE53935);
  static const foodAppleText = Color(0xFFC62828);
  static const foodAppleHalo = Color(0x33E53935);

  static const foodBlueberry = Color(0xFF1E88E5);
  static const foodBlueberryText = Color(0xFF1565C0);
  static const foodBlueberryHalo = Color(0x331E88E5);

  static const foodGrape = Color(0xFF8E24AA);
  static const foodGrapeText = Color(0xFF6A1B9A);
  static const foodGrapeHalo = Color(0x338E24AA);

  static const foodBanana = Color(0xFFF9A825);
  static const foodBananaText = Color(0xFFE65100);
  static const foodBananaHalo = Color(0x33F9A825);

  // Feedback & Shadows
  static const danger = Color(0xFFD32F2F);
  static const dangerSoft = Color(0xFFFFEBEE);
  static const shadow = Color(0x141A2E1C);
  static const shadowElevated = Color(0x241A2E1C);

  // Obstacles / Hazards
  static const obstacleRock = Color(0xFF5D6D4E);
  static const obstacleRockBevel = Color(0xFF7D8F6D);
  static const obstacleRockShadow = Color(0xFF38432E);

  static const portalPairA = Color(0xFF00E5FF); // Electric Cyan
  static const portalPairB = Color(0xFFE040FB); // Vivid Purple
  static const portalPairC = Color(0xFFFFAB00); // Amber
  static const portalPairD = Color(0xFF00E676); // Emerald Green

  static const obstacleSpikeOff = Color(0x384A614D); // Faint outline, safe
  static const obstacleSpikeWarn = Color(0xFFFF9800); // Amber pulse, still safe
  static const obstacleSpikeOn = Color(0xFFD32F2F); // Deadly solid danger

  static const obstaclePatrol = Color(0xFFE65100); // Deep safety orange
  static const obstaclePatrolChevron = Color(0xFFFFFFFF);
}
