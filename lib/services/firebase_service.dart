import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Kullanıcı kayıt işlemi
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String sifre,
  }) async {
    try {
      // Email kontrolü
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {
          'success': false, 
          'message': 'Gecersiz e-posta adresi.'
        };
      }
      
      // Şifre kontrolü
      if (sifre.length < 6) {
        return {
          'success': false, 
          'message': 'Sifre en az 6 karakter olmalidir.'
        };
      }
      
      try {
        // Kullanıcı oluştur
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: sifre,
        );

        // Kullanıcı başarıyla oluşturuldu mu kontrol et
        final User? user = userCredential.user;
        if (user == null) {
          return {
            'success': false,
            'message': 'Kullanici olusturulamadi.',
          };
        }

        // Kullanıcı oturum açmış durumda, başarılı dön
        return {
          'success': true,
          'message': 'Kullanici basariyla kaydedildi.',
          'userId': user.uid,
        };

      } on FirebaseAuthException catch (e) {
        // Firebase Auth hataları
        if (e.code == 'email-already-in-use') {
          // Kullanıcı zaten varsa, giriş yapmayı dene
          try {
            final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: sifre,
            );

            final User? user = userCredential.user;
            if (user == null) {
              return {
                'success': false,
                'message': 'Giris yapilamadi.',
              };
            }
            
            return {
              'success': true,
              'message': 'Bu e-posta zaten kayıtlı, giriş yapıldı.',
              'userId': user.uid,
            };
          } catch (loginError) {
            print('Giris sirasinda hata: $loginError');
            return {
              'success': false,
              'message': 'Bu e-posta kayıtlı ancak giriş yapılamadı.',
              'error': loginError.toString()
            };
          }
        }
        
        String message = 'Kayit sirasinda bir hata olustu.';
        
        if (e.code == 'weak-password') {
          message = 'Daha guclu bir sifre secin.';
        } else if (e.code == 'invalid-email') {
          message = 'Gecersiz bir e-posta formati.';
        }
        
        print('Firebase Auth hatasi: ${e.code} - ${e.message}');
        return {
          'success': false,
          'message': message,
          'error': e.toString()
        };
      }
    } catch (e, stackTrace) {
      print('Kayit islemi sirasinda beklenmeyen hata: $e');
      print('Stack trace: $stackTrace');
      
      // Kullanıcı başarıyla oluşturulmuş ama başka bir hata olduysa
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        return {
          'success': true,
          'message': 'Kullanici olusturuldu ancak bazi bilgiler eksik olabilir.',
          'userId': currentUser.uid,
        };
      }
      
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata olustu.',
        'error': e.toString()
      };
    }
  }
  
  // Kullanıcı giriş işlemi
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String sifre,
  }) async {
    try {
      // Email kontrolü
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {
          'success': false, 
          'message': 'Gecersiz e-posta adresi.'
        };
      }
      
      // Giriş yap
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: sifre,
        );
        
        return {
          'success': true,
          'message': 'Giris basarili.',
          'userId': userCredential.user!.uid
        };
      } on FirebaseAuthException catch (e) {
        String message = 'Giris sirasinda bir hata olustu.';
        
        if (e.code == 'user-not-found') {
          message = 'Bu e-posta adresine sahip kullanici bulunamadi.';
        } else if (e.code == 'wrong-password') {
          message = 'Hatali sifre.';
        } else if (e.code == 'invalid-email') {
          message = 'Gecersiz bir e-posta formati.';
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
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata olustu.',
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
        'message': 'Çikis basarili.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Çikis sirasinda bir hata olustu.',
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
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email,
      );
      
      return {
        'success': true,
        'message': 'Sifre sifirlama baglantisi gonderildi.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Sifre sifirlama islemi basarisiz.',
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