import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  // Firebase kimlik doğrulama servisi
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // TC numarasını email formatına çevirir
  String _convertTcToEmail(String tcKimlik) {
    return "$tcKimlik@example.com";
  }
  
  // Kullanıcı kayıt işlemi - sadece TC ve şifre
  Future<Map<String, dynamic>> registerUser({
    required String tcKimlik,
    required String sifre,
  }) async {
    try {
      // TC kimlik kontrolü
      if (tcKimlik.length != 11 || !RegExp(r'^\d+$').hasMatch(tcKimlik)) {
        return {
          'success': false, 
          'message': 'Geçersiz TC kimlik numarası.'
        };
      }
      
      // Şifre kontrolü
      if (sifre.length < 6) {
        return {
          'success': false, 
          'message': 'Şifre en az 6 karakter olmalıdır.'
        };
      }
      
      // Email formatı
      String email = _convertTcToEmail(tcKimlik);
      
      // Kullanıcı oluştur
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: sifre,
        );
        
        return {
          'success': true,
          'message': 'Kullanıcı başarıyla kaydedildi.',
          'userId': userCredential.user!.uid
        };
      } on FirebaseAuthException catch (e) {
        // Bu kullanıcı zaten kayıtlı mı kontrol et
        if (e.code == 'email-already-in-use') {
          // Bu durumda kullanıcı zaten kayıtlı, direkt giriş yapmayı deneyelim
          try {
            UserCredential userCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: sifre,
            );
            
            return {
              'success': true,
              'message': 'TC kimlik zaten kayıtlı, giriş yapıldı.',
              'userId': userCredential.user!.uid
            };
          } catch (loginError) {
            return {
              'success': false,
              'message': 'Bu TC kimlik numarası zaten kayıtlı ama giriş yapılamadı. Doğru şifreyi girin.',
              'error': loginError.toString()
            };
          }
        }
        
        String message = 'Kayıt sırasında bir hata oluştu.';
        
        if (e.code == 'weak-password') {
          message = 'Daha güçlü bir şifre seçin.';
        } else if (e.code == 'invalid-email') {
          message = 'Geçersiz bir TC kimlik formatı.';
        }
        
        return {
          'success': false,
          'message': message,
          'error': e.toString()
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata oluştu.',
        'error': e.toString()
      };
    }
  }
  
  // Kullanıcı giriş işlemi
  Future<Map<String, dynamic>> loginUser({
    required String tcKimlik,
    required String sifre,
  }) async {
    try {
      // TC kimlik kontrolü
      if (tcKimlik.length != 11 || !RegExp(r'^\d+$').hasMatch(tcKimlik)) {
        return {
          'success': false, 
          'message': 'Geçersiz TC kimlik numarası.'
        };
      }
      
      // Email formatı
      String email = _convertTcToEmail(tcKimlik);
      
      // Giriş yap
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: sifre,
        );
        
        return {
          'success': true,
          'message': 'Giriş başarılı.',
          'userId': userCredential.user!.uid
        };
      } on FirebaseAuthException catch (e) {
        String message = 'Giriş sırasında bir hata oluştu.';
        
        if (e.code == 'user-not-found') {
          message = 'Bu TC kimlik numarasına sahip kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password') {
          message = 'Hatalı şifre.';
        } else if (e.code == 'invalid-email') {
          message = 'Geçersiz bir TC kimlik formatı.';
        } else if (e.code == 'user-disabled') {
          message = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
        }
        
        return {
          'success': false,
          'message': message,
          'error': e.toString()
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata oluştu.',
        'error': e.toString()
      };
    }
  }
  
  // Kullanıcı çıkış işlemi
  Future<Map<String, dynamic>> signOut() async {
    try {
      await _auth.signOut();
      return {
        'success': true,
        'message': 'Çıkış başarılı.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Çıkış sırasında bir hata oluştu.',
        'error': e.toString()
      };
    }
  }
  
  // Kullanıcı kontrolü
  bool isUserLoggedIn() {
    final bool loggedIn = _auth.currentUser != null;
    return loggedIn;
  }
  
  // Mevcut kullanıcıyı getir
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Şifre sıfırlama
  Future<Map<String, dynamic>> resetPassword(String tcKimlik) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: _convertTcToEmail(tcKimlik),
      );
      
      return {
        'success': true,
        'message': 'Şifre sıfırlama bağlantısı gönderildi.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Şifre sıfırlama işlemi başarısız.',
        'error': e.toString()
      };
    }
  }
} 