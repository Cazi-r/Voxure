// Bu servis, GitHub OAuth kimlik doğrulama işlemlerini yönetir.
// Web ve mobil platformlar için GitHub ile giriş yapma sürecini ve Firebase entegrasyonunu sağlar.

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class GitHubOAuthService {
  // GitHub OAuth yapılandırma bilgileri
  static const String clientId = 'Ov23lighZHKYkgHC2j3U';
  static const String clientSecret = 'b9a4b385bf061acede7c8f73c6926bbbc66e32c2';
  static const String redirectUri = kIsWeb 
      ? 'https://voxure-app.firebaseapp.com/__/auth/handler'
      : 'voxure://oauth/callback';
  static const String scope = 'read:user user:email';

  // Servis örnekleri
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _appLinks = AppLinks();
  String? _currentState;
  StreamSubscription<Uri?>? _subscription;
  bool _isDisposed = false;

  // Servis kaynaklarını temizleme
  Future<void> dispose() async {
    _isDisposed = true;
    await _subscription?.cancel();
    _subscription = null;
    _currentState = null;
  }

  // GitHub ile giriş işlemini başlatma
  Future<UserCredential?> signIn() async {
    if (_isDisposed) {
      print('GitHubOAuthService is disposed');
      return null;
    }

    try {
      // Platform türüne göre uygun giriş yöntemini seç
      if (kIsWeb) {
        return await _handleWebSignIn();
      } else {
        return await _handleMobileSignIn();
      }
    } catch (e) {
      print('GitHub OAuth Error: $e');
      return null;
    } finally {
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  // Web platformu için GitHub giriş işlemi
  Future<UserCredential?> _handleWebSignIn() async {
    final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
      'state': _generateState(),
    });

    // Web'de popup veya yönlendirme ile giriş yap
    final provider = GithubAuthProvider();
    provider.addScope('read:user');
    provider.addScope('user:email');
    
    try {
      return await _auth.signInWithPopup(provider);
    } catch (e) {
      print('Web OAuth Error: $e');
      // Popup başarısız olursa yönlendirme ile dene
      await _auth.signInWithRedirect(provider);
      return await _auth.getRedirectResult();
    }
  }

  // Mobil platform için GitHub giriş işlemi
  Future<UserCredential?> _handleMobileSignIn() async {
    // Cancel any existing subscription
    await _subscription?.cancel();
    _subscription = null;

    _currentState = _generateState();
    print('Generated state: $_currentState');
    
    final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
      'state': _currentState,
    });

    print('Launching URL: ${authUrl.toString()}');

    try {
      final canLaunch = await canLaunchUrl(authUrl);
      if (!canLaunch) {
        print('Cannot launch URL: $authUrl');
        return null;
      }

      // Start listening for the callback before launching the URL
      final completer = Completer<String?>();
      
      _subscription = _appLinks.uriLinkStream.listen((Uri? uri) async {
        if (!completer.isCompleted && uri != null) {
          print('Received URI in stream: $uri');
          try {
            final result = await _handleOAuthResponse(uri, _currentState!);
            if (result != null) {
              completer.complete(result);
            }
          } catch (e) {
            print('Error handling OAuth response: $e');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        }
      }, onError: (error) {
        print('Stream error: $error');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      // Launch the URL after setting up the listener
      await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );
      
      // Wait for the OAuth response
      final accessToken = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print('OAuth timeout');
          return null;
        },
      );

      if (accessToken != null) {
        print('Received access token, getting Firebase credential...');
        final credential = await _getFirebaseCredential(accessToken);
        print('Got Firebase credential, signing in...');
        final userCredential = await _auth.signInWithCredential(credential);
        print('Successfully signed in with Firebase: ${userCredential.user?.email}');
        return userCredential;
      } else {
        print('No OAuth response received');
      }
    } catch (e) {
      print('Error during OAuth flow: $e');
    } finally {
      await _subscription?.cancel();
      _subscription = null;
    }
    return null;
  }

  // GitHub'dan gelen OAuth yanıtını işleme
  Future<String?> _handleOAuthResponse(Uri uri, String expectedState) async {
    print('Handling OAuth response...');
    print('URI: $uri');
    print('Expected state: $expectedState');
    print('Received state: ${uri.queryParameters['state']}');
    
    final receivedState = uri.queryParameters['state'];
    if (receivedState != expectedState) {
      print('State mismatch! Expected: $expectedState, Received: $receivedState');
      return null;
    }

    final code = uri.queryParameters['code'];
    if (code != null) {
      print('Exchanging code for access token...');
      // GitHub'dan access token al
      final tokenResponse = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
        }),
      );

      print('Token response status: ${tokenResponse.statusCode}');
      print('Token response body: ${tokenResponse.body}');

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'];
      
      if (accessToken != null) {
        print('Successfully got access token');
        return accessToken;
      } else {
        print('No access token in response: $tokenData');
        return null;
      }
    }
    print('No code in callback URI');
    return null;
  }

  // GitHub access token'ı ile Firebase kimlik bilgisi oluşturma
  Future<OAuthCredential> _getFirebaseCredential(String accessToken) async {
    print('Getting Firebase credential for access token...');
    // GitHub API'den kullanıcı bilgilerini al
    final userResponse = await http.get(
      Uri.parse('https://api.github.com/user'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (userResponse.statusCode != 200) {
      print('Failed to get GitHub user data: ${userResponse.statusCode}');
      print('Response body: ${userResponse.body}');
      throw Exception('Failed to get GitHub user data');
    }

    print('Successfully got GitHub user data');
    return GithubAuthProvider.credential(accessToken);
  }

  // Güvenlik için benzersiz durum değeri oluşturma
  String _generateState() {
    final random = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Url.encode(random).replaceAll('=', '');
  }
} 