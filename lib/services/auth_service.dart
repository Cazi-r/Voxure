import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mevcut kullanici durumunu izle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Cikis yap
  Future<void> signOut() async {
    try {
      print('AuthService: Cikis islemi baslatiliyor...');
      
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