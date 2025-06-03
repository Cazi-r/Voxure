// Bu widget, uygulama genelinde kullanılan özelleştirilmiş yan menüyü oluşturur.
// Kullanıcı profili, navigasyon menüsü ve çıkış işlemlerini yönetir.

import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';

class CustomDrawer extends StatefulWidget {
  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  // Servis örnekleri
  final FirebaseService _firebaseService = FirebaseService();
  final SupabaseService _supabaseService = SupabaseService(Supabase.instance.client);
  final AuthService _authService = AuthService();
  
  // Durum değişkenleri
  String? _logoUrl;                    // Uygulama logosu URL'i
  bool _isLoggingOut = false;          // Çıkış işlemi durumu

  @override
  void initState() {
    super.initState();
    _loadLogo();  // Widget oluşturulduğunda logoyu yükle
  }

  // Uygulama logosunu yükleme
  Future<void> _loadLogo() async {
    try {
      final logoUrl = await _supabaseService.getAppLogo();
      if (mounted) {
        setState(() {
          _logoUrl = logoUrl;
        });
      }
    } catch (e) {
      print('Logo yuklenirken hata: $e');
    }
  }

  // Sayfa yönlendirme işlemi
  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);  // Drawer'ı kapat
    if (ModalRoute.of(context)?.settings.name != route) {  // Aynı sayfada değilsek yönlendir
      Navigator.pushReplacementNamed(context, route);
    }
  }

  // Çıkış işlemini gerçekleştirme
  Future<void> _handleLogout(BuildContext context) async {
    print('CustomDrawer: Cikis islemi baslatiliyor...');
    try {
      setState(() {
        _isLoggingOut = true;
      });
      print('CustomDrawer: Loading durumu aktif edildi');

      print('CustomDrawer: AuthService.signOut() cagiriliyor...');
      await _authService.signOut();
      print('CustomDrawer: AuthService.signOut() basariyla tamamlandi');

      print('CustomDrawer: Login sayfasina yonlendirme yapiliyor...');
      if (!mounted) {
        print('CustomDrawer: Widget artik mounted degil, islem iptal ediliyor');
        return;
      }

      setState(() {
        _isLoggingOut = false;
      });
      print('CustomDrawer: Loading durumu kapatildi');

      await Future.delayed(Duration.zero, () {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        print('CustomDrawer: Yonlendirme basarili');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cikis yapildi'),
            duration: Duration(seconds: 2),
          ),
        );
        print('CustomDrawer: Basarili cikis bildirimi gosterildi');
      });

    } catch (e, stackTrace) {
      print('CustomDrawer: Cikis sirasinda hata olustu:');
      print('Hata: $e');
      print('Stack Trace: $stackTrace');
      
      if (!mounted) {
        print('CustomDrawer: Widget artik mounted degil, hata mesaji gosterilemeyecek');
        return;
      }

      setState(() {
        _isLoggingOut = false;
      });
      print('CustomDrawer: Hata sonrasi loading durumu kapatildi');
      
      String errorMessage = 'Cikis yaparken bir hata olustu';
      if (e is Exception) {
        errorMessage += ': ${e.toString().replaceAll('Exception: ', '')}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      print('CustomDrawer: Hata bildirimi gosterildi');
    }
  }

  // Çıkış onay dialogunu gösterme
  void _logout(BuildContext context) {
    print('CustomDrawer: Cikis dialog\'u gosteriliyor');
    if (_isLoggingOut) {
      print('CustomDrawer: Cikis islemi zaten devam ediyor, dialog gosterilmeyecek');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,  // Dialog dışına tıklayarak kapatmayı engelle
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => !_isLoggingOut,  // Çıkış sırasında geri tuşunu devre dışı bırak
          child: AlertDialog(
            title: const Text('Cikis'),
            content: const Text('Cikmak istediginize emin misiniz?'),
            actions: [
              // İptal butonu
              TextButton(
                onPressed: _isLoggingOut 
                  ? null 
                  : () {
                      print('CustomDrawer: Cikis dialog\'u iptal edildi');
                      Navigator.of(dialogContext).pop();
                    },
                child: const Text('Iptal'),
              ),
              // Onay butonu
              TextButton(
                onPressed: _isLoggingOut
                  ? null
                  : () async {
                      print('CustomDrawer: Cikis onayi verildi');
                      Navigator.of(dialogContext).pop();
                      await _handleLogout(context);
                    },
                child: _isLoggingOut
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      ),
                    )
                  : const Text('Evet'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı ve admin kontrolü
    final currentUser = _firebaseService.getCurrentUser();
    final String? userId = currentUser?.uid;
    final String? userEmail = currentUser?.email;
    String? tcKimlik;
    
    if (userEmail != null) {
      tcKimlik = userEmail.split('@')[0];
    }
    
    // Admin yetkisi kontrolü
    const String adminUserId = "RSoZIw4KBRRbVmcwMfYvzSzNtqA2";
    bool isAdmin = (userId == adminUserId);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Üst bölüm (Header)
          Container(
            color: Color(0xFF5181BE),
            child: Column(
              children: [
                SizedBox(height: 50),  // Status bar için boşluk
                
                // Logo alanı
                if (_logoUrl != null)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Image.network(
                      _logoUrl!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error_outline, size: 100, color: Colors.white);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 100,
                          width: 100,
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Icon(Icons.account_circle, size: 100, color: Colors.white),
                  ),
                
                // Kullanıcı e-posta bilgisi
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    userEmail ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Ana menü öğeleri
          ListTile(
            leading: Icon(Icons.home, color: Color(0xFF5181BE)),
            title: Text('Ana Sayfa'),
            onTap: () => _navigate(context, '/home'),
          ),
          
          ListTile(
            leading: Icon(Icons.poll, color: Color(0xFF5181BE)),
            title: Text('Anketler'),
            onTap: () => _navigate(context, '/survey'),
          ),
          
          ListTile(
            leading: Icon(Icons.bar_chart, color: Color(0xFF5181BE)),
            title: Text('Istatistikler'),
            onTap: () => _navigate(context, '/statistics'),
          ),
          
          // Admin menüsü (sadece admin kullanıcılar için)
          if (isAdmin)
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.purple),
              title: Text('Anket Yonetimi'),
              onTap: () => _navigate(context, '/admin/survey'),
            ),
          
          const Divider(),
          
          // Alt menü öğeleri
          ListTile(
            leading: Icon(Icons.person_outline, color: Color(0xFF5181BE)),
            title: Text('Profil Bilgilerim'),
            onTap: () => _navigate(context, '/profile_update'),
          ),
          
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Cikis'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
