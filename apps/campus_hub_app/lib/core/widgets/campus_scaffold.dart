import 'package:flutter/material.dart';
import 'atmospheric_background.dart';

/// Unified CampusScaffold for CampusHub.
/// Enforces iOS-grade atmospheric glass backgrounds,
/// consistent padding, safe areas, and bottom inset management.
class CampusScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool resizeToAvoidBottomInset;
  final bool useSafeArea;
  final Color? backgroundColor;

  const CampusScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.resizeToAvoidBottomInset = true,
    this.useSafeArea = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    final scaffold = Scaffold(
      backgroundColor: backgroundColor ?? Colors.transparent,
      appBar: appBar,
      drawer: drawer,
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );

    if (backgroundColor != null) {
      return scaffold;
    }

    return AtmosphericBackground(child: scaffold);
  }
}
