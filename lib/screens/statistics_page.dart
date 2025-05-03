import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../services/blockchain_service.dart';

/// StatisticsPage: Anketlerin oy istatistiklerini gösteren sayfa.
///
/// Bu sayfa, blockchain üzerinde kaydedilmiş oy verilerini görselleştirir
/// ve her anket seçeneği için oy sayıları ve yüzdelerini gösterir.
class StatisticsPage extends StatefulWidget {
  @override
  State<StatisticsPage> createState() => StatisticsPageState();
}

class StatisticsPageState extends State<StatisticsPage> {
  // Blockchain servisi
  final BlockchainService _blockchainService = BlockchainService();
  
  // Veriler yükleniyor mu?
  bool isLoading = true;
  
  // Anket verileri listesi - Survey sayfasındaki anketlerle aynı format
  List<Map<String, dynamic>> surveys = [
    {
      'id': 'cumhurbaskanligi_secimi',
      'soru': 'Cumhurbaşkanlığı seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Kişisi', 'B Kişisi', 'C Kişisi'],
      'oylar': [0, 0, 0],
      'ikon': Icons.how_to_vote,
      'renk': Colors.green,
    },
    {
      'id': 'belediye_secimi',
      'soru': 'İstanbul belediye başkanlığı seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Adayı', 'B Adayı', 'C Adayı', 'D Adayı'],
      'oylar': [0, 0, 0, 0],
      'ikon': Icons.location_city,
      'renk': Colors.blue,
    },
    {
      'id': 'okul_temsilcisi',
      'soru': 'İstanbul Sabahattin Zaim Üniversitesi öğrenci temsilcisi seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Öğrenci', 'B Öğrenci', 'C Öğrenci'],
      'oylar': [0, 0, 0],
      'ikon': Icons.school,
      'renk': Colors.brown,
    },
    {
      'id': 'isletim_sistemi',
      'soru': 'Hangi işletim sistemini tercih ediyorsunuz?',
      'secenekler': ['Windows', 'Linux', 'MacOS', 'Pardus'],
      'oylar': [0, 0, 0, 0],
      'ikon': Icons.computer,
      'renk': Colors.orange,
    },
    {
      'id': 'sosyal_medya',
      'soru': 'Hangi sosyal medya platformunu daha sık kullanıyorsunuz?',
      'secenekler': ['Instagram', 'Twitter (X)', 'TikTok', 'Facebook'],
      'oylar': [0, 0, 0, 0],
      'ikon': Icons.public,
      'renk': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    loadDataFromBlockchain();
  }

  /// Blockchain'den oy verilerini yükler
  Future<void> loadDataFromBlockchain() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Blockchain servisinden tüm anketlerin verilerini al
      Map<String, Map<int, int>> allVotes = await _blockchainService.getAllSurveyVotes();
      
      // Tüm anketleri güncelle
      setState(() {
        for (int i = 0; i < surveys.length; i++) {
          String surveyId = surveys[i]['id'];
          
          // Bu anket için oy verileri var mı?
          if (allVotes.containsKey(surveyId)) {
            Map<int, int> voteData = allVotes[surveyId]!;
            
            // Oy sayılarını sıfırla
            List<int> newVotes = List<int>.filled(surveys[i]['secenekler'].length, 0);
            
            // Blockchain'den gelen oy verilerini işle
            voteData.forEach((optionIndex, count) {
              if (optionIndex >= 0 && optionIndex < newVotes.length) {
                newVotes[optionIndex] = count;
              }
            });
            
            // Anket verilerini güncelle
            surveys[i]['oylar'] = newVotes;
          }
        }
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text('İstatistikler'),
        actions: [
          // Yenile butonu
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Verileri Yenile',
            onPressed: () {
              loadDataFromBlockchain();
            },
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: isLoading 
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: surveys.length,
              itemBuilder: (context, index) {
                return createStatisticsCard(index);
              },
            ),
    );
  }

  /// İstatistik kartını oluşturan widget metodu
  Widget createStatisticsCard(int surveyIndex) {
    Map<String, dynamic> survey = surveys[surveyIndex];

    // Tüm seçeneklerin aldığı toplam oy sayısını hesapla
    int totalVotes = 0;
    List<int> votes = List<int>.from(survey['oylar']);
    for (int vote in votes) {
      totalVotes += vote;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anket sorusu ve ikonu
            Row(
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

            SizedBox(height: 12),

            // Toplam oy sayısı
            Text(
              'Toplam: $totalVotes oy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            // Tüm seçeneklerin sonuçları
            Column(
              children: createOptionResults(survey, totalVotes),
            ),
          ],
        ),
      ),
    );
  }

  /// Seçenek sonuçlarını oluşturan metot
  List<Widget> createOptionResults(
      Map<String, dynamic> survey, int totalVotes) {
    List<Widget> results = [];
    
    // Oylar listesinin seçeneklerle aynı uzunlukta olduğunu kontrol et
    List<dynamic> secenekler = survey['secenekler'];
    List<dynamic> oylar = survey['oylar'];
    
    // Dizilerin uzunluklarını uyumlu hale getir
    if (oylar.length != secenekler.length) {
      oylar = List.filled(secenekler.length, 0);
    }

    for (int i = 0; i < secenekler.length; i++) {
      String option = secenekler[i];
      int voteCount = i < oylar.length ? oylar[i] : 0;

      // Seçeneğin aldığı oyun yüzdesini hesapla
      double percentage = 0;
      if (totalVotes > 0) {
        percentage = (voteCount / totalVotes) * 100;
      }

      // Seçenek sonucu için widget
      Widget resultWidget = Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seçenek adı, oy sayısı ve yüzde bilgisi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option),
                Text('$voteCount (${percentage.toStringAsFixed(0)}%)'),
              ],
            ),

            SizedBox(height: 4),

            // Oy yüzdesini gösteren çubuk
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(survey['renk']),
              minHeight: 10,
            ),
          ],
        ),
      );

      results.add(resultWidget);
    }

    return results;
  }
}
