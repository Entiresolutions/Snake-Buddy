import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/splash_screen.dart';
import 'package:snake_game/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
}

class SnakeApp extends StatelessWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;
  final CampaignController campaign;

  SnakeApp({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
    CampaignController? campaign,
  })  : canvasThemes = canvasThemes ?? CanvasThemeController(),
        campaign = campaign ?? CampaignController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Buddy',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      home: SplashScreen(
        settings: settings,
        canvasThemes: canvasThemes,
        campaign: campaign,
      ),
    );
  }
}
