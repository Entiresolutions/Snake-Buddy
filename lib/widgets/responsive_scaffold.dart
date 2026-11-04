import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/theme/app_colors.dart';
import 'package:snake_game/theme/app_theme.dart';
import 'package:snake_game/widgets/responsive.dart';

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;
  final bool useSafeArea;
  final bool centerContent;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding,
    this.useSafeArea = true,
    this.centerContent = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (centerContent) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Responsive.maxContentWidth,
          ),
          child: content,
        ),
      );
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlay,
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppColors.background,
        appBar: appBar,
        body: content,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
