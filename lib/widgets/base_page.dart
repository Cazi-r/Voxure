import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_drawer.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showDrawer;
  final Color? backgroundColor;
  final bool showSaveButton;
  final VoidCallback? onSavePressed;
  final bool showInfoButton;
  final VoidCallback? onInfoPressed;
  final bool showRefreshButton;
  final VoidCallback? onRefreshPressed;

  const BasePage({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.showDrawer = true,
    this.backgroundColor,
    this.showSaveButton = false,
    this.onSavePressed,
    this.showInfoButton = false,
    this.onInfoPressed,
    this.showRefreshButton = false,
    this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: title,
        showSaveButton: showSaveButton,
        onSavePressed: onSavePressed,
        showInfoButton: showInfoButton,
        onInfoPressed: onInfoPressed,
        actions: [
          if (showRefreshButton && onRefreshPressed != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: onRefreshPressed,
              tooltip: 'Yenile',
            ),
          if (actions != null) ...actions!,
        ],
      ),
      drawer: showDrawer ? CustomDrawer() : null,
      body: content,
    );
  }
} 