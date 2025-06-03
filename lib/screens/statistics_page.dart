import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/custom_app_bar.dart';
import '../services/supabase_service.dart';
import '../widgets/base_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/*
 * İstatistikler Sayfası (StatisticsPage)
 * 
 * Bu sayfa, anketlerin oy istatistiklerini görselleştirmek için aşağıdaki özellikleri sunar:
 * - Anket sorularının listelenmesi
 * - Her seçenek için oy sayıları ve yüzdeleri
 * - Görsel grafikler ve ilerleme çubukları
 * - Yenileme özelliği
 * - Boş durum gösterimi
 */

/// StatisticsPage: Anketlerin oy istatistiklerini gösteren sayfa.
///
/// Bu sayfa, Firebase'de kaydedilmiş oy verilerini görselleştirir
/// ve her anket seçeneği için oy sayıları ve yüzdelerini gösterir.
class StatisticsPage extends StatefulWidget {
  @override
  State<StatisticsPage> createState() => StatisticsPageState();
}

class StatisticsPageState extends State<StatisticsPage> {
  // Supabase veritabanı servisi
  final SupabaseService _supabaseService = SupabaseService(Supabase.instance.client);
  
  // Sayfa durumu
  bool isLoading = true;
  
  // Anket verileri
  List<Map<String, dynamic>> surveys = [];

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  /// Anketleri yükler ve sonra oyları alır
  Future<void> _loadSurveys() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Önce Supabase'den tüm anketleri getir
      List<Map<String, dynamic>> loadedSurveys = await _supabaseService.getSurveys();
      
      setState(() {
        surveys = loadedSurveys;
      });
      
      // Anketler yüklendikten sonra her anket için oy verilerini al
      await loadVoteData();
    } catch (e) {
      print('Anketleri yükleken hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Her anket için oy verilerini yükler ve işler
  Future<void> loadVoteData() async {
    try {
      // Her anket için ayrı ayrı oy verilerini al
      for (int i = 0; i < surveys.length; i++) {
        String surveyId = surveys[i]['id'];
        
        // Bu anket için oy verilerini Supabase'den getir
        Map<int, int> voteData = await _supabaseService.getSurveyVotes(surveyId);
        
        // Her seçenek için oy sayılarını sıfırla
        List<int> newVotes = List<int>.filled(surveys[i]['secenekler'].length, 0);
        
        // Gelen oy verilerini işle ve seçeneklere dağıt
        voteData.forEach((optionIndex, count) {
          if (optionIndex >= 0 && optionIndex < newVotes.length) {
            newVotes[optionIndex] = count;
          }
        });
        
        // Anket verilerini güncelle
        if (mounted) {
          setState(() {
            surveys[i]['oylar'] = newVotes;
          });
        }
      }
    } catch (e) {
      print('Oy verileri yüklenirken hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Istatistikler',
      showRefreshButton: true,
      onRefreshPressed: _loadSurveys,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        isLoading 
            ? Center(child: CircularProgressIndicator())
            : surveys.isEmpty
                ? _buildEmptySurveyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: surveys.length,
                    itemBuilder: (context, index) {
                      return createStatisticsCard(index);
                    },
                  ),
      ],
    );
  }

  /// Anket olmadığında gösterilecek boş durum widget'ı
  Widget _buildEmptySurveyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Henüz Anket Bulunmuyor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Anketlere katılmak için önce anket ekleyin',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Yenile'),
            onPressed: () => _loadSurveys(),
          ),
        ],
      ),
    );
  }

  /// İstatistik kartını oluşturan widget metodu
  /// Bu metot her anket için bir kart oluşturur ve içinde:
  /// - Anket sorusunu
  /// - Toplam oy sayısını
  /// - Her seçenek için oy yüzdelerini ve çubuk grafiğini gösterir
  Widget createStatisticsCard(int surveyIndex) {
    Map<String, dynamic> survey = surveys[surveyIndex];
    Color surveyColor = _getColorFromValue(survey['renk']) ?? Colors.blue;

    // Tüm seçeneklerin aldığı toplam oy sayısını hesapla
    int totalVotes = 0;
    List<int> votes = List<int>.from(survey['oylar'] ?? []);
    for (int vote in votes) {
      totalVotes += vote;
    }

    print('Anket ${survey['id']} icin gelen oylar: ${survey['oylar']}');

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
                Icon(_getIconFromValue(survey['ikon']), size: 28, color: surveyColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    survey['soru'] ?? 'Basliksiz Anket',
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
  /// Her seçenek için:
  /// - Seçenek adını
  /// - Aldığı oy sayısını ve yüzdesini
  /// - Yüzdeyi gösteren bir ilerleme çubuğunu oluşturur
  List<Widget> createOptionResults(
      Map<String, dynamic> survey, int totalVotes) {
    List<Widget> results = [];
    Color surveyColor = _getColorFromValue(survey['renk']) ?? Colors.blue;
    
    // Oylar listesinin seçeneklerle aynı uzunlukta olduğunu kontrol et
    List<dynamic> secenekler = survey['secenekler'] ?? [];
    List<dynamic> oylar = survey['oylar'] ?? [];
    
    // Dizilerin uzunluklarını uyumlu hale getir
    if (oylar.length != secenekler.length) {
      oylar = List.filled(secenekler.length, 0);
    }

    for (int i = 0; i < secenekler.length; i++) {
      String option = secenekler[i].toString();
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
              valueColor: AlwaysStoppedAnimation<Color>(surveyColor),
              minHeight: 10,
            ),
          ],
        ),
      );

      results.add(resultWidget);
    }

    return results;
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

  void _showInfoDialog(BuildContext context) {
    // Implement the logic to show the info dialog
  }
}
