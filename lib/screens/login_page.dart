import 'package:flutter/material.dart';
import 'survey_page.dart';
import '../services/firebase_service.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Firebase servisi
  final FirebaseService _firebaseService = FirebaseService();
  
  // Text controller'lar
  final tcController = TextEditingController();
  final sifreController = TextEditingController();
  
  // Loading durumu
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text("Giris Sayfasi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Uygulama logosu
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
                Text(
                  'VOXURE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                
                // TC Kimlik No giriş alanı
                TextField(
                  controller: tcController,
                  decoration: InputDecoration(
                      labelText: "TC Kimlik No",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Sadece rakam girişine izin verir
                  ],
                ),
                SizedBox(height: 12),
                
                // Şifre giriş alanı
                TextField(
                  controller: sifreController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Sifre",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 24),
                
                // Giriş butonu
                _isLoading
                    ? CircularProgressIndicator()
                    : Row(
                        children: [
                          // Giris Yap butonu
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF5181BE),
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                  minimumSize: Size(0, 50)),
                              child: Text('Giris Yap', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                          SizedBox(width: 10),
                          // Kayit Ol butonu
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 240, 76, 64),
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                  minimumSize: Size(0, 50)),
                              child: Text('Kayit Ol', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TC kimlik numarası geçerlilik kontrolü
  bool _isValidTc(String? tc) {
    if (tc == null || tc.isEmpty) return false;
    if (tc.length != 11) return false;
    if (tc[0] == '0') return false;
    // Sadece rakam içerip içermediğini kontrol et
    if (!RegExp(r'^[0-9]+$').hasMatch(tc)) return false;
    return true;
  }

  // Giriş işlemi
  void _login() async {
    // Input kontrolü
    if (!_isValidTc(tcController.text)) {
      _showMessage("Hata", "Gecerli bir TC kimlik numarasi giriniz.");
      return;
    }
    
    if (sifreController.text.isEmpty) {
      _showMessage("Hata", "Sifre alani bos birakilamaz.");
      return;
    }

    // Loading göstergesi
    setState(() {
      _isLoading = true;
    });
    
    try {
      developer.log("LOGIN_PAGE: Giris deneniyor. TC: ${tcController.text}", name: 'login_page');
      
      // Firebase ile giriş kontrolü
      Map<String, dynamic> result = await _firebaseService.loginUser(
        tcKimlik: tcController.text,
        sifre: sifreController.text,
      );
      
      developer.log("LOGIN_PAGE: Giris cevabi: $result", name: 'login_page');
      developer.log("LOGIN_RESULT_DETAILS: ${result.toString()}", name: 'login_page');
      
      setState(() {
        _isLoading = false;
      });
      
      // Kullanici zaten oturum acmissa dogrudan ana sayfaya yonlendir
      if (_firebaseService.isUserLoggedIn()) {
        developer.log("LOGIN_PAGE: Kullanici zaten giris yapmis, ana sayfaya yonlendiriliyor", name: 'login_page');
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      
      if (result['success'] == true) {
        // Ana sayfaya yönlendir - giriş başarılı
        developer.log("LOGIN_PAGE: Giris basarili, ana sayfaya yonlendiriliyor", name: 'login_page');
        
        try {
          await Future.delayed(Duration(milliseconds: 100));
          Navigator.pushReplacementNamed(context, '/home');
          developer.log("LOGIN_PAGE: Ana sayfaya yonlendirme tamamlandi", name: 'login_page');
        } catch (navError) {
          developer.log("LOGIN_PAGE: Yonlendirme hatasi: $navError", name: 'login_page');
          _showMessage("Hata", "Ana sayfaya yonlendirme sirasinda hata olustu: $navError");
        }
      } else {
        // Giriş başarısız
        _showMessage("Hata", result['message'] ?? "Giris yapilamadi");
      }
    } catch (e) {
      developer.log("LOGIN_PAGE: Beklenmeyen hata: $e", name: 'login_page');
      
      setState(() {
        _isLoading = false;
      });
      
      // Firebase Auth kullanicisi oturum acmissa, hata olsa bile basarili kabul et
      if (_firebaseService.isUserLoggedIn()) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage("Hata", "Giris sirasinda bir hata olustu. Lutfen tekrar deneyin.");
      }
    }
  }

  // Kayıt sayfasına yönlendirme
  void _register() {
    Navigator.pushReplacementNamed(context, '/register');
  }
  
  // Şifre sıfırlama işlemi
  void _resetPassword() async {
    // TC numarası doğrulaması
    if (!_isValidTc(tcController.text)) {
      _showMessage("Hata", "Sifre sifirlamak icin gecerli bir TC kimlik numarasi giriniz.");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      Map<String, dynamic> result = await _firebaseService.resetPassword(tcController.text);
      
      setState(() {
        _isLoading = false;
      });
      
      _showMessage(
        result['success'] ? "Basarili" : "Hata", 
        result['message']
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Hata", "Sifre sifirlama sirasinda bir hata olustu.");
    }
  }

  // Mesaj gösterimi
  void _showMessage(String title, String message) {
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
