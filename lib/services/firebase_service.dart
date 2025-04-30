import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class FirebaseService {
  // Firebase kimlik dogrulama servisi
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // TC numarasini email formatina cevirir
  String _convertTcToEmail(String tcKimlik) {
    return "$tcKimlik@example.com";
  }
  
  // Kullanici kayit islemi - sadece TC ve sifre
  Future<Map<String, dynamic>> registerUser({
    required String tcKimlik,
    required String sifre,
  }) async {
    try {
      developer.log("KAYIT BASLIYOR... TC: $tcKimlik", name: 'firebase_service');
      
      // TC kimlik kontrolu
      if (tcKimlik.length != 11 || !RegExp(r'^\d+$').hasMatch(tcKimlik)) {
        developer.log("GECERSIZ TC: $tcKimlik", name: 'firebase_service');
        return {
          'success': false, 
          'message': 'Gecersiz TC kimlik numarasi.'
        };
      }
      
      // Sifre kontrolu
      if (sifre.length < 6) {
        developer.log("SIFRE COK KISA: ${sifre.length}", name: 'firebase_service');
        return {
          'success': false, 
          'message': 'Sifre en az 6 karakter olmalidir.'
        };
      }
      
      // Email formatı
      String email = _convertTcToEmail(tcKimlik);
      developer.log("EMAIL FORMAT: $email", name: 'firebase_service');
      
      // Kullanici olustur
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: sifre,
        );
        
        developer.log("KAYIT BASARILI. UID: ${userCredential.user?.uid}", name: 'firebase_service');
        
        return {
          'success': true,
          'message': 'Kullanici basariyla kaydedildi.',
          'userId': userCredential.user!.uid
        };
      } on FirebaseAuthException catch (e) {
        developer.log("FIREBASE AUTH HATASI: ${e.code} - ${e.message}", name: 'firebase_service');
        
        // Bu kullanıcı zaten kayıtlı mı kontrol et
        if (e.code == 'email-already-in-use') {
          // Bu durumda kullanıcı zaten kayıtlı, direkt giriş yapmayı deneyelim
          try {
            developer.log("KULLANICI ZATEN KAYITLI, GIRIS DENENIYOR", name: 'firebase_service');
            
            UserCredential userCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: sifre,
            );
            
            developer.log("MEVCUT KULLANICI ILE GIRIS BASARILI", name: 'firebase_service');
            
            return {
              'success': true,
              'message': 'TC kimlik zaten kayitli, giris yapildi.',
              'userId': userCredential.user!.uid
            };
          } catch (loginError) {
            developer.log("MEVCUT KULLANICI ILE GIRIS HATASI: $loginError", name: 'firebase_service');
            return {
              'success': false,
              'message': 'Bu TC kimlik numarasi zaten kayitli ama giris yapilamadi. Dogru sifreyi girin.',
              'error': loginError.toString()
            };
          }
        }
        
        String message = 'Kayit sirasinda bir hata olustu.';
        
        if (e.code == 'weak-password') {
          message = 'Daha guclu bir sifre secin.';
        } else if (e.code == 'invalid-email') {
          message = 'Gecersiz bir TC kimlik formati.';
        }
        
        return {
          'success': false,
          'message': message,
          'error': e.toString()
        };
      }
    } catch (e) {
      developer.log("GENEL HATA: $e", name: 'firebase_service');
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata olustu.',
        'error': e.toString()
      };
    }
  }
  
  // Kullanici giris islemi
  Future<Map<String, dynamic>> loginUser({
    required String tcKimlik,
    required String sifre,
  }) async {
    try {
      developer.log("GIRIS DENENIYOR... TC: $tcKimlik", name: 'firebase_service');
      
      // TC kimlik kontrolu
      if (tcKimlik.length != 11 || !RegExp(r'^\d+$').hasMatch(tcKimlik)) {
        developer.log("GECERSIZ TC: $tcKimlik", name: 'firebase_service');
        return {
          'success': false, 
          'message': 'Gecersiz TC kimlik numarasi.'
        };
      }
      
      // Email formatı
      String email = _convertTcToEmail(tcKimlik);
      developer.log("EMAIL FORMAT: $email", name: 'firebase_service');
      
      // Giris yap
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: sifre,
        );
        
        developer.log("GIRIS BASARILI. UID: ${userCredential.user?.uid}", name: 'firebase_service');
        
        return {
          'success': true,
          'message': 'Giris basarili.',
          'userId': userCredential.user!.uid
        };
      } on FirebaseAuthException catch (e) {
        developer.log("FIREBASE AUTH HATASI: ${e.code} - ${e.message}", name: 'firebase_service');
        
        String message = 'Giris sirasinda bir hata olustu.';
        
        if (e.code == 'user-not-found') {
          message = 'Bu TC kimlik numarasina sahip kullanici bulunamadi.';
        } else if (e.code == 'wrong-password') {
          message = 'Hatali sifre.';
        } else if (e.code == 'invalid-email') {
          message = 'Gecersiz bir TC kimlik formati.';
        } else if (e.code == 'user-disabled') {
          message = 'Bu kullanici hesabi devre disi birakilmis.';
        }
        
        return {
          'success': false,
          'message': message,
          'error': e.toString()
        };
      }
    } catch (e) {
      developer.log("GENEL HATA: $e", name: 'firebase_service');
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata olustu.',
        'error': e.toString()
      };
    }
  }
  
  // Kullanici cikis islemi
  Future<Map<String, dynamic>> signOut() async {
    try {
      await _auth.signOut();
      developer.log("CIKIS BASARILI", name: 'firebase_service');
      return {
        'success': true,
        'message': 'Cikis basarili.'
      };
    } catch (e) {
      developer.log("CIKIS HATASI: $e", name: 'firebase_service');
      return {
        'success': false,
        'message': 'Cikis sirasinda bir hata olustu.',
        'error': e.toString()
      };
    }
  }
  
  // Kullanici kontrolu
  bool isUserLoggedIn() {
    final bool loggedIn = _auth.currentUser != null;
    developer.log("OTURUM KONTROLU: $loggedIn", name: 'firebase_service');
    return loggedIn;
  }
  
  // Mevcut kullaniciyi getir
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Sifre sifirlama
  Future<Map<String, dynamic>> resetPassword(String tcKimlik) async {
    try {
      developer.log("SIFRE SIFIRLAMA DENENIYOR... TC: $tcKimlik", name: 'firebase_service');
      await _auth.sendPasswordResetEmail(
        email: _convertTcToEmail(tcKimlik),
      );
      
      developer.log("SIFRE SIFIRLAMA MAILI GONDERILDI", name: 'firebase_service');
      return {
        'success': true,
        'message': 'Sifre sifirlama baglantisi gonderildi.'
      };
    } catch (e) {
      developer.log("SIFRE SIFIRLAMA HATASI: $e", name: 'firebase_service');
      return {
        'success': false,
        'message': 'Sifre sifirlama islemi basarisiz.',
        'error': e.toString()
      };
    }
  }
} 