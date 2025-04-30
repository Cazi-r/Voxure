import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Firebase servisi
  final FirebaseService _firebaseService = FirebaseService();
  // Firestore referansı
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Yukleniyor durumu
  bool _isLoading = false;
  // Kullanici bilgisi
  User? currentUser;
  // Profil bilgileri eksik mi?
  bool _isProfileIncomplete = true;
  // Kullanıcı ad soyadı
  String? userName;
  String? userSurname;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Kullanici bilgilerini yukle
  void _loadUser() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      currentUser = _firebaseService.getCurrentUser();
      
      if (currentUser != null) {
        // Profil bilgilerini Firestore'dan kontrol et
        await _checkProfileCompleteness();
      }
    } catch (e) {
      developer.log("Kullanici bilgisi yuklenirken hata: $e", name: 'home_page');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Profil bilgilerinin tam olup olmadığını kontrol et
  Future<void> _checkProfileCompleteness() async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Kullanıcı adı ve soyadını al
        userName = userData['name'] as String?;
        userSurname = userData['surname'] as String?;
        
        // Gerekli alanların varlığını kontrol et
        bool hasBirthDate = userData.containsKey('birthDate') && userData['birthDate'] != null;
        bool hasCity = userData.containsKey('city') && userData['city'] != null;
        bool hasSchool = userData.containsKey('school') && userData['school'] != null;
        
        // Tüm bilgiler varsa, profil tamamlanmıştır
        setState(() {
          _isProfileIncomplete = !(hasBirthDate && hasCity && hasSchool);
        });
        
        developer.log("Profil durumu: ${_isProfileIncomplete ? 'Eksik' : 'Tam'}", name: 'home_page');
      } else {
        // Kullanıcı dokümanı yoksa profil eksiktir
        setState(() {
          _isProfileIncomplete = true;
        });
      }
    } catch (e) {
      developer.log("Profil bilgileri kontrol edilirken hata: $e", name: 'home_page');
      // Hata durumunda varsayılan olarak profil eksik kabul edilir
      setState(() {
        _isProfileIncomplete = true;
      });
    }
  }

  // Cikis islemi
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firebaseService.signOut();
      
      // Login sayfasina yonlendir
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      developer.log("Cikis yaparken hata: $e", name: 'home_page');
      setState(() {
        _isLoading = false;
      });
      
      // Hata mesaji goster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Çıkış yaparken bir hata oluştu"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text("Ana Sayfa"),
      ),
      drawer: CustomDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanici bilgi karti
                  if (currentUser != null) _createUserCard(),
                  
                  // Kullanici bilgilerini isteme uyarisi - sadece profil eksikse göster
                  if (_isProfileIncomplete)
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Profil Bilgileriniz Eksik",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Doğum tarihi, yaşadığınız il ve okul bilgilerinizi girerek uygulamanın tüm özelliklerinden yararlanabilirsiniz.",
                            style: TextStyle(
                              color: Colors.orange.shade800,
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              // Profil sayfasına git ve dönüşte profil durumunu tekrar kontrol et
                              await Navigator.pushNamed(context, '/profile_update');
                              _loadUser(); // Profil sayfasından dönünce bilgileri yeniden yükle
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: Text("Profil Bilgilerini Güncelle"),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 16),

                  // Hizli erisim menusu
                  _createHeaderRow('Hızlı Erişim', Icons.dashboard),

                  SizedBox(height: 16),
                  
                  // Anketler butonu
                  _createMenuButton(
                    icon: Icons.poll,
                    title: 'Anketler',
                    description: 'Anketlere eriş ve oy kullan',
                    onTapFunction: () {
                      Navigator.pushNamed(context, '/survey');
                    },
                  ),

                  SizedBox(height: 16),

                  // Istatistikler butonu
                  _createMenuButton(
                    icon: Icons.bar_chart,
                    title: 'İstatistikler',
                    description: 'Anket sonuçlarını incele',
                    onTapFunction: () {
                      Navigator.pushNamed(context, '/statistics');
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Profil Bilgilerim butonu
                  _createMenuButton(
                    icon: Icons.person_outline,
                    title: 'Profil Bilgilerim',
                    description: 'Kişisel bilgilerinizi düzenleyin',
                    onTapFunction: () {
                      Navigator.pushNamed(context, '/profile_update');
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Kullanici bilgi karti
  Widget _createUserCard() {
    // Email adresinden TC kimlik numarasini cikar (ornek@example.com)
    String email = currentUser?.email ?? '';
    String tcKimlik = email.split('@')[0];
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF5181BE).withOpacity(0.2),
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
          // Kullanici avatari
          CircleAvatar(
            backgroundColor: Color(0xFF5181BE),
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hosgeldin mesaji
                Text(
                  'Hoşgeldiniz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // İsim ve soyisim gösterimi (eğer varsa)
                if (userName != null && userName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      '${userName} ${userSurname ?? ""}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                // TC kimlik gosterimi
                Text(
                  tcKimlik.length >= 11 
                    ? 'TC: ${tcKimlik.substring(0, 3)}*****${tcKimlik.substring(8, 11)}'
                    : 'TC: $tcKimlik',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Baslik satiri
  Widget _createHeaderRow(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
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

  // ListTile Widget'i
  Widget _createListTile({
    required IconData icon,
    required String title,
    required Function onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF5181BE)),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () => onTap(),
    );
  }
  
  // Menu butonu
  Widget _createMenuButton({
    required IconData icon,
    required String title,
    required String description,
    required Function onTapFunction
  }) {
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
          Icon(icon, color: Color(0xFF5181BE), size: 30),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ],
      ),
    );
  }
}
