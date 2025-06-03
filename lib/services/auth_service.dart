// Bu servis, kullanıcı kimlik doğrulama işlemlerini yönetir.
// Google ve GitHub ile giriş yapma, çıkış yapma ve kullanıcı durumu takibi gibi işlemleri gerçekleştirir.

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth show User;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert' show jsonDecode;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'github_oauth_service.dart';
import '../main.dart';

class AuthService {
  // Firebase kimlik doğrulama örneği
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Google giriş servisi yapılandırması
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
    hostedDomain: '',  // tüm domainlere izin ver
    clientId: '',      // Android için gerekli değil
  );
  
  // GitHub OAuth servisi örneği
  final GitHubOAuthService _githubOAuthService = GitHubOAuthService();

  // Kullanıcının oturum durumundaki değişiklikleri dinle
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Google ile giriş yapma işlemi
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Önce mevcut hesaptan çıkış yap
      await _googleSignIn.signOut();
      
      print('Google giris basladi');
      // Google Sign-In akisini baslat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google giris iptal edildi');
        return null;
      }

      print('Google hesabi secildi: ${googleUser.email}');

      // Google Sign-In kimlik bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase kimlik bilgilerini olustur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase ile giris yapiliyor...');
      // Firebase ile giris yap
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('Firebase giris basarili: ${userCredential.user?.email}');
      
      return userCredential;
    } catch (e) {
      print('Google giris hatasi: $e');
      return null;
    }
  }

  // GitHub ile giriş yapma işlemi
  Future<UserCredential?> signInWithGithub() async {
    try {
      print('GitHub giris basladi');
      return await _githubOAuthService.signIn();
    } catch (e) {
      print('GitHub giris hatasi: $e');
      return null;
    }
  }

  // Tüm servislerden çıkış yapma işlemi
  Future<void> signOut() async {
    try {
      print('AuthService: Cikis islemi baslatiliyor...');

      // Önce Firebase oturumunu kontrol et
      final user = _auth.currentUser;
      if (user == null) {
        print('AuthService: Zaten çıkış yapılmış');
        return;
      }

      // GitHub servisini temizle
      print('AuthService: GitHub servisini temizleme deneniyor...');
      try {
        await _githubOAuthService.dispose();
        print('AuthService: GitHub servisi temizlendi');
      } catch (e) {
        print('AuthService: GitHub servisi temizleme hatasi: $e');
      }

      // Google hesabından çıkış yap
      print('AuthService: Google hesabindan cikis deneniyor...');
      try {
        final isSignedIn = await _googleSignIn.isSignedIn();
        if (isSignedIn) {
          await _googleSignIn.signOut();
          print('AuthService: Google hesabindan cikis basarili');
        } else {
          print('AuthService: Google hesabında oturum açılmamış');
        }
      } catch (e) {
        print('AuthService: Google cikis hatasi: $e');
      }

      // Firebase'den çıkış yap
      print('AuthService: Firebase cikisi deneniyor...');
      await _auth.signOut();
      print('AuthService: Firebase cikisi basarili');

      // Tüm çıkış işlemleri tamamlandı
      print('AuthService: Tum cikis islemleri basariyla tamamlandi');

      // Uygulamayı yeniden başlat
      Future.delayed(const Duration(milliseconds: 100), () {
        print('AuthService: Uygulama yeniden başlatılıyor...');
        restartApp();
      });
    } catch (e) {
      print('AuthService: Cikis sirasinda hata: $e');
      // Hata durumunda Firebase oturumunu zorla kapatmayı dene
      try {
        await _auth.signOut();
        // Hata durumunda da uygulamayı yeniden başlat
        Future.delayed(const Duration(milliseconds: 100), () {
          print('AuthService: Uygulama yeniden başlatılıyor (hata sonrası)...');
          restartApp();
        });
      } catch (e2) {
        print('AuthService: Zorla cikis yaparken hata: $e2');
      }
    }
  }
} 