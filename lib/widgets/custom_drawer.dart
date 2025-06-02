import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomDrawer extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  CustomDrawer({super.key});

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cikis'),
          content: const Text('Cikmak istediginize emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('Iptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Evet'),
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  
                  // Firebase'den cikis yap
                  await _firebaseService.signOut();
                  
                  // Supabase'den cikis yap
                  await Supabase.instance.client.auth.signOut();
                  
                  // Login sayfasina yonlendir
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cikis yapildi')),
                    );
                  }
                } catch (e) {
                  print('Cikis yaparken hata: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cikis yaparken bir hata olustu')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Admin kontrolu icin kullanici bilgilerini al
    final currentUser = _firebaseService.getCurrentUser();
    final String? userId = currentUser?.uid;
    final String? userEmail = currentUser?.email;
    String? tcKimlik;
    
    if (userEmail != null) {
      tcKimlik = userEmail.split('@')[0];
    }
    
    // Admin UID kontrolu
    const String adminUserId = "yWt0hnQif1ONGEpcAo8yPCitLQm1";
    bool isAdmin = (userId == adminUserId);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF5181BE),
            ),
            accountName: Text(''),
            accountEmail: Text(userEmail ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF5181BE), size: 50),
            ),
          ),
          
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
          
          if (isAdmin)
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.purple),
              title: Text('Anket Yonetimi'),
              onTap: () => _navigate(context, '/admin/survey'),
            ),
          
          const Divider(),
          
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
