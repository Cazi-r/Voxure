import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/blockchain_service.dart';
import '../services/survey_service.dart';

/// SurveyPage: Kullanıcının anketlere oy verebildiği sayfa.
///
/// Bu sayfa kullanıcı profiline göre filtrelenmiş anketleri gösterir
/// ve kullanıcının oy vermesini sağlar. Oylar blockchain servisine kaydedilir.
class SurveyPage extends StatefulWidget {
  @override
  State<SurveyPage> createState() => SurveyPageState();
}

class SurveyPageState extends State<SurveyPage> {
  // Firebase ve blockchain servisleri
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BlockchainService _blockchainService = BlockchainService();
  final SurveyService _surveyService = SurveyService();
  
  // Kullanıcı bilgileri
  String? userId;
  int? userAge;
  String? userCity;
  String? userSchool;
  
  // Veri yükleniyor mu?
  bool isLoading = true;

  // Anket verileri listesi
  List<Map<String, dynamic>> surveys = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Kullanıcının profil bilgilerini Firestore'dan yükler
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Mevcut kullanıcı bilgilerini al
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        userId = currentUser.uid;
        
        // Kullanıcı profil bilgilerini Firestore'dan al
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // İl ve okul bilgisini al
          setState(() {
            userCity = userData['city'] as String?;
            userSchool = userData['school'] as String?;
          });
          
          // Doğum tarihini al ve yaşı hesapla
          Timestamp? birthDateTimestamp = userData['birthDate'] as Timestamp?;
          
          if (birthDateTimestamp != null) {
            DateTime birthDate = birthDateTimestamp.toDate();
            DateTime now = DateTime.now();
            int age = now.year - birthDate.year;
            
            // Doğum günü bu yıl henüz geçmediyse yaşından 1 çıkar
            if (now.month < birthDate.month || 
                (now.month == birthDate.month && now.day < birthDate.day)) {
              age--;
            }
            
            setState(() {
              userAge = age;
            });
          } else {
            // Varsayılan yaş
            setState(() {
              userAge = 18;
            });
          }
        }
        
        // Anketleri Firestore'dan yükle
        await _loadSurveys();
        
        // Kullanıcı bilgileri yüklendikten sonra blockchain verilerini yükle
        await _loadVotesFromBlockchain();
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  /// Firestore'dan anketleri yükler
  Future<void> _loadSurveys() async {
    try {
      List<Map<String, dynamic>> loadedSurveys = await _surveyService.getSurveys();
      
      // Anketleri yükle ve kullanıcı verilerine göre filtrele
      setState(() {
        surveys = loadedSurveys.map((survey) {
          // Her ankete eksik olan kullanıcı bilgilerini ekle
          return {
            ...survey,
            'oyVerildi': false,
            'secilenSecenek': null,
          };
        }).toList();
      });
    } catch (e) {
      print('Anketleri yüklerken hata: $e');
    }
  }
  
  /// Blockchain'den oy verilerini yükler
  Future<void> _loadVotesFromBlockchain() async {
    try {
      if (userId == null) return;
      
      // Her anket için ayrı ayrı blockchain'den oy verilerini al
      for (var i = 0; i < surveys.length; i++) {
        String surveyId = surveys[i]['id'];
        
        // Blockchain'den bu anket için oy verileri al
        Map<int, int> voteData = await _blockchainService.getSurveyVotes(surveyId);
        
        if (voteData.isNotEmpty) {
          // Tüm anket oylarını güncelle
          List<int> newVotes = List<int>.filled(surveys[i]['secenekler'].length, 0);
          voteData.forEach((optionIndex, count) {
            if (optionIndex >= 0 && optionIndex < newVotes.length) {
              newVotes[optionIndex] = count;
            }
          });
          
          // Bu anket için toplam oylar
          surveys[i]['oylar'] = newVotes;
          
          // Kullanıcının bu anket için önceden oy verip vermediğini kontrol et
          Map<String, dynamic>? userVote = await _blockchainService.getUserVote(userId!, surveyId);
          
          if (userVote != null) {
            // Kullanıcının verdiği oyu bulduysak, anketi kilitli olarak işaretle
            int optionIndex = userVote['optionIndex'] as int;
            
            setState(() {
              surveys[i]['oyVerildi'] = true;
              surveys[i]['kilitlendi'] = true;
              surveys[i]['secilenSecenek'] = optionIndex;
            });
          }
        }
      }
    } catch (e) {
      print('Blockchain verileri yuklenirken hata: $e');
      // Hata durumunda sessizce devam et
    }
  }
  
  /// Kullanıcının belirli bir ankete oy verip vermediğini kontrol eder
  Future<bool> _checkIfUserVotedForSurvey(String surveyId) async {
    try {
      if (userId == null) return false;
      
      // BlockchainService'in getUserVote metodunu kullan
      Map<String, dynamic>? userVote = await _blockchainService.getUserVote(userId!, surveyId);
      
      // Eğer kullanıcı oyu bulunduysa true döndür
      return userVote != null;
    } catch (e) {
      // Hata durumunda sessizce devam et
      return false;
    }
  }

  /// Kullanıcı bir seçeneği seçtiğinde çağrılan metot
  void vote(int surveyIndex, int optionIndex) async {
    if (userId == null) return;
    
    // Anket kilitlenmişse işlemi engelle
    if (surveys[surveyIndex]['kilitlendi'] == true) {
      return;
    }
    
    setState(() {
      // Kullanici daha once oy verdiyse onceki oyu geri al
      if (surveys[surveyIndex]['oyVerildi'] == true) {
        int oncekiSecenek = surveys[surveyIndex]['secilenSecenek'];
        surveys[surveyIndex]['oylar'][oncekiSecenek]--;
      }
      
      // Seçilen seçeneğin oy sayısını artır
      surveys[surveyIndex]['oylar'][optionIndex]++;
      surveys[surveyIndex]['oyVerildi'] = true;
      surveys[surveyIndex]['secilenSecenek'] = optionIndex;
    });
    
    // Oy verilerini blockchain icin hazirla
    final Map<String, dynamic> voteData = {
      'userId': userId,
      'surveyId': surveys[surveyIndex]['id'],
      'optionIndex': optionIndex,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Anketin kullanıcıya gösterilip gösterilmeyeceğini kontrol eder
  bool shouldShowSurvey(Map<String, dynamic> survey) {
    // Yaş kontrolü
    if (userAge != null && survey['minYas'] != null && userAge! < survey['minYas']) {
      return false;
    }
    
    // İl kontrolü
    if (survey['ilFiltresi'] == true && (userCity == null || userCity!.isEmpty)) {
      return false;
    }
    
    // Belirli bir il için filtreleme
    if (survey['belirliIl'] != null) {
      String belirliIl = survey['belirliIl'];
      if (userCity != belirliIl) {
        return false;
      }
    }
    
    // Okul kontrolü
    if (survey['okulFiltresi'] == true) {
      // Okul bilgisi yoksa veya "Okumuyorum" ise anketi gösterme
      if (userSchool == null || userSchool!.isEmpty || userSchool == 'Okumuyorum') {
        return false;
      }
      
      // Belirli bir okul için filtreleme
      if (survey['belirliOkul'] != null) {
        String belirliOkul = survey['belirliOkul'];
        if (userSchool != belirliOkul) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text('Anketler'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'Anket Bilgisi',
            onPressed: () {
              _showInfoDialog();
            },
          ),
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Tum secimleri kaydet',
            onPressed: () {
              _showSaveConfirmationDialog();
            },
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: isLoading 
          ? Center(child: CircularProgressIndicator())
          : (userAge == null || (userCity == null && userSchool == null))
              ? _buildProfileUpdateReminder()
              : Column(
                  children: [
                    // Anket listesi
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: surveys.length,
                        itemBuilder: (context, index) {
                          // Anketin gösterilip gösterilmeyeceğini kontrol et
                          if (shouldShowSurvey(surveys[index])) {
                            return createSurveyCard(index);
                          } else {
                            // Anketi gösterme
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
  
  /// Profil bilgileri eksik olduğunda gösterilen uyarı widget'ı
  Widget _buildProfileUpdateReminder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 70, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'Anketlere katılabilmek için önce profil bilgilerinizi tamamlamanız gerekmektedir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile_update');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5181BE),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Profil Bilgilerimi Güncelle',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _loadUserData();
              },
              icon: Icon(Icons.refresh, color: Color(0xFF5181BE)),
              label: Text(
                'Bilgilerimi Yenile',
                style: TextStyle(color: Color(0xFF5181BE)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Anket kartını oluşturan widget metodu
  Widget createSurveyCard(int surveyIndex) {
    Map<String, dynamic> survey = surveys[surveyIndex];
    bool hasVoted = survey['oyVerildi'] == true;
    
    // İkon ve renk dönüşümleri
    IconData iconData = _getIconFromValue(survey['ikon']);
    Color iconColor = _getColorFromValue(survey['renk']) ?? Colors.blue;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru başlığı ve anket ikonu
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(iconData, size: 28, color: iconColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    survey['soru'] ?? 'Basliksiz Anket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Anket seçenekleri listesi
          Column(
            children: List.generate(
              survey['secenekler'].length,
              (optionIndex) =>
                  createOptionRow(surveyIndex, optionIndex, hasVoted),
            ),
          ),

          SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Her seçenek için satır oluşturan widget metodu
  Widget createOptionRow(int surveyIndex, int optionIndex, bool hasVoted) {
    Map<String, dynamic> survey = surveys[surveyIndex];
    String option = survey['secenekler'][optionIndex];
    bool isSelected = survey['secilenSecenek'] == optionIndex;
    bool isLocked = survey['kilitlendi'] == true;
    
    // Renk dönüşümü
    Color iconColor = _getColorFromValue(survey['renk']) ?? Colors.blue;

    return ListTile(
      onTap: isLocked
          ? null
          : () {
              vote(surveyIndex, optionIndex);
            },
      leading: Icon(
        hasVoted
            ? (isSelected ? Icons.check_circle : Icons.circle_outlined)
            : Icons.radio_button_unchecked,
        color: hasVoted && isSelected 
               ? (isLocked ? Colors.grey.shade700 : iconColor) 
               : Colors.grey,
      ),
      title: Text(
        option,
        style: TextStyle(
          color: hasVoted && !isSelected ? Colors.grey : Colors.black,
          fontWeight: isLocked && isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: hasVoted
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLocked && isSelected)
                  Icon(Icons.lock, size: 16, color: Colors.grey),
              ],
            )
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
    );
  }

  /// Oy kaydetme onay dialogunu gösterir
  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dikkat'),
          content: Text('Secimlerinizi bir daha degistiremezsiniz. Emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetUnconfirmedVotes();
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveAllVotes();
              },
              child: Text('Eminim'),
            ),
          ],
        );
      },
    );
  }

  /// Kaydedilmemiş oyları sıfırlar
  void _resetUnconfirmedVotes() {
    setState(() {
      for (var survey in surveys) {
        // Sadece oyVerildi=true ve kilitlendi=false olan anketleri sıfırla
        if (survey['oyVerildi'] == true && survey['kilitlendi'] != true) {
          // Kullanıcının seçimini iptal et
          int secilenSecenek = survey['secilenSecenek'];
          survey['oylar'][secilenSecenek]--;
          survey['oyVerildi'] = false;
          survey['secilenSecenek'] = null;
        }
      }
    });
    
    // Kullanıcıyı bilgilendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kaydedilmemiş seçimleriniz iptal edildi')),
    );
  }

  /// Tüm oyları blockchain'e kaydeder
  void _saveAllVotes() async {
    if (userId == null) return;
    
    // Kaydedilecek tüm anketleri topla (sadece kilitli olmayanlar)
    List<Map<String, dynamic>> votesToSave = [];
    
    for (int i = 0; i < surveys.length; i++) {
      if (surveys[i]['oyVerildi'] == true && surveys[i]['kilitlendi'] != true) {
        votesToSave.add({
          'userId': userId,
          'surveyId': surveys[i]['id'],
          'optionIndex': surveys[i]['secilenSecenek'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
    
    if (votesToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilecek yeni bir seçiminiz bulunmamaktadır!')),
      );
      return;
    }
    
    // İşlem sırasında progress indicator göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Oylarınız kaydediliyor...'),
            ],
          ),
        );
      },
    );
    
    // Tüm oyları kaydet
    try {
      // Blockchain entegrasyonu: Tüm oyları kaydet
      bool success = await _blockchainService.saveBulkVotes(votesToSave);
      
      // Dialog'u kapat
      Navigator.of(context).pop();
      
      if (success) {
        // Kullanıcıyı bilgilendir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tüm seçimleriniz başarıyla kaydedildi.'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Oyların değiştirilememesi için sadece kaydedilen anketleri kilitle
        setState(() {
          for (var i = 0; i < surveys.length; i++) {
            if (surveys[i]['oyVerildi'] == true && surveys[i]['kilitlendi'] != true) {
              surveys[i]['kilitlendi'] = true;
            }
          }
        });
      } else {
        // Başarısız işlem
        _showBlockchainErrorDialog();
      }
    } catch (e) {
      // Dialog'u kapat
      Navigator.of(context).pop();
      _showBlockchainErrorDialog();
    }
  }
  
  /// Blockchain hatası için dialog
  void _showBlockchainErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kayıt Hatası'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Oylarınız kaydedilirken bir sorun oluştu.'),
              SizedBox(height: 16),
              Text('Lütfen daha sonra tekrar deneyiniz.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Anladım'),
            ),
          ],
        );
      },
    );
  }

  /// Anket bilgisi dialog penceresi
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF5181BE)),
              SizedBox(width: 8),
              Text('Anket Bilgisi'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Anketler profil bilgilerinize göre düzenlenmiştir.'),
              SizedBox(height: 8),
              Text('• Yaşadığınız il, yaşınız ve okulunuz gibi bilgiler anketlerin gösteriminde etkilidir.'),
              SizedBox(height: 8),
              Text('• Seçimlerinizi kaydetmek için sağ üstteki kaydet butonuna tıklayın.'),
              SizedBox(height: 8),
              Text('• Oylar kaydedildikten sonra değiştirilemez veya silinemez.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Anladım'),
            ),
          ],
        );
      },
    );
  }
  
  // Icon değerini IconData'ya dönüştürür
  IconData _getIconFromValue(dynamic iconValue) {
    // Basit bir ikonlar maplemesi
    Map<String, IconData> iconMap = {
      'poll': Icons.poll,
      'how_to_vote': Icons.how_to_vote,
      'location_city': Icons.location_city,
      'school': Icons.school,
      'computer': Icons.computer,
      'public': Icons.public,
    };
    
    if (iconValue is int) {
      // IconData zaten bir int değeri olarak saklanmış olabilir
      return IconData(iconValue, fontFamily: 'MaterialIcons');
    } else if (iconValue is String && iconMap.containsKey(iconValue)) {
      return iconMap[iconValue]!;
    }
    
    // Varsayılan ikon
    return Icons.poll;
  }

  // Renk değerini Color'a dönüştürür
  Color? _getColorFromValue(dynamic colorValue) {
    // Basit bir renkler maplemesi
    Map<String, Color> colorMap = {
      'green': Colors.green,
      'blue': Colors.blue,
      'brown': Colors.brown,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'red': Colors.red,
    };
    
    if (colorValue is int) {
      // Color zaten bir int değeri olarak saklanmış olabilir
      return Color(colorValue);
    } else if (colorValue is String && colorMap.containsKey(colorValue)) {
      return colorMap[colorValue];
    }
    
    // Varsayılan renk
    return Colors.blue;
  }
}
