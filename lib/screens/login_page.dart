import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'survey_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // TC kimlik numarası ve şifre bilgilerini saklar ve değişikliklerini takip eder
  final tcController = TextEditingController();
  final sifreController = TextEditingController();
  
  // Uygulama logosu için API'den alınan URL
  final logoUrl = 'https://cdn-icons-png.flaticon.com/512/1902/1902201.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text("Giriş Sayfası"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Login ekranında görünen uygulama logosu
              Image.network(
                logoUrl,
                height: 140,
                width: 140,
              ),
              SizedBox(height: 16),
              
              // Uygulama başlığı
              // Ana uygulama ismini gösterir
              Text(
                'VOXURE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              
              // TC Kimlik No giriş alanı
              // Kullanıcı tanımlaması için TC kimlik numarası istenir
              // 11 karakter sınırlaması ve sadece sayı girişi sağlanır
              TextField(
                controller: tcController,
                decoration: InputDecoration(
                    labelText: "TC Kimlik No",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
                keyboardType: TextInputType.number,
                maxLength: 11,
              ),
              SizedBox(height: 12),
              
              // Şifre giriş alanı
              // Kullanıcının şifresini gizli şekilde girmesini sağlar
              // Güvenlik için metin gizlenir (obscureText: true)
              TextField(
                controller: sifreController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 24),
              
              // Giriş butonu
              // Kullanıcı bilgilerini kontrol eder ve giriş işlemini başlatır
              ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5181BE),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    minimumSize: Size(double.infinity, 50)),
                child: Text('Giriş Yap', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TC kimlik numarası geçerlilik kontrolü
  // TC numarası 11 haneli olmalı ve ilk rakamı 0 olmamalıdır
  bool isIdValid(String? tc) {
    if (tc == null || tc.isEmpty) return false;  // Boş değer kontrolü
    if (tc.length != 11) return false;           // 11 hane kontrolü
    if (tc[0] == '0') return false;              // İlk rakam 0 olmamalı
    return true;
  }

  // Kullanıcı giriş işlemini gerçekleştiren metot
  // TC kimlik ve şifre kontrolü yaparak giriş işlemini yönetir
  void login() async {
    // TC kimlik numarası geçerlilik kontrolü
    // Geçersiz ise hata mesajı gösterilir
    if (!isIdValid(tcController.text)) {
      showMessage("Hata", "Geçerli bir TC kimlik numarası giriniz.");
      return;
    }
    
    // Şifre boş olmamalı kontrolü
    // Boş ise hata mesajı gösterilir
    if (sifreController.text.isEmpty) {
      showMessage("Hata", "Şifre alanı boş bırakılamaz.");
      return;
    }

    try {
      // Kullanıcı TC'sini cihaz hafızasına kaydet
      // SharedPreferences kullanarak oturum bilgisini saklar
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('user_id', tcController.text);

      // Ana sayfaya yönlendir - giriş başarılı
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      showMessage("Hata", "Giriş sırasında bir hata oluştu: $e");
    }
  }

  // Hata ve bilgi mesajlarını gösteren yardımcı metot
  // AlertDialog kullanarak kullanıcıya bildirim gösterir
  void showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tamam"),
            ),
          ],
        );
      },
    );
  }
}
