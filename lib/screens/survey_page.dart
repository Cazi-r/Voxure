import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/custom_app_bar.dart';
import '../services/firebase_service.dart';
import '../services/survey_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// SurveyPage: Kullanıcının anketlere oy verebildiği sayfa.
///
/// Bu sayfa kullanıcı profiline göre filtrelenmiş anketleri gösterir
/// ve kullanıcının oy vermesini sağlar. Oylar blockchain servisine kaydedilir.
class SurveyPage extends StatefulWidget {
  @override
  State<SurveyPage> createState() => SurveyPageState();
}

class SurveyPageState extends State<SurveyPage> {
  // Servisler
  final FirebaseService _firebaseService = FirebaseService();
  final SurveyService _surveyService = SurveyService();
  
  // Kullanıcı bilgileri
  String? userId;
  int? userAge;
  String? userCity;
  String? userSchool;
  
  // Anket verileri
  List<Map<String, dynamic>> surveys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Kullanıcı bilgilerini yükler
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Mevcut kullanıcı bilgilerini al
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        userId = currentUser.uid;
        
        // Kullanıcı profil bilgilerini Firestore'dan al
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            userCity = userData['city'];
            userSchool = userData['school'];
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
      }
    } catch (e) {
      print('Kullanici bilgileri yuklenirken hata: $e');
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
      List<Map<String, dynamic>> updatedSurveys = [];
      
      for (var survey in loadedSurveys) {
        // Kullanicinin bu ankete daha once oy verip vermedigini kontrol et
        bool hasVoted = await _hasUserVoted(survey['id']);
        
        if (hasVoted) {
          // Kullanicinin onceki oyunu getir
          var userVote = await _firebaseService.getUserVote(userId!, survey['id']);
          
          updatedSurveys.add({
            ...survey,
            'oyVerildi': true,
            'kilitlendi': true,
            'secilenSecenek': userVote?['optionIndex'],
          });
        } else {
          updatedSurveys.add({
            ...survey,
            'oyVerildi': false,
            'secilenSecenek': null,
          });
        }
      }
      
      setState(() {
        surveys = updatedSurveys;
      });
    } catch (e) {
      print('Anketleri yüklerken hata: $e');
    }
  }
  
  /// Kullanıcının belirli bir ankete oy verip vermediğini kontrol eder
  Future<bool> _hasUserVoted(String surveyId) async {
    if (userId == null) return false;
    
    try {
      final userVote = await _firebaseService.getUserVote(userId!, surveyId);
      return userVote != null;
    } catch (e) {
      print('Oy kontrolu sirasinda hata: $e');
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
      appBar: CustomAppBar(
        title: 'Anketler',
        showInfoButton: true,
        onInfoPressed: _showInfoDialog,
        showSaveButton: true,
        onSavePressed: () {
          _showSaveConfirmationDialog();
        },
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

  /// Tüm oyları Firebase'e kaydeder
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
        return Center(child: CircularProgressIndicator());
      },
    );
    
    try {
      // Oyları Firebase'e kaydet
      final success = await _firebaseService.saveBulkVotes(votesToSave);
      
      // Progress indicator'ı kapat
      Navigator.of(context).pop();
      
      if (success) {
        // Başarılı kayıt sonrası anketleri kilitle
        setState(() {
          for (var survey in surveys) {
            if (survey['oyVerildi'] == true && survey['kilitlendi'] != true) {
              survey['kilitlendi'] = true;
            }
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oylarınız başarıyla kaydedildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bazı oylar kaydedilemedi, lütfen tekrar deneyin')),
        );
      }
    } catch (e) {
      // Progress indicator'ı kapat
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oylar kaydedilirken bir hata oluştu')),
      );
    }
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
