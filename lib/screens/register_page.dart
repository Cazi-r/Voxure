import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_app_bar.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseService _firebaseService = FirebaseService();
  
  final tcController = TextEditingController();
  final sifreController = TextEditingController();
  final sifreTekrarController = TextEditingController();
  
  bool _isLoading = false;
  String _loadingMessage = "Kayıt olunuyor...";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Kayit Ol',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'images/icon.png',
                        height: 100,
                        width: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, size: 100, color: Color(0xFF5181BE));
                        },
                      ),
                      SizedBox(height: 12),
                      Text(
                        'VOXURE - Kayıt Formu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
                
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Basit Kayıt",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Hesap oluşturmak için sadece TC kimlik numarası ve şifre gerekiyor. Diğer bilgilerinizi (doğum tarihi, il ve okul) daha sonra girebilirsiniz.",
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                TextField(
                  controller: tcController,
                  decoration: InputDecoration(
                    labelText: "TC Kimlik No",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                SizedBox(height: 20),
                
                TextField(
                  controller: sifreController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 20),
                
                TextField(
                  controller: sifreTekrarController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Şifre Tekrar",
                    prefixIcon: Icon(Icons.lock_reset),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 240, 76, 64),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('KAYIT OL', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: const Color.fromARGB(255, 240, 76, 64),
                      ),
                      SizedBox(height: 24),
                      Text(
                        _loadingMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _registerUser() async {
    if (!_isValidTc(tcController.text)) {
      _showMessage("Hata", "Geçerli bir TC kimlik numarası giriniz.");
      return;
    }
    
    if (sifreController.text.isEmpty) {
      _showMessage("Hata", "Şifre boş bırakılamaz.");
      return;
    }
    
    if (sifreController.text.length < 6) {
      _showMessage("Hata", "Şifre en az 6 karakter olmalıdır.");
      return;
    }
    
    if (sifreController.text != sifreTekrarController.text) {
      _showMessage("Hata", "Şifreler eşleşmiyor.");
      return;
    }
    
    setState(() {
      _isLoading = true;
      _loadingMessage = "Kayıt olunuyor...";
    });
    
    try {
      Map<String, dynamic> result = await _firebaseService.registerUser(
        tcKimlik: tcController.text,
        sifre: sifreController.text,
      );
      
      setState(() {
        _loadingMessage = "Giriş yapılıyor...";
      });
      
      setState(() {
        _isLoading = false;
      });
      
      if (_firebaseService.isUserLoggedIn()) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      
      if (result['success']) {
        _showMessage(
          "Kayıt Başarılı", 
          "Hesabınız başarıyla oluşturuldu.",
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          }
        );
      } else {
        String errorMessage = result['message'] ?? "Bilinmeyen hata";
        
        if (errorMessage.contains('zaten kayıtlı, giriş yapıldı')) {
          _showMessage(
            "Dikkat", 
            errorMessage,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            }
          );
        } else {
          _showMessage("Kayıt Hatası", errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (_firebaseService.isUserLoggedIn()) {
        _showMessage(
          "Kayıt Başarılı", 
          "Hesabınız oluşturuldu.",
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          }
        );
      } else {
        _showMessage("Beklenmeyen Hata", "Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.");
      }
    }
  }
  
  void _showMessage(String title, String message, {Function()? onPressed}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: onPressed ?? () => Navigator.pop(context),
              child: Text("Tamam"),
            ),
          ],
        );
      },
    );
  }
  
  bool _isValidTc(String? tc) {
    if (tc == null || tc.isEmpty) return false;
    if (tc.length != 11) return false;
    if (tc[0] == '0') return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(tc)) return false;
    return true;
  }
} 