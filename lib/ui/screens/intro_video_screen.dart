import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/splash_screen.dart';
import 'package:snake_game/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

/// Plays an introduction video seamlessly before the Splash Screen.
/// Pure white canvas, completely silent, with auto-advance and tap-to-advance.
class IntroVideoScreen extends StatefulWidget {
  final SettingsController settings;
  final CanvasThemeController canvasThemes;
  final CampaignController campaign;

  IntroVideoScreen({
    super.key,
    required this.settings,
    CanvasThemeController? canvasThemes,
    CampaignController? campaign,
  })  : canvasThemes = canvasThemes ?? CanvasThemeController(),
        campaign = campaign ?? CampaignController();

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  static const String _kVideoAsset = 'assets/splah_before.mp4';

  VideoPlayerController? _controller;
  Timer? _autoAdvanceTimer;
  bool _isInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initAndPlayVideo();
  }

  Future<void> _initAndPlayVideo() async {
    try {
      final controller = VideoPlayerController.asset(_kVideoAsset);
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      // Video must play completely SILENTLY
      await controller.setVolume(0.0);

      // Loop must be disabled
      await controller.setLooping(false);

      controller.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
      });

      await controller.play();

      // Master fallback timer: automatically transitions exactly when video duration finishes
      final duration = controller.value.duration;
      if (duration > Duration.zero) {
        _autoAdvanceTimer?.cancel();
        _autoAdvanceTimer = Timer(duration, _navigateToSplash);
      }
    } catch (_) {
      // If video initialization fails (e.g. test environment or format error),
      // gracefully advance to splash screen without hanging.
      _navigateToSplash();
    }
  }

  void _videoListener() {
    if (!mounted || _hasNavigated) return;
    final controller = _controller;
    if (controller == null) return;

    final value = controller.value;
    if (value.hasError) {
      _navigateToSplash();
      return;
    }

    if (value.isInitialized && value.duration > Duration.zero) {
      // Auto-advance if completed, or reached within 200ms of end and paused, or position >= duration
      final bool isFinished = value.isCompleted ||
          (value.position >=
                  value.duration - const Duration(milliseconds: 200) &&
              !value.isPlaying) ||
          (value.position >= value.duration);

      if (isFinished) {
        _navigateToSplash();
      }
    }
  }

  void _navigateToSplash() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    _controller?.removeListener(_videoListener);

    void doNavigate() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => SplashScreen(
            settings: widget.settings,
            canvasThemes: widget.canvasThemes,
            campaign: widget.campaign,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => doNavigate());
    } else {
      doNavigate();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    // Restore the app's default system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlay);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final hasValidSize = _isInitialized &&
        controller != null &&
        controller.value.size.width > 0 &&
        controller.value.size.height > 0;

    final videoWidth = hasValidSize ? controller.value.size.width : 1080.0;
    final videoHeight = hasValidSize ? controller.value.size.height : 1920.0;
    final videoAspectRatio = hasValidSize
        ? controller.value.aspectRatio
        : (videoWidth / videoHeight);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToSplash,
          child: SizedBox.expand(
            child: Container(
              color: Colors.white,
              child: Center(
                child: _isInitialized && controller != null
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: videoWidth,
                          height: videoHeight,
                          child: AspectRatio(
                            aspectRatio: videoAspectRatio,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
