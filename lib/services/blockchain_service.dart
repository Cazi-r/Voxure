import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// BlockchainService: Oylama verilerini güvenli şekilde saklayan servis.
/// 
/// Bu servis, oylama verilerini hash'leyerek saklar ve doğrular.
/// Veriler cihazda kalıcı olarak saklanır.
class BlockchainService {
  // Mock blockchain modunda veriler
  final Map<String, dynamic> _mockVotes = {}; // Geçici bellekte oyları saklar
  static const String _votesStorageKey = 'blockchain_mock_votes'; // SharedPreferences anahtarı

  // Constructor - servisi başlat
  BlockchainService() {
    _initialize();
  }

  // Servisi başlatma
  Future<void> _initialize() async {
    try {
      // Kaydedilmiş oyları yükle
      await _loadSavedVotes();
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Kaydedilmiş oyları SharedPreferences'tan yükler
  Future<void> _loadSavedVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedVotesJson = prefs.getString(_votesStorageKey);
      
      if (savedVotesJson != null && savedVotesJson.isNotEmpty) {
        Map<String, dynamic> savedVotes = Map<String, dynamic>.from(
          jsonDecode(savedVotesJson) as Map
        );
        
        // Kaydedilmiş oyları _mockVotes'a yükle
        _mockVotes.clear();
        savedVotes.forEach((key, value) {
          _mockVotes[key] = value;
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Oyları SharedPreferences'a kaydeder
  Future<void> _saveVotesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String votesJson = jsonEncode(_mockVotes);
      await prefs.setString(_votesStorageKey, votesJson);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Oy verme işlemini kaydeder
  Future<bool> saveVote(Map<String, dynamic> voteData) async {
    try {
      // Oy verisini JSON formatına dönüştür
      final String voteJson = jsonEncode(voteData);
      
      // Oy verisinin hash'ini oluştur
      final String voteHash = sha256.convert(utf8.encode(voteJson)).toString();
      
      // Bu oy daha önce kaydedilmiş mi kontrol et
      if (_mockVotes.containsKey(voteHash)) {
        return false;
      }
      
      // Oyu kaydet - tüm veriyi saklayalım ki istatistiklerden kullanabilelim
      _mockVotes[voteHash] = voteData;
      
      // Verileri kalıcı olarak kaydet
      await _saveVotesToStorage();
      
      // İşlemi simüle etmek için kısa bir gecikme
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Toplu oyları kaydeder
  Future<bool> saveBulkVotes(List<Map<String, dynamic>> votesData) async {
    try {
      bool allSuccessful = true;
      
      // Her oy için ayrı işlem
      for (var voteData in votesData) {
        bool success = await saveVote(voteData);
        if (!success) {
          allSuccessful = false;
        }
      }
      
      return allSuccessful;
    } catch (e) {
      return false;
    }
  }

  // Oyun kaydedilmiş olup olmadığını doğrular
  Future<bool> verifyVote(Map<String, dynamic> voteData) async {
    try {
      // Oy verisini JSON formatına dönüştür
      final String voteJson = jsonEncode(voteData);
      
      // Oy verisinin hash'ini oluştur
      final String voteHash = sha256.convert(utf8.encode(voteJson)).toString();
      
      // Oy veritabanında var mı kontrol et
      return _mockVotes.containsKey(voteHash);
    } catch (e) {
      return false;
    }
  }
  
  // İstatistik sayfası için tüm anketlerin oy verilerini döndürür
  Future<Map<String, Map<int, int>>> getAllSurveyVotes() async {
    // Sonuç formatı: {'anket_id': {0: 5, 1: 10, 2: 3}, ...}
    // Burada 0, 1, 2 seçenek indeksleri, yanındaki değerler oy sayılarıdır
    
    Map<String, Map<int, int>> allVotes = {};
    
    try {
      // Önce SharedPreferences'tan güncel verileri yükleyelim
      try {
        final prefs = await SharedPreferences.getInstance();
        String? savedVotesJson = prefs.getString(_votesStorageKey);
        
        if (savedVotesJson != null && savedVotesJson.isNotEmpty) {
          // Bellekteki mock votes'u SharedPreferences'tan gelen verilerle güncelleyelim
          _mockVotes.clear();
          Map<String, dynamic> savedVotes = jsonDecode(savedVotesJson) as Map<String, dynamic>;
          _mockVotes.addAll(savedVotes.map((key, value) => MapEntry(key, value)));
        }
      } catch (e) {
        // SharedPreferences hatası - sessizce devam et
      }
      
      // Tüm kaydedilen oyları tara
      _mockVotes.forEach((hash, value) {
        try {
          // Veri çıkarma
          final Map<String, dynamic> voteData = value as Map<String, dynamic>;
          final String surveyId = voteData['surveyId'] as String;
          final int optionIndex = voteData['optionIndex'] as int;
          
          // Anket için oy mapini oluştur veya mevcut olanı al
          if (!allVotes.containsKey(surveyId)) {
            allVotes[surveyId] = {};
          }
          
          // Seçenek için oy sayısını artır
          allVotes[surveyId]![optionIndex] = (allVotes[surveyId]![optionIndex] ?? 0) + 1;
        } catch (e) {
          // Veri işleme hatası - bu veriyi atla
        }
      });
    } catch (e) {
      // Genel hata - boş sonuç döndür
    }
    
    return allVotes;
  }
  
  // Belirli bir anketin oy verilerini döndürür
  Future<Map<int, int>> getSurveyVotes(String surveyId) async {
    Map<int, int> voteCount = {};
    Map<String, Map<int, int>> allVotes = await getAllSurveyVotes();
    
    if (allVotes.containsKey(surveyId)) {
      return allVotes[surveyId]!;
    }
    
    return voteCount; // Boş map döner (oy yoksa)
  }
  
  // Belirli bir kullanıcının belirli bir anketteki oy bilgisini döndürür
  Future<Map<String, dynamic>?> getUserVote(String userId, String surveyId) async {
    try {
      // Tüm kaydedilen oyları tara
      for (var entry in _mockVotes.entries) {
        if (entry.value is Map<String, dynamic>) {
          Map<String, dynamic> voteData = entry.value as Map<String, dynamic>;
          // userId ve surveyId eşleşen oyu bul
          if (voteData['userId'] == userId && voteData['surveyId'] == surveyId) {
            return voteData; // Kullanıcının bu anket için oy bilgisini döndür
          }
        }
      }
      return null; // Oy bulunamadı
    } catch (e) {
      return null;
    }
  }
} 