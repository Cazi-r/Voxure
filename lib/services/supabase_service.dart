// Bu servis, Supabase veritabanı işlemlerini yönetir.
// Anket yönetimi, oy verme işlemleri ve logo yönetimi gibi temel işlevleri sağlar.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  // Supabase istemci örneği
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  // Tüm anketleri veritabanından getirme
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

  // Belirli bir anketin detaylarını getirme
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

  // Veritabanına yeni bir anket ekleme
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

  // Mevcut bir anketin bilgilerini güncelleme
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

  // Bir ankete oy verme ve mükerrer oy kontrolü
  Future<bool> saveVote(Map<String, dynamic> voteData) async {
    try {
      // Mükerrer oy kontrolü
      final existingVote = await _supabase
          .from('votes')
          .select()
          .eq('survey_id', voteData['surveyId'])
          .eq('user_id', voteData['userId']);

      if ((existingVote as List).isNotEmpty) {
        print('Kullanici bu ankete zaten oy vermis: ${voteData['userId']}, ${voteData['surveyId']}');
        return false;
      }

      // Yeni oyu veritabanına kaydet
      await _supabase
          .from('votes')
          .insert({
            'survey_id': voteData['surveyId'],
            'user_id': voteData['userId'],
            'option_index': voteData['optionIndex'],
            'created_at': DateTime.now().toIso8601String(),
          });

      // Anketin toplam oy sayısını güncelle (stored procedure kullanarak)
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

  // Birden fazla oyu toplu olarak kaydetme
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

  // Bir anketin oy istatistiklerini getirme
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

  // Bir kullanıcının belirli bir anketteki oyunu sorgulama
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

  // Bir anketi veritabanından silme
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

  // Dosya sisteminden logo yükleme ve depolama
  Future<String?> uploadLogo(String filePath, String fileName) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      
      // Logo dosyasını Supabase depolama alanına yükle
      await _supabase
          .storage
          .from('logos')  // 'logos' bucket'ina yukle
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Yüklenen logonun genel erişim URL'ini al
      final String publicUrl = _supabase
          .storage
          .from('logos')
          .getPublicUrl(fileName);
          
      return publicUrl;
    } catch (e) {
      print('Logo yuklenirken hata: $e');
      return null;
    }
  }

  // Depolama alanından logo silme
  Future<bool> deleteLogo(String fileName) async {
    try {
      await _supabase
          .storage
          .from('logos')
          .remove([fileName]);
          
      return true;
    } catch (e) {
      print('Logo silinirken hata: $e');
      return false;
    }
  }

  // Bir logonun genel erişim URL'ini alma
  String? getLogoUrl(String fileName) {
    try {
      return _supabase
          .storage
          .from('logos')
          .getPublicUrl(fileName);
    } catch (e) {
      print('Logo URL alinirken hata: $e');
      return null;
    }
  }

  // Uygulama ana logosunu veritabanından getirme
  Future<String?> getAppLogo() async {
    try {
      // 'app_settings' tablosundan logo URL'ini al
      final response = await _supabase
          .from('app_settings')
          .select('logo_url')
          .single();
      
      if (response != null && response['logo_url'] != null) {
        return response['logo_url'];
      }
      
      return null;
    } catch (e) {
      print('Uygulama logosu alinirken hata: $e');
      return null;
    }
  }
} 