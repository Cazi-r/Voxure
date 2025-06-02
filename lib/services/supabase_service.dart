import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  // Anketleri getir
  Future<List<Map<String, dynamic>>> getSurveys() async {
    try {
      final response = await _supabase
          .from('surveys')
          .select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Anketleri getirirken hata: $e');
      return [];
    }
  }

  // Belirli bir anketi getir
  Future<Map<String, dynamic>?> getSurvey(String surveyId) async {
    try {
      final response = await _supabase
          .from('surveys')
          .select()
          .eq('id', surveyId)
          .single();

      return response;
    } catch (e) {
      print('Anketi getirirken hata: $e');
      return null;
    }
  }

  // Yeni anket ekle
  Future<String?> addSurvey(Map<String, dynamic> survey) async {
    try {
      final response = await _supabase
          .from('surveys')
          .insert(survey)
          .select();

      return response[0]['id'];
    } catch (e) {
      print('Anket eklerken hata: $e');
      return null;
    }
  }

  // Anketi guncelle
  Future<bool> updateSurvey(String surveyId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('surveys')
          .update(data)
          .eq('id', surveyId);

      return true;
    } catch (e) {
      print('Anketi guncellerken hata: $e');
      return false;
    }
  }

  // Oy kullan
  Future<bool> saveVote(Map<String, dynamic> voteData) async {
    try {
      // Kullanicinin daha once oy verip vermedigini kontrol et
      final existingVote = await _supabase
          .from('votes')
          .select()
          .eq('survey_id', voteData['surveyId'])
          .eq('user_id', voteData['userId']);

      if ((existingVote as List).isNotEmpty) {
        print('Kullanici bu ankete zaten oy vermis: ${voteData['userId']}, ${voteData['surveyId']}');
        return false;
      }

      // Yeni oyu kaydet
      await _supabase
          .from('votes')
          .insert({
            'survey_id': voteData['surveyId'],
            'user_id': voteData['userId'],
            'option_index': voteData['optionIndex'],
            'created_at': DateTime.now().toIso8601String(),
          });

      // Anketin oy sayisini guncelle
      await _supabase.rpc(
        'increment_survey_vote',
        params: {
          'survey_id': voteData['surveyId'],
          'option_index': voteData['optionIndex'],
        },
      );

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

  // Bir anketin oy verilerini getirir
  Future<Map<int, int>> getSurveyVotes(String surveyId) async {
    try {
      final response = await _supabase
          .from('surveys')
          .select('oylar')
          .eq('id', surveyId)
          .single();

      if (response != null && response['oylar'] != null) {
        List<dynamic> votes = response['oylar'];
        Map<int, int> voteMap = {};
        
        for (int i = 0; i < votes.length; i++) {
          voteMap[i] = votes[i];
        }
        
        return voteMap;
      }
      
      return {};
    } catch (e) {
      print('Anket oylari alinirken hata: $e');
      return {};
    }
  }

  // Kullanicinin oyunu getir
  Future<Map<String, dynamic>?> getUserVote(String userId, String surveyId) async {
    try {
      final response = await _supabase
          .from('votes')
          .select()
          .eq('user_id', userId)
          .eq('survey_id', surveyId)
          .maybeSingle();

      if (response == null) return null;

      return {
        'userId': userId,
        'surveyId': surveyId,
        'optionIndex': response['option_index'],
      };
    } catch (e) {
      print('Kullanici oyu alinirken hata: $e');
      return null;
    }
  }

  // Anketi sil
  Future<bool> deleteSurvey(String surveyId) async {
    try {
      await _supabase
          .from('surveys')
          .delete()
          .eq('id', surveyId);

      return true;
    } catch (e) {
      print('Anketi silerken hata: $e');
      return false;
    }
  }
} 