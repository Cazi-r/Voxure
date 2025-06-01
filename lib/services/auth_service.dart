import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Cikis yap
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
} 