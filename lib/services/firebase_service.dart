import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

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

  // Oy verme islemi
  Future<bool> saveVote(Map<String, dynamic> voteData) async {
    try {
      final String surveyId = voteData['surveyId'];
      final String userId = voteData['userId'];
      final int optionIndex = voteData['optionIndex'];

      // Kullanicinin daha once oy verip vermedigini kontrol et
      final userVoteDoc = await _firestore
          .collection('votes')
          .where('surveyId', isEqualTo: surveyId)
          .where('userId', isEqualTo: userId)
          .get();

      if (userVoteDoc.docs.isNotEmpty) {
        print('Kullanici bu ankete zaten oy vermis: $userId, $surveyId');
        return false;
      }

      // Yeni oyu kaydet
      await _firestore.collection('votes').add({
        'surveyId': surveyId,
        'userId': userId,
        'optionIndex': optionIndex,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Anketin oy sayisini guncelle
      final surveyRef = _firestore.collection('surveys').doc(surveyId);
      await _firestore.runTransaction((transaction) async {
        final surveyDoc = await transaction.get(surveyRef);
        if (!surveyDoc.exists) {
          throw Exception('Anket bulunamadi');
        }

        List<int> votes = List<int>.from(surveyDoc.data()?['oylar'] ?? []);
        if (optionIndex >= 0 && optionIndex < votes.length) {
          votes[optionIndex]++;
          transaction.update(surveyRef, {'oylar': votes});
        }
      });

      return true;
    } catch (e) {
      print('Oy kaydedilirken hata: $e');
      return false;
    }
  }

  // Toplu oy kaydetme
  Future<bool> saveBulkVotes(List<Map<String, dynamic>> votesData) async {
    try {
      bool allSuccessful = true;
      for (var voteData in votesData) {
        final bool success = await saveVote(voteData);
        if (!success) {
          allSuccessful = false;
        }
      }
      return allSuccessful;
    } catch (e) {
      print('Toplu oy kaydedilirken hata: $e');
      return false;
    }
  }

  // Anket oylarini getir
  Future<Map<int, int>> getSurveyVotes(String surveyId) async {
    try {
      final surveyDoc = await _firestore.collection('surveys').doc(surveyId).get();
      
      if (!surveyDoc.exists) {
        return {};
      }

      final List<dynamic> votes = surveyDoc.data()?['oylar'] ?? [];
      Map<int, int> voteCount = {};
      
      for (int i = 0; i < votes.length; i++) {
        if (votes[i] > 0) {
          voteCount[i] = votes[i];
        }
      }
      
      return voteCount;
    } catch (e) {
      print('Anket oylari alinirken hata: $e');
      return {};
    }
  }

  // Kullanicinin oyunu getir
  Future<Map<String, dynamic>?> getUserVote(String userId, String surveyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('votes')
          .where('userId', isEqualTo: userId)
          .where('surveyId', isEqualTo: surveyId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final voteDoc = querySnapshot.docs.first;
      return {
        'userId': userId,
        'surveyId': surveyId,
        'optionIndex': voteDoc.data()['optionIndex'],
      };
    } catch (e) {
      print('Kullanici oyu alinirken hata: $e');
      return null;
    }
  }

  // Oy dogrulama
  Future<bool> verifyVote(Map<String, dynamic> voteData) async {
    final userId = voteData['userId'];
    final surveyId = voteData['surveyId'];
    final optionIndex = voteData['optionIndex'];

    final userVote = await getUserVote(userId, surveyId);
    return userVote != null && userVote['optionIndex'] == optionIndex;
  }
} 