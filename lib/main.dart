import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/theme/app_theme.dart';
import 'package:snake_game/ui/screens/intro_video_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlay);
  final settings = SettingsController();
  final canvasThemes = CanvasThemeController();
  final campaign = CampaignController();
  runApp(
    SnakeApp(
      settings: settings,
      canvasThemes: canvasThemes,
      campaign: campaign,
    ),
  );
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        unawaited(
          MobileAds.instance.initialize().then((_) {}, onError: (_) {}),
        );
      } catch (_) {}
    });
  }
}

class SnakeApp extends StatelessWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;
  final CampaignController campaign;
  final Widget? home;

  SnakeApp({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
    CampaignController? campaign,
    this.home,
  })  : canvasThemes = canvasThemes ?? CanvasThemeController(),
        campaign = campaign ?? CampaignController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Buddy',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      home: home ??
          IntroVideoScreen(
            settings: settings,
            canvasThemes: canvasThemes,
            campaign: campaign,
          ),
    );
  }
}
