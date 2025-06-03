// Bu widget, uygulama genelinde kullanılan temel sayfa yapısını oluşturur.
// Özelleştirilmiş app bar, drawer ve içerik alanı gibi ortak bileşenleri içerir.

import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_drawer.dart';

class BasePage extends StatelessWidget {
  // Sayfa özellikleri
  final String title;                  // Sayfa başlığı
  final Widget content;                // Sayfa içeriği
  final List<Widget>? actions;         // App bar'da gösterilecek ek aksiyonlar
  final bool showDrawer;               // Drawer menüsünün gösterilip gösterilmeyeceği
  final Color? backgroundColor;        // Sayfa arkaplan rengi
  
  // Kaydet butonu özellikleri
  final bool showSaveButton;           // Kaydet butonunun gösterilip gösterilmeyeceği
  final VoidCallback? onSavePressed;   // Kaydet butonu tıklama işlevi
  
  // Bilgi butonu özellikleri
  final bool showInfoButton;           // Bilgi butonunun gösterilip gösterilmeyeceği
  final VoidCallback? onInfoPressed;   // Bilgi butonu tıklama işlevi
  
  // Yenileme butonu özellikleri
  final bool showRefreshButton;        // Yenileme butonunun gösterilip gösterilmeyeceği
  final VoidCallback? onRefreshPressed;// Yenileme butonu tıklama işlevi
  
  // Özel başlık alanı widget'ı
  final Widget? leading;

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
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // Özelleştirilmiş uygulama çubuğu
      appBar: CustomAppBar(
        title: title,
        showSaveButton: showSaveButton,
        onSavePressed: onSavePressed,
        showInfoButton: showInfoButton,
        onInfoPressed: onInfoPressed,
        leading: leading,
        actions: [
          // Yenileme butonu (eğer aktifse)
          if (showRefreshButton && onRefreshPressed != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: onRefreshPressed,
              tooltip: 'Yenile',
            ),
          // Ek aksiyonlar (eğer varsa)
          if (actions != null) ...actions!,
        ],
      ),
      // Yan menü (eğer aktifse)
      drawer: showDrawer ? CustomDrawer() : null,
      // Sayfa içeriği
      body: content,
    );
  }
} 