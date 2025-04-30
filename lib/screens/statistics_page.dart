import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsPage extends StatefulWidget {
  @override
  State<StatisticsPage> createState() => StatisticsPageState();
}

class StatisticsPageState extends State<StatisticsPage> {
  // Anket verileri listesi - Survey sayfasındaki anketlerle aynı format ve içeriğe sahip
  // Ancak burada sadece gösterim amaçlı olduğu için 'oyVerildi' ve 'secilenSecenek' alanları yok
  List<Map<String, dynamic>> surveys = [
    {
      'soru': 'Cumhurbaşkanlığı seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Kişisi', 'B Kişisi', 'C Kişisi'],
      'oylar': [0, 0, 0],
      'ikon': Icons.how_to_vote,
      'renk': Colors.green,
    },
    {
      'soru': 'Hangi işletim sistemini tercih ediyorsunuz?',
      'secenekler': ['Windows', 'Linux', 'MacOS', 'Pardus'],
      'oylar': [0, 0, 0, 0],
      'ikon': Icons.computer,
      'renk': Colors.orange,
    },
    {
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
    loadData();
  }

  // SharedPreferences'dan kaydedilmiş oy verilerini yükler
  // Bu metot sayfa açıldığında çağrılır ve tüm anketlerin güncel oy durumlarını gösterir
  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < surveys.length; i++) {
      // Oy verilerini içeren string listesini ('votes_0', 'votes_1', 'votes_2' anahtarlarıyla) yükle
      List<String>? oyListesi = prefs.getStringList('votes_$i');

      // Veri varsa ve boş değilse işleme devam et
      if (oyListesi != null && oyListesi.isNotEmpty) {
        try {
          // String listesini int listesine dönüştür (SharedPreferences int listesi saklamadığı için)
          List<int> oylar = [];
          for (String oy in oyListesi) {
            oylar.add(int.parse(oy));
          }

          // Seçenek sayısı ve oy sayısı uyuşması için kontrol
          if (oylar.length == surveys[i]['secenekler'].length) {
            // Anket verisini güncel oy sayılarıyla güncelle
            setState(() {
              surveys[i]['oylar'] = oylar;
            });
          } else {
            // Sayılar uyuşmuyorsa, seçenek sayısına göre yeni bir oy dizisi oluştur
            setState(() {
              List<int> yeniOylar = List.filled(surveys[i]['secenekler'].length, 0);
              // Mevcut oyları yeni diziye kopyala (sınırları aşmayacak şekilde)
              for (int j = 0; j < oylar.length && j < yeniOylar.length; j++) {
                yeniOylar[j] = oylar[j];
              }
              surveys[i]['oylar'] = yeniOylar;
            });
          }
        } catch (e) {
          print("Oy verilerini yüklerken hata: $e");
          // Hata durumunda varsayılan sıfır oyları kullan
          setState(() {
            surveys[i]['oylar'] = List.filled(surveys[i]['secenekler'].length, 0);
          });
        }
      } else {
        // Veri yoksa, seçenek sayısına göre sıfır oylar oluştur
        setState(() {
          surveys[i]['oylar'] = List.filled(surveys[i]['secenekler'].length, 0);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text('İstatistikler'),
      ),
      drawer: CustomDrawer(),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: surveys.length,
        itemBuilder: (context, index) {
          return createStatisticsCard(index);
        },
      ),
    );
  }

  // İstatistik kartını oluşturan widget metodu
  // Her anket için soru, toplam oy sayısı ve seçeneklerin durumunu gösteren kart oluşturur
  Widget createStatisticsCard(int surveyIndex) {
    Map<String, dynamic> survey = surveys[surveyIndex];

    // Tüm seçeneklerin aldığı toplam oy sayısını hesapla
    // Bu değer hem gösterim için kullanılır hem de yüzde hesaplarında payda olarak kullanılır
    int totalVotes = 0;
    List<int> votes = survey['oylar'];
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
            // Anket sorusu ve ikonu - kart başlığı
            // Anketin içeriğini temsil eden ikon ve soru metni
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

            // Ankete verilen toplam oy sayısı bilgisi
            // Hiç oy verilmediyse 0 gösterilir
            Text(
              'Toplam: $totalVotes oy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            // Tüm seçeneklerin sonuçlarını içeren widget listesi
            // Her seçenek için oy sayısı, yüzdesi ve ilerlemesi gösterilir
            Column(
              children: createOptionResults(survey, totalVotes),
            ),
          ],
        ),
      ),
    );
  }

  // Her seçenek için ayrı sonuç satırı widget'ları oluşturan metot
  // Seçenek adı, oy sayısı, yüzdesi ve grafiksel gösterimini içerir
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

      // Seçeneğin aldığı oyun toplam oylara oranını yüzde olarak hesapla
      // Toplam oy yoksa yüzde sıfır olacaktır
      double percentage = 0;
      if (totalVotes > 0) {
        percentage = (voteCount / totalVotes) * 100;
      }

      // Her seçenek için oy bilgisi ve ilerleme çubuğu içeren widget
      Widget resultWidget = Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seçenek adı, oy sayısı ve yüzde bilgisi
            // Örnek: "Elma: 5 (50%)"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option),
                Text('$voteCount (${percentage.toStringAsFixed(0)}%)'),
              ],
            ),

            SizedBox(height: 4),

            // Oyun yüzdesini görsel olarak temsil eden ilerleme çubuğu
            // Her seçenek için anketin renginde bir çubuk gösterilir
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
