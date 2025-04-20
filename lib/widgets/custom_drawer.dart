import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  // Uygulama logosu için URL tanımı
  // Drawer başlığında gösterilen logo
  final String logoUrl =
      'https://cdn-icons-png.flaticon.com/512/1902/1902201.png';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[100],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer başlık bölümü
          // Uygulama logosu ve adını içeren üst kısım
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF5181BE),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Uygulama logosu
                // Uygulama kimliğini güçlendiren görsel öğe
                Image.network(
                  logoUrl,
                  height: 70,
                  width: 70,
                ),
                SizedBox(height: 10),
                // Uygulama adı
                // Beyaz renkte ve vurgulu şekilde gösterilir
                Text(
                  'VOXURE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Ana Sayfa menü öğesi
          // Kullanıcıyı ana sayfaya yönlendirir
          ListTile(
            leading: Icon(Icons.home, color: Color(0xFF5181BE)),
            title: Text('Ana Sayfa'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          
          // Anketler menü öğesi
          // Kullanıcıyı anket sayfasına yönlendirir, oy kullanmayı sağlar
          ListTile(
            leading: Icon(Icons.poll, color: Color(0xFF5181BE)),
            title: Text('Anketler'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/survey');
            },
          ),
          
          // İstatistikler menü öğesi
          // Kullanıcıyı anket sonuçları ve istatistikleri sayfasına yönlendirir
          ListTile(
            leading: Icon(Icons.bar_chart, color: Color(0xFF5181BE)),
            title: Text('İstatistikler'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/statistics');
            },
          ),
          
          // Ayırıcı çizgi - alt menü öğelerini ayırır
          Divider(),
          
          // Çıkış menü öğesi
          // Kullanıcıyı oturumdan çıkarır ve giriş sayfasına yönlendirir
          // Diğer menü öğelerinden farklı olarak kırmızı renkli ikon kullanılır
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Çıkış'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
