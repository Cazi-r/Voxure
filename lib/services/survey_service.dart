import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'surveys';

  // Tüm anketleri getir
  Future<List<Map<String, dynamic>>> getSurveys() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_collection).get();
      List<Map<String, dynamic>> surveys = querySnapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
      return surveys;
    } catch (e) {
      print('Anketleri getirirken hata: $e');
      return [];
    }
  }

  // Belirli bir anketi getir
  Future<Map<String, dynamic>?> getSurvey(String surveyId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(surveyId).get();
      if (doc.exists) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      print('Anketi getirirken hata: $e');
      return null;
    }
  }

  // Yeni anket ekle
  Future<String?> addSurvey(Map<String, dynamic> survey) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(survey);
      return docRef.id;
    } catch (e) {
      print('Anket eklerken hata: $e');
      return null;
    }
  }

  // Anketi güncelle
  Future<bool> updateSurvey(String surveyId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(surveyId).update(data);
      return true;
    } catch (e) {
      print('Anketi güncellerken hata: $e');
      return false;
    }
  }

  // Oy kullan
  Future<bool> voteSurvey(String surveyId, int selectedOption) async {
    try {
      // Transaction ile oy sayılarını güncelle
      await _firestore.runTransaction((transaction) async {
        DocumentReference surveyRef = _firestore.collection(_collection).doc(surveyId);
        DocumentSnapshot snapshot = await transaction.get(surveyRef);
        
        if (!snapshot.exists) {
          throw Exception("Anket bulunamadı");
        }
        
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> votes = List.from(data['oylar']);
        
        // Seçilen seçeneğin oy sayısını artır
        votes[selectedOption] = votes[selectedOption] + 1;
        
        transaction.update(surveyRef, {'oylar': votes});
      });
      
      return true;
    } catch (e) {
      print('Oy kullanırken hata: $e');
      return false;
    }
  }

  // Anketi sil
  Future<bool> deleteSurvey(String surveyId) async {
    try {
      await _firestore.collection(_collection).doc(surveyId).delete();
      return true;
    } catch (e) {
      print('Anketi silerken hata: $e');
      return false;
    }
  }
} 