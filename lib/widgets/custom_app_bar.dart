import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showInfoButton;
  final VoidCallback? onInfoPressed;
  final bool showSaveButton;
  final VoidCallback? onSavePressed;
  final Widget? leading;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showInfoButton = false,
    this.onInfoPressed,
    this.showSaveButton = false,
    this.onSavePressed,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFF5181BE),
      title: Text(title),
      leading: leading,
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