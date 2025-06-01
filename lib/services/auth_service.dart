import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:convert' show jsonDecode;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // TODO: Bunlari Firebase Remote Config veya guvenli bir yerden alin
  final String githubClientId = 'Ov23liJTc47yorORCyTL';
  final String githubClientSecret = 'edaac4c438730123cb5bb70a706653bb270f338d';
  
  // Bu, Firebase Console'da GitHub saglayicisi icin yapilandirilan URL'dir.
  // flutter_web_auth_2 tarafindan dogrudan kullanilmaz.
  final String firebaseGithubAuthHandlerUrl = 'https://voxure-app.firebaseapp.com/__/auth/handler';

  // Uygulamanizin GitHub'dan gelen callback'i yakalamak icin kullanacagi ozel sema.
  static const String appSpecificCallbackScheme = 'voxureauth';
  // GitHub OAuth App ayarlarinda "Authorization callback URL" olarak bunu girmelisiniz.
  static const String githubRedirectUriForApp = '$appSpecificCallbackScheme://github-auth-callback';

  // Mevcut kullanici durumunu izle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google ile giris yap
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-In akisini baslat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // Google Sign-In kimlik bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase kimlik bilgilerini olustur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase ile giris yap
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google giris hatasi: $e');
      return null;
    }
  }

  // GitHub ile giris yap
  Future<UserCredential?> signInWithGitHub() async {
    print('GitHub ile giris baslatiliyor...');
    try {
      final String authorizationUrl =
          'https://github.com/login/oauth/authorize?client_id=$githubClientId&scope=read:user%20user:email&redirect_uri=$githubRedirectUriForApp';
      print('Yetkilendirme URL: $authorizationUrl');
      print('Callback scheme: $appSpecificCallbackScheme');

      String? result; // Nullable yapalim
      try {
        result = await FlutterWebAuth2.authenticate(
          url: authorizationUrl,
          callbackUrlScheme: appSpecificCallbackScheme,
        );
        print('FlutterWebAuth2.authenticate BASARILI sonucu: $result');
      } catch (authError) {
        print('FlutterWebAuth2.authenticate ICINDE HATA: $authError'); // authenticate icindeki hatayi yakala
        rethrow; // Hatayi dis try-catch'e ilet
      }

      if (result == null) { // Islem iptal edilmis veya null donmus olabilir
          print('GitHub OAuth: FlutterWebAuth2.authenticate null sonuc dondu veya islem iptal edildi.');
          return null;
      }
      
      print('Alinan tam geri arama URL: $result');

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      
      if (code == null) {
        print('GitHub OAuth: Kod alinamadi. Gelen URI\'da \'code\' parametresi yok. URI: $result');
        if (uri.queryParameters.containsKey('error')) {
          print('GitHub OAuth Hata Detaylari: error=${uri.queryParameters['error']}, error_description=${uri.queryParameters['error_description']}, error_uri=${uri.queryParameters['error_uri']}');
        }
        return null;
      }
      print('GitHub OAuth: Kod basariyla alindi: $code');

      final tokenResponse = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': githubClientId,
          'client_secret': githubClientSecret,
          'code': code,
          'redirect_uri': githubRedirectUriForApp, // GitHub'a bu da gonderilebilir, bazi akislarda gerekir
        },
      );

      if (tokenResponse.statusCode != 200) {
        print('GitHub OAuth: Erisim anahtari alinamadi. Hata: ${tokenResponse.body}');
        return null;
      }

      final accessToken = jsonDecode(tokenResponse.body)['access_token'];
      if (accessToken == null) {
        print('GitHub OAuth: Erisim anahtari bulunamadi.');
        return null;
      }

      final credential = GithubAuthProvider.credential(accessToken);
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Bu dis catch blogu, authenticate icindeki rethrow edilen veya diger hatalari yakalar
      if (e is PlatformException && e.code == 'CANCELED') {
          print('GitHub giris hatasi: Kullanici islemi iptal etti (PlatformException CANCELED).');
      } else {
          print('GitHub giris genel hatasi: $e');
      }
      return null;
    }
  }

  // Cikis yap
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
} 