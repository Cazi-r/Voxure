import 'package:flutter/material.dart';
import 'survey_page.dart';
import '../services/firebase_service.dart';
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
        title: Text("Giriş Sayfası"),
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
                  textInputAction: TextInputAction.next,
                  enableSuggestions: true,
                  autocorrect: true,
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
                    labelText: "Şifre",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  textInputAction: TextInputAction.done,
                  enableSuggestions: true,
                  autocorrect: true,
                  keyboardType: TextInputType.visiblePassword,
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
                              child: Text('Giriş Yap', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                              child: Text('Kayıt Ol', style: TextStyle(fontSize: 16, color: Colors.white)),
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
      _showMessage("Hata", "Geçerli bir TC kimlik numarası giriniz.");
      return;
    }
    
    if (sifreController.text.isEmpty) {
      _showMessage("Hata", "Şifre alanı boş bırakılamaz.");
      return;
    }

    // Loading göstergesi
    setState(() {
      _isLoading = true;
    });
    
    try {      
      // Firebase ile giriş kontrolü
      Map<String, dynamic> result = await _firebaseService.loginUser(
        tcKimlik: tcController.text,
        sifre: sifreController.text,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      // Kullanıcı zaten oturum açmışsa doğrudan ana sayfaya yönlendir
      if (_firebaseService.isUserLoggedIn()) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      
      if (result['success'] == true) {
        // Ana sayfaya yönlendir - giriş başarılı
        try {
          await Future.delayed(Duration(milliseconds: 100));
          Navigator.pushReplacementNamed(context, '/home');
        } catch (navError) {
          _showMessage("Hata", "Ana sayfaya yönlendirme sırasında hata oluştu: $navError");
        }
      } else {
        // Giriş başarısız
        _showMessage("Hata", result['message'] ?? "Giriş yapılamadı");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Firebase Auth kullanıcısı oturum açmışsa, hata olsa bile başarılı kabul et
      if (_firebaseService.isUserLoggedIn()) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage("Hata", "Giriş sırasında bir hata oluştu. Lütfen tekrar deneyin.");
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
      _showMessage("Hata", "Şifre sıfırlamak için geçerli bir TC kimlik numarası giriniz.");
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
        result['success'] ? "Başarılı" : "Hata", 
        result['message']
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Hata", "Şifre sıfırlama sırasında bir hata oluştu.");
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
