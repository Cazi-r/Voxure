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
              Image.asset(
                'images/icon.png',
                height: 140,
                width: 140,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, size: 140, color: Color(0xFF5181BE));
                },
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
              Row(
                children: [
                  // Giris Yap butonu
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5181BE),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          minimumSize: Size(0, 50)),
                      child: Text('Giriş Yap', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 10), // Butonlar arasi bosluk
                  // Kayit Ol butonu
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 240, 76, 64),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          minimumSize: Size(0, 50)),
                      child: Text('Kayıt Ol', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
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

  // Kayit olmak icin yonlendirme yapan metot
  void register() {
    // Kayit sayfasina yonlendir
    Navigator.pushReplacementNamed(context, '/register');
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
