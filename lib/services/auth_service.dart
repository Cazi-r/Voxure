import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert' show jsonDecode;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
    hostedDomain: '',  // tüm domainlere izin ver
    clientId: '',      // Android için gerekli değil
  );

  // Mevcut kullanici durumunu izle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google ile giris yap
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

  // GitHub ile giriş yap
  Future<UserCredential?> signInWithGithub() async {
    try {
      print('GitHub giris basladi');
      
      if (kIsWeb) {
        // Web platformu için
        final GithubAuthProvider githubProvider = GithubAuthProvider();
        await _auth.signInWithRedirect(githubProvider);
        return await _auth.getRedirectResult();
      } else {
        // Mobil platformlar için
        final GithubAuthProvider githubProvider = GithubAuthProvider();
        final result = await _auth.signInWithProvider(githubProvider);
        
        if (result.user != null) {
          print('GitHub giris basarili: ${result.user?.email}');
          return result;
        } else {
          print('GitHub giris basarisiz: Kullanici bilgisi alinamadi');
          return null;
        }
      }
    } on FirebaseAuthException catch (e) {
      print('GitHub giris hatasi (FirebaseAuthException): ${e.message}');
      return null;
    } catch (e) {
      print('GitHub giris hatasi: $e');
      return null;
    }
  }

  // Cikis yap
  Future<void> signOut() async {
    try {
      print('AuthService: Cikis islemi baslatiliyor...');
      
      print('AuthService: Google hesabindan cikis deneniyor...');
      try {
        await _googleSignIn.signOut();
        print('AuthService: Google hesabindan cikis basarili');
      } catch (e) {
        print('AuthService: Google cikis hatasi: $e');
        // Google cikis hatasi genel cikisi engellemeyecek
      }

      print('AuthService: Firebase cikisi deneniyor...');
      try {
        await _auth.signOut();
        print('AuthService: Firebase cikisi basarili');
      } catch (e) {
        print('AuthService: Firebase cikis hatasi: $e');
        throw Exception('Firebase cikis islemi basarisiz: $e');
      }

      print('AuthService: Tum cikis islemleri basariyla tamamlandi');
    } catch (e, stackTrace) {
      print('AuthService: Cikis sirasinda kritik hata:');
      print('Hata: $e');
      print('Stack Trace: $stackTrace');
      throw Exception('Cikis islemi tamamlanamadi: $e');
    }
  }
} 