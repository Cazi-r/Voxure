import 'package:flutter/material.dart';
import 'survey_page.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/base_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Firebase servisi
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  
  // Text controller'lar
  final emailController = TextEditingController();
  final sifreController = TextEditingController();
  
  // Loading durumu
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Giris Yap',
      showDrawer: false,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        Padding(
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
                  
                  // E-posta giriş alanı
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                        labelText: "E-posta",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enableSuggestions: true,
                    autocorrect: false,
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
                  SizedBox(height: 20),
                  
                  // Google ile giris butonu
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 50),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    icon: Image.network(
                      'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                      height: 24,
                    ),
                    label: const Text('Google ile Giris Yap'),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        final user = await _authService.signInWithGoogle();
                        if (user != null && mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  // GitHub ile giris butonu
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      backgroundColor: Colors.grey[800], // GitHub rengine yakin
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    icon: Image.network(
                      'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png', // GitHub logosu
                      height: 24,
                    ),
                    label: const Text('GitHub ile Giris Yap'),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        final user = await _authService.signInWithGitHub();
                        if (user != null && mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // E-posta geçerlilik kontrolü
  bool _isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    // Basit e-posta doğrulama
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Giriş işlemi
  void _login() async {
    // Input kontrolü
    if (!_isValidEmail(emailController.text)) {
      _showMessage("Hata", "Gecerli bir e-posta adresi giriniz.");
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
      // Firebase ile giriş kontrolü
      Map<String, dynamic> result = await _firebaseService.loginUser(
        email: emailController.text,
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
    // E-posta doğrulaması
    if (!_isValidEmail(emailController.text)) {
      _showMessage("Hata", "Sifre sifirlamak icin gecerli bir e-posta adresi giriniz.");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      Map<String, dynamic> result = await _firebaseService.resetPassword(emailController.text);
      
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
