// Bu widget, uygulama genelinde kullanılan özelleştirilmiş üst çubuğu oluşturur.
// Bilgi ve kaydetme butonları gibi ortak işlevleri içerir.

import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Temel özellikler
  final String title;                  // Üst çubuk başlığı
  final List<Widget>? actions;         // Sağ tarafta gösterilecek ek butonlar
  final Widget? leading;               // Sol tarafta gösterilecek özel widget
  
  // Bilgi butonu özellikleri
  final bool showInfoButton;           // Bilgi butonunun gösterilip gösterilmeyeceği
  final VoidCallback? onInfoPressed;   // Bilgi butonu tıklama işlevi
  
  // Kaydet butonu özellikleri
  final bool showSaveButton;           // Kaydet butonunun gösterilip gösterilmeyeceği
  final VoidCallback? onSavePressed;   // Kaydet butonu tıklama işlevi

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
        // Bilgi butonu (eğer aktifse)
        if (showInfoButton)
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'Bilgi',
            onPressed: onInfoPressed,
          ),
        // Kaydet butonu (eğer aktifse)
        if (showSaveButton)
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Kaydet',
            onPressed: onSavePressed,
          ),
        // Ek butonlar (eğer varsa)
        if (actions != null) ...actions!,
      ],
    );
  }

  // AppBar yüksekliğini belirle
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
} 