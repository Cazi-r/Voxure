import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class SurveyPage extends StatefulWidget {
  @override
  State<SurveyPage> createState() => SurveyPageState();
}

class SurveyPageState extends State<SurveyPage> {
  // Firebase referansları (sadece profil bilgileri için)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Giriş yapan kullanıcının ID'si
  String? userId;
  
  // Kullanıcı bilgileri
  int? userAge;
  String? userCity;
  String? userSchool;
  
  // Veri yükleniyor mu?
  bool isLoading = true;

  // Anket verileri listesi - Her anket bir Map olarak tanımlanmıştır
  // Her Map içerisinde soru metni, seçenekler, oy sayıları, kullanıcı tercihi, görsel öğeler bulunur
  List<Map<String, dynamic>> surveys = [
    {
      'id': 'cumhurbaskanligi_secimi',
      'soru': 'Cumhurbaşkanlığı seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Kişisi', 'B Kişisi', 'C Kişisi'],
      'oylar': [0, 0, 0],
      'oyVerildi': false,
      'secilenSecenek': null,
      'kilitlendi': false,
      'ikon': Icons.how_to_vote,
      'renk': Colors.green,
      'minYas': 18, // 18 yaş ve üzeri
      'ilFiltresi': null, // İl filtresi yok
      'okulFiltresi': null, // Okul filtresi yok
      'belirliOkul': null, // Belirli bir okul seçimi yok
    },
    {
      'id': 'belediye_secimi',
      'soru': 'İstanbul belediye başkanlığı seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Adayı', 'B Adayı', 'C Adayı', 'D Adayı'],
      'oylar': [0, 0, 0, 0],
      'oyVerildi': false,
      'secilenSecenek': null,
      'kilitlendi': false,
      'ikon': Icons.location_city,
      'renk': Colors.blue,
      'minYas': 18, // 18 yaş ve üzeri
      'ilFiltresi': true, // İl bilgisi olmalı
      'okulFiltresi': null, // Okul filtresi yok
      'belirliOkul': null, // Belirli bir okul seçimi yok
      'belirliIl': 'İstanbul', // Sadece İstanbul'da yaşayanlar görebilir
    },
    {
      'id': 'okul_temsilcisi',
      'soru': 'İstanbul Sabahattin Zaim Üniversitesi öğrenci temsilcisi seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Öğrenci', 'B Öğrenci', 'C Öğrenci'],
      'oylar': [0, 0, 0],
      'oyVerildi': false,
      'secilenSecenek': null,
      'kilitlendi': false,
      'ikon': Icons.school,
      'renk': Colors.brown,
      'minYas': 0, // Yaş sınırı yok
      'ilFiltresi': null, // İl filtresi yok
      'okulFiltresi': true, // Okul bilgisi olmalı ve "Okumuyorum" olmamalı
      'belirliOkul': 'İstanbul Sabahattin Zaim Üniversitesi', // Sadece İstanbul Sabahattin Zaim Üniversitesi öğrencileri
    },
    {
      'id': 'isletim_sistemi',
      'soru': 'Hangi işletim sistemini tercih ediyorsunuz?',
      'secenekler': ['Windows', 'Linux', 'MacOS', 'Pardus'],
      'oylar': [0, 0, 0, 0],
      'oyVerildi': false,
      'secilenSecenek': null,
      'kilitlendi': false,
      'ikon': Icons.computer,
      'renk': Colors.orange,
      'minYas': 12, // 12 yaş ve üzeri
      'ilFiltresi': null, // İl filtresi yok
      'okulFiltresi': null, // Okul filtresi yok
      'belirliOkul': null, // Belirli bir okul seçimi yok
    },
    {
      'id': 'sosyal_medya',
      'soru': 'Hangi sosyal medya platformunu daha sık kullanıyorsunuz?',
      'secenekler': ['Instagram', 'Twitter (X)', 'TikTok', 'Facebook'],
      'oylar': [0, 0, 0, 0],
      'oyVerildi': false,
      'secilenSecenek': null,
      'kilitlendi': false,
      'ikon': Icons.public,
      'renk': Colors.purple,
      'minYas': 15, // 15 yaş ve üzeri
      'ilFiltresi': null, // İl filtresi yok
      'okulFiltresi': null, // Okul filtresi yok
      'belirliOkul': null, // Belirli bir okul seçimi yok
    },
  ];

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgilerini yükle
    _loadUserData();
  }

  // Kullanıcının profil bilgilerini Firestore'dan yükler
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Mevcut kullanıcı
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Kullanıcı ID'sini kaydet
        userId = currentUser.uid;
        developer.log("Mevcut kullanıcı: $userId", name: 'survey_page');
        
        // Kullanıcı profil bilgilerini Firestore'dan al (yaş, il ve okul için)
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
          
          developer.log("Kullanıcı şehri: $userCity, okulu: $userSchool", name: 'survey_page');
          
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
            developer.log("Hesaplanan kullanıcı yaşı: $userAge", name: 'survey_page');
          } else {
            developer.log("UYARI: birthDate alanı bulunamadı veya null", name: 'survey_page');
            // Doğum tarihi olmasa bile diğer profil bilgileri varsa anketleri göstermek için
            // varsayılan bir yaş ata (örneğin 18)
            setState(() {
              userAge = 18; // Varsayılan yaş
            });
          }
        } else {
          developer.log("UYARI: Kullanıcı dokümanı bulunamadı", name: 'survey_page');
        }
      } else {
        developer.log("HATA: Oturum açmış kullanıcı bulunamadı", name: 'survey_page');
      }
    } catch (e) {
      developer.log("Kullanıcı veri yüklenirken hata: $e", name: 'survey_page');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Kullanıcı bir seçeneği seçtiğinde çağrılan metot
  // Seçilen seçeneğin oy sayısını artırır ve kullanıcı tercihini kaydeder
  // Burada ileride blockchain entegrasyonu yapılacak
  void vote(int surveyIndex, int optionIndex) async {
    if (userId == null) return; // Kullanıcı giriş yapmamışsa işlem yapma
    
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
      
      // Seçilen seçeneğin oy sayısını bir artır
      surveys[surveyIndex]['oylar'][optionIndex]++;
      // Bu anket için kullanıcının oy verdiğini işaretle ve seçimini kaydet
      surveys[surveyIndex]['oyVerildi'] = true;
      surveys[surveyIndex]['secilenSecenek'] = optionIndex;
    });
    
    // TODO: Blockchain entegrasyonu için oy verilerini hazırla
    final Map<String, dynamic> voteData = {
      'userId': userId,
      'surveyId': surveys[surveyIndex]['id'],
      'optionIndex': optionIndex,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    developer.log("Oy verildi: $voteData", name: 'survey_page');
    // Burada blockchain'e veri gönderme işlemi yapılacak
  }

  // Anketin kullanıcıya gösterilip gösterilmeyeceğini kontrol eder
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
  
  // Profil güncelleme hatırlatıcısı
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
            // Yenileme butonu
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

  // Anket kartını oluşturan widget metodu
  // Her anket için başlık, simge ve seçenekleri içeren kart oluşturur
  Widget createSurveyCard(int surveyIndex) {
    Map<String, dynamic> survey = surveys[surveyIndex];
    bool hasVoted = survey['oyVerildi'] == true;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru başlığı ve anket ikonu
          // Başlık üst kısmında anketin konusuyla ilgili bir ikon ve soru metni bulunur
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(survey['ikon'], size: 28, color: survey['renk']),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    survey['soru'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Anket seçenekleri listesi
          // Anketin tüm seçeneklerini ayrı satırlar halinde alt alta listeler
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

  // Her seçenek için ayrı bir satır oluşturan widget metodu
  // Seçenek adını, seçim durumunu ve oy verilmiş ise oy sayısını gösterir
  Widget createOptionRow(
      int surveyIndex, int optionIndex, bool hasVoted) {
    Map<String, dynamic> survey = surveys[surveyIndex];
    String option = survey['secenekler'][optionIndex];
    bool isSelected = survey['secilenSecenek'] == optionIndex;
    bool isLocked = survey['kilitlendi'] == true;

    return ListTile(
      // Sadece anket kilitlenmişse tıklama devre dışı bırakılır
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
               ? (isLocked ? Colors.grey.shade700 : survey['renk']) 
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

  // Kaydetme onay dialogunu goster
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
                Navigator.of(context).pop(); // Dialog'u kapat
                _resetUnconfirmedVotes(); // Kaydedilmemis oylari sifirla
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _saveAllVotes(); // Tum oylari kaydet
              },
              child: Text('Eminim'),
            ),
          ],
        );
      },
    );
  }

  // Kaydedilmemis/kilitlenmemis oylari sifirla
  void _resetUnconfirmedVotes() {
    setState(() {
      for (var survey in surveys) {
        // Sadece oyVerildi=true ve kilitlendi=false olan anketleri sifirla
        if (survey['oyVerildi'] == true && survey['kilitlendi'] != true) {
          // Kullanicinin secimini iptal et
          int secilenSecenek = survey['secilenSecenek'];
          // Oy sayisini azalt
          survey['oylar'][secilenSecenek]--;
          // Anket degerlerini sifirla
          survey['oyVerildi'] = false;
          survey['secilenSecenek'] = null;
        }
      }
    });
    
    // Kullaniciyi bilgilendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kaydedilmemis secimleriniz iptal edildi')),
    );
  }

  // Tum oylari kaydet
  void _saveAllVotes() async {
    if (userId == null) return; // Kullanici giris yapmamissa islem yapma
    
    // Kaydedilecek tum anketleri topla
    List<Map<String, dynamic>> votesToSave = [];
    
    for (int i = 0; i < surveys.length; i++) {
      if (surveys[i]['oyVerildi'] == true) {
        votesToSave.add({
          'userId': userId,
          'surveyId': surveys[i]['id'],
          'optionIndex': surveys[i]['secilenSecenek'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
    
    if (votesToSave.isEmpty) {
      // Henuz hicbir oy verilmemisse kullaniciyi bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Henuz hicbir anket icin oy vermediniz!')),
      );
      return;
    }
    
    // Tum oylari kaydet
    try {
      // TODO: Blockchain entegrasyonu burada yapilacak
      developer.log("Tum oylar kaydedildi: $votesToSave", name: 'survey_page');
      
      // Kullaniciyi bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tum secimleriniz basariyla kaydedildi.')),
      );
      
      // Oylarin degistirilememesi icin tum anketleri kilitle
      setState(() {
        for (var survey in surveys) {
          if (survey['oyVerildi'] == true) {
            survey['kilitlendi'] = true;
          }
        }
      });
    } catch (e) {
      developer.log("Oy kaydedilirken hata: $e", name: 'survey_page');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oylar kaydedilirken bir hata olustu!')),
      );
    }
  }

  // Bilgi dialogunu goster
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
              Text('• Anketler profil bilgilerinize gore duzenlenmistir.'),
              SizedBox(height: 8),
              Text('• Yasadiginiz il, yasiniz ve okulunuz gibi bilgiler anketlerin gosteriminde etkilidir.'),
              SizedBox(height: 8),
              Text('• Profil bilgileriniz eksikse bazi anketleri goremeyebilirsiniz.'),
              SizedBox(height: 8),
              Text('• Secimlerinizi kaydetmek icin sag ustteki disket ikonuna tiklayin.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
              child: Text('Anladim'),
            ),
          ],
        );
      },
    );
  }
}
