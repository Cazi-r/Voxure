import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showInfoButton;
  final VoidCallback? onInfoPressed;
  final bool showSaveButton;
  final VoidCallback? onSavePressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showInfoButton = false,
    this.onInfoPressed,
    this.showSaveButton = false,
    this.onSavePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFF5181BE),
      title: Text(title),
      actions: [
        if (showInfoButton)
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'Bilgi',
            onPressed: onInfoPressed,
          ),
        if (showSaveButton)
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Kaydet',
            onPressed: onSavePressed,
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
} 