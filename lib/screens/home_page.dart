import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Giriş yapan kullanıcının ID bilgisi (TC kimlik numarası)
  // SharedPreferences'dan yüklenir ve kullanıcı bilgisi kartında kullanılır
  String? userId;

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  // Kullanıcı kimlik bilgisini SharedPreferences'dan yükleyen metot
  // Giriş yapıldığında LoginPage tarafından kaydedilen 'user_id' değerini alır
  void getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text("Ana Sayfa"),
      ),
      // Yan menü çekmecesi - uygulama içi navigasyonu sağlar
      drawer: CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgi kartı - sadece kullanıcı giriş yapmışsa gösterilir
            // TC kimlik numarasının bir kısmını gizleyerek güvenli şekilde gösterir
            if (userId != null) createUserCard(),

            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),

            // Ana menü başlık bölümü - hızlı erişim seçeneklerini tanıtır
            createHeaderRow('Hızlı Erişim', Icons.dashboard),

            // Anket sayfasına giden navigasyon butonu
            // Kullanıcının mevcut anketlere erişmesini ve oy kullanmasını sağlar
            createMenuButton(
                icon: Icons.poll,
                title: 'Anketler',
                description: 'Anketlere eriş ve oy kullan',
                onTapFunction: () {
                  Navigator.pushNamed(context, '/survey');
                }),

            SizedBox(height: 10),

            // İstatistik sayfasına giden navigasyon butonu
            // Kullanıcının anket sonuçlarını ve istatistikleri görüntülemesini sağlar
            createMenuButton(
                icon: Icons.bar_chart,
                title: 'İstatistikler',
                description: 'Anket sonuçlarını incele',
                onTapFunction: () {
                  Navigator.pushNamed(context, '/statistics');
                }),
          ],
        ),
      ),
    );
  }

  // Kullanıcı bilgilerini gösteren kart widget'ı
  // Giriş yapan kullanıcının karşılama mesajı ve kısmi gizlenmiş TC kimlik numarasını içerir
  Widget createUserCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF5181BE).withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Kullanıcı avatarı - ikon olarak gösterilir
          CircleAvatar(
            backgroundColor: Color(0xFF5181BE),
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kullanıcı karşılama mesajı
              Text(
                'Hoşgeldiniz',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Kısmi gizlenmiş TC kimlik numarası 
              // Örnek: İlk 3 hane ve son 3 hane gösterilir, ortası yıldızlarla gizlenir
              Text(
                'TC: ${userId!.substring(0, 3)}*****${userId!.substring(8, 11)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Başlık satırını oluşturan yardımcı metot
  // Bölüm başlıklarını ikon ile birlikte gösterir
  Widget createHeaderRow(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF5181BE)),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Menü butonlarını oluşturan yardımcı metot
  // Farklı bölümlere giden butonlar için tutarlı bir görünüm ve davranış sağlar
  // Her buton bir ikon, başlık, açıklama içerir ve tıklandığında ilgili sayfaya yönlendirir
  Widget createMenuButton(
      {required IconData icon,
      required String title,
      required String description,
      required Function onTapFunction}) {
    return ElevatedButton(
      onPressed: () => onTapFunction(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        children: [
          // Menü öğesi ikonu - her öğe için farklı ve anlamlı ikonlar kullanılır
          Icon(icon, color: Color(0xFF5181BE), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menü başlığı
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Menü açıklaması - kullanıcıya öğenin amacını açıklar
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // İleri git ikonu - kullanıcıya butonun başka bir sayfaya yönlendireceğini gösterir
          Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}
