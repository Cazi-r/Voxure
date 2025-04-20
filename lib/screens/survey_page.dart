import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyPage extends StatefulWidget {
  @override
  State<SurveyPage> createState() => SurveyPageState();
}

class SurveyPageState extends State<SurveyPage> {
  // Giriş yapan kullanıcının ID'si
  String? userId;

  // Anket verileri listesi - Her anket bir Map olarak tanımlanmıştır
  // Her Map içerisinde soru metni, seçenekler, oy sayıları, kullanıcı tercihi, görsel öğeler bulunur
  List<Map<String, dynamic>> surveys = [
    {
      'soru': 'Cumhurbaşkanlığı seçiminde kimi destekliyorsunuz?',
      'secenekler': ['A Kişisi', 'B Kişisi', 'C Kişisi'],
      'oylar': [0, 0, 0],
      'oyVerildi': false,
      'secilenSecenek': null,
      'ikon': Icons.how_to_vote,
      'renk': Colors.green,
    },
    {
      'soru': 'Hangi işletim sistemini tercih ediyorsunuz?',
      'secenekler': ['Windows', 'Linux', 'MacOS', 'Pardus'],
      'oylar': [0, 0, 0, 0],
      'oyVerildi': false,
      'secilenSecenek': null,
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
    // Önce kullanıcı ID'sini al, sonra verileri yükle
    _loadUserId().then((_) {
      loadData();
    });
  }

  // Giriş yapan kullanıcının ID'sini SharedPreferences'dan yükler
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  // SharedPreferences'dan kayıtlı anket verilerini (oylar ve kullanıcı tercihleri) yükler
  // İlk çalıştırmada veya veri yoksa varsayılan değerler kullanılır
  void loadData() async {
    if (userId == null) return; // Kullanıcı ID'si yoksa yükleme yapma

    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      for (int i = 0; i < surveys.length; i++) {
        // Önceden kaydedilmiş oy sayılarını yükle
        // 'votes_0', 'votes_1', 'votes_2' şeklinde saklanan string listelerini alır
        final oyListesi = prefs.getStringList('votes_$i');
        if (oyListesi != null) {
          List<int> oylar = [];
          for (String oy in oyListesi) {
            oylar.add(int.parse(oy));
          }
          surveys[i]['oylar'] = oylar;
        }

        // Kullanıcının daha önce seçtiği seçeneği yükle
        // 'selectedOption_USER-ID_0', 'selectedOption_USER-ID_1', 'selectedOption_USER-ID_2' şeklinde saklanır
        final secilenIndex = prefs.getInt('selectedOption_${userId}_$i');
        if (secilenIndex != null) {
          surveys[i]['secilenSecenek'] = secilenIndex;
          surveys[i]['oyVerildi'] = true;
        }
      }
    });
  }

  // Kullanıcı bir seçeneği seçtiğinde çağrılan metot
  // Seçilen seçeneğin oy sayısını artırır ve kullanıcı tercihini kaydeder
  void vote(int surveyIndex, int optionIndex) async {
    if (userId == null) return; // Kullanıcı giriş yapmamışsa işlem yapma

    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Kullanıcının bu ankete daha önce oy verip vermediğini kontrol et
    final mevcutSecim = prefs.getInt('selectedOption_${userId}_$surveyIndex');
    
    // Eğer kullanıcı daha önce oy vermişse, oyunu değiştirmesine izin verme
    if (mevcutSecim != null) {
      // Kullanıcı zaten oy vermiş, sessizce işlemi durdur
      return;
    }

    setState(() {
      // Seçilen seçeneğin oy sayısını bir artır
      surveys[surveyIndex]['oylar'][optionIndex]++;
      // Bu anket için kullanıcının oy verdiğini işaretle ve seçimini kaydet
      surveys[surveyIndex]['oyVerildi'] = true;
      surveys[surveyIndex]['secilenSecenek'] = optionIndex;
    });

    // Güncellenmiş oy sayılarını SharedPreferences'a kaydet
    // Int listesi direkt kaydedilemediği için string listesine dönüştürülür
    List<String> oyListesi = [];
    for (int oy in surveys[surveyIndex]['oylar']) {
      oyListesi.add(oy.toString());
    }
    prefs.setStringList('votes_$surveyIndex', oyListesi);

    // Kullanıcının seçtiği seçeneği kullanıcı ID'sine göre kaydet
    // Bu, her kullanıcının sadece bir kez oy vermesini sağlar
    prefs.setInt('selectedOption_${userId}_$surveyIndex', optionIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text('Anketler'),
      ),
      drawer: CustomDrawer(),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: surveys.length,
        itemBuilder: (context, index) {
          return createSurveyCard(index);
        },
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

    return ListTile(
      // Kullanıcı daha önce oy verdiyse tıklama devre dışı bırakılır
      onTap: hasVoted
          ? null
          : () {
              vote(surveyIndex, optionIndex);
            },
      leading: Icon(
        hasVoted
            ? (isSelected ? Icons.check_circle : Icons.circle_outlined)
            : Icons.radio_button_unchecked,
        color: hasVoted && isSelected ? survey['renk'] : Colors.grey,
      ),
      title: Text(
        option,
        style: TextStyle(
          color: hasVoted && !isSelected ? Colors.grey : Colors.black,
        ),
      ),
      trailing: hasVoted
          ? Text('${survey['oylar'][optionIndex]} oy')
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
