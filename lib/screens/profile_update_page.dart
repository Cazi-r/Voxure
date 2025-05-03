import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class ProfileUpdatePage extends StatefulWidget {
  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  // Firebase servisi
  final FirebaseService _firebaseService = FirebaseService();
  
  // Firestore referansı
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Kullanıcı bilgisi
  User? currentUser;
  String? userEmail;
  String? tcKimlik;
  
  // Isim ve soyisim icin deger tutucular
  TextEditingController _nameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();
  
  // Il secimi icin deger tutucu
  String? selectedCity;
  
  // Okul secimi icin deger tutucu
  String? selectedSchool;
  
  // Dogum tarihi secimi icin deger tutucu
  DateTime? selectedDate;
  
  // Sayfa yükleniyor mu kontrolü
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Son güncelleme tarihi
  DateTime? lastUpdateTime;
  
  // Turkiye'deki illerin listesi
  final List<String> cities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara', 'Antalya',
    'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik',
    'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
    'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir',
    'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul',
    'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kilis',
    'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa',
    'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye',
    'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop', 'Sivas', 'Şırnak',
    'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak'
  ];
  
  // Universiteler
  final List<String> schools = [
    'Okumuyorum',
    'Altınbaş Üniversitesi',
    'Bahçeşehir Üniversitesi',
    'Beykent Üniversitesi',
    'Boğaziçi Üniversitesi',
    'Galatasaray Üniversitesi',
    'Işık Üniversitesi',
    'İstanbul Kültür Üniversitesi',
    'İstanbul Medipol Üniversitesi',
    'İstanbul Sabahattin Zaim Üniversitesi',
    'İstanbul Teknik Üniversitesi',
    'İstanbul Ticaret Üniversitesi',
    'İstanbul Üniversitesi',
    'Koç Üniversitesi',
    'Maltepe Üniversitesi',
    'Marmara Üniversitesi',
    'Özyeğin Üniversitesi',
    'Sabancı Üniversitesi',
    'Yıldız Teknik Üniversitesi',
    'Diğer'
  ];
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }
  
  // Kullanıcı bilgilerini yükle
  void _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Mevcut kullanıcıyı al
      currentUser = _firebaseService.getCurrentUser();
      
      if (currentUser != null) {
        userEmail = currentUser!.email;
        
        // Email'den TC kimlik numarasını çıkar (ornek@example.com)
        if (userEmail != null) {
          tcKimlik = userEmail!.split('@')[0];
        }
        
        // Kullanıcı profil bilgilerini Firestore'dan al
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // Tarih bilgisini Timestamp'den DateTime'a çevir
          Timestamp? birthDateTimestamp = userData['birthDate'] as Timestamp?;
          if (birthDateTimestamp != null) {
            selectedDate = birthDateTimestamp.toDate();
          }
          
          // Son güncelleme tarihini al
          Timestamp? updatedAtTimestamp = userData['updatedAt'] as Timestamp?;
          if (updatedAtTimestamp != null) {
            lastUpdateTime = updatedAtTimestamp.toDate();
          }
          
          setState(() {
            // Mevcut verileri doldur
            _nameController.text = userData['name'] as String? ?? '';
            _surnameController.text = userData['surname'] as String? ?? '';
            selectedCity = userData['city'] as String?;
            selectedSchool = userData['school'] as String?;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showMessage("Hata", "Kullanıcı bilgisi bulunamadı.");
      }
    } catch (e) {
      developer.log("Kullanıcı bilgileri yüklenirken hata: $e", name: 'profile_update');
      setState(() {
        _isLoading = false;
      });
      _showMessage("Hata", "Kullanıcı bilgileri yüklenirken bir hata oluştu.");
    }
  }
  
  // Profil bilgilerini kaydet
  Future<void> _saveProfile() async {
    // Bilgilerin tam olduğunu kontrol et
    if (_nameController.text.trim().isEmpty) {
      _showMessage("Eksik Bilgi", "Lütfen adınızı girin.");
      return;
    }
    
    if (_surnameController.text.trim().isEmpty) {
      _showMessage("Eksik Bilgi", "Lütfen soyadınızı girin.");
      return;
    }
    
    if (selectedDate == null) {
      _showMessage("Eksik Bilgi", "Lütfen doğum tarihinizi seçin.");
      return;
    }
    
    if (selectedCity == null) {
      _showMessage("Eksik Bilgi", "Lütfen yaşadığınız ili seçin.");
      return;
    }
    
    if (selectedSchool == null) {
      _showMessage("Eksik Bilgi", "Lütfen okulunuzu seçin.");
      return;
    }
    
    // 6 ayda sadece bir kez güncelleme yapılabilmesi için kontrol
    if (lastUpdateTime != null) {
      final now = DateTime.now();
      
      // Son güncelleme tarihine 6 ay ekle
      final DateTime nextAllowedUpdate = DateTime(
        lastUpdateTime!.year + ((lastUpdateTime!.month + 6) > 12 ? 1 : 0),
        ((lastUpdateTime!.month + 6) % 12 == 0 ? 12 : (lastUpdateTime!.month + 6) % 12),
        lastUpdateTime!.day,
      );
      
      // Şu anki tarih, izin verilen bir sonraki güncellemeden önce mi kontrol et
      if (now.isBefore(nextAllowedUpdate)) {
        _showMessage(
          "Güncelleme Sınırlaması", 
          "Profil bilgilerinizi 6 ayda sadece bir kez güncelleyebilirsiniz. Lütfen ${nextAllowedUpdate.day}/${nextAllowedUpdate.month}/${nextAllowedUpdate.year} tarihinden sonra tekrar deneyin."
        );
        return;
      }
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (currentUser != null) {
        // Firestore'a bilgileri kaydet
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'tcKimlik': tcKimlik,
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'birthDate': selectedDate,
          'city': selectedCity,
          'school': selectedSchool,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          _isSaving = false;
        });
        
        _showMessage("Başarılı", "Profil bilgileriniz başarıyla güncellendi.", onDismissed: () {
          Navigator.pop(context);  // Ana sayfaya dön
        });
      } else {
        setState(() {
          _isSaving = false;
        });
        _showMessage("Hata", "Kullanıcı bilgisi bulunamadı.");
      }
    } catch (e) {
      developer.log("Profil bilgileri kaydedilirken hata: $e", name: 'profile_update');
      setState(() {
        _isSaving = false;
      });
      _showMessage("Hata", "Profil bilgileri kaydedilirken bir hata oluştu.");
    }
  }
  
  // Tarih seçme dialog'unu göster
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime minimumDate = DateTime(now.year - 100, 1, 1);
    final DateTime maximumDate = DateTime(now.year - 10, 12, 31);
    
    final DateTime initialDate = selectedDate ?? DateTime(now.year - 18, now.month, now.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minimumDate,
      lastDate: maximumDate,
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF5181BE),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text("Profil Bilgilerini Güncelle"),
        actions: [
          // Bilgi ikonu
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.black54),
            onPressed: () {
              // Bilgi popup'ını göster
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          _isLoading 
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TC Kimlik bilgisi
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Color(0xFF5181BE), size: 22),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TC Kimlik Numaranız",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                tcKimlik ?? "Yükleniyor...",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    
                    // Form başlığı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Profil Bilgileriniz",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5181BE),
                          ),
                        ),
                      ],
                    ),
                    if (lastUpdateTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          "Son güncelleme: ${lastUpdateTime!.day}/${lastUpdateTime!.month}/${lastUpdateTime!.year} ${lastUpdateTime!.hour}:${lastUpdateTime!.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                    
                    // Ad alanı
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: "Adınız",
                          labelStyle: TextStyle(fontSize: 15),
                          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF5181BE), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Soyad alanı
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _surnameController,
                        style: TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: "Soyadınız",
                          labelStyle: TextStyle(fontSize: 15),
                          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF5181BE), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Doğum Tarihi Seçimi
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: Color(0xFF5181BE), size: 20),
                        title: Text(
                          "Doğum Tarihi", 
                          style: TextStyle(fontSize: 15)
                        ),
                        subtitle: Text(
                          selectedDate != null 
                            ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                            : "Seçilmedi",
                          style: TextStyle(fontSize: 14)
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        dense: true,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // İl Seçimi
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                          hint: Row(
                            children: [
                              Icon(Icons.location_city, color: Color(0xFF5181BE), size: 20),
                              SizedBox(width: 12),
                              Text(
                                "Yaşadığınız İl",
                                style: TextStyle(fontSize: 15)
                              ),
                            ],
                          ),
                          value: selectedCity,
                          items: cities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(
                                city,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCity = newValue;
                            });
                          },
                          selectedItemBuilder: (BuildContext context) {
                            return cities.map<Widget>((String city) {
                              return Row(
                                children: [
                                  Icon(Icons.location_city, color: Color(0xFF5181BE), size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    city,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Okul Seçimi
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                          hint: Row(
                            children: [
                              Icon(Icons.school, color: Color(0xFF5181BE), size: 20),
                              SizedBox(width: 12),
                              Text(
                                "Okulunuz",
                                style: TextStyle(fontSize: 15)
                              ),
                            ],
                          ),
                          value: selectedSchool,
                          items: schools.map((String school) {
                            return DropdownMenuItem<String>(
                              value: school,
                              child: Text(
                                school,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSchool = newValue;
                            });
                          },
                          selectedItemBuilder: (BuildContext context) {
                            return schools.map<Widget>((String school) {
                              return Row(
                                children: [
                                  Icon(Icons.school, color: Color(0xFF5181BE), size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    school,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Bilgileri Kaydet butonu
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5181BE),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        minimumSize: Size(double.infinity, 48),
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Kaydediliyor...', 
                                style: TextStyle(fontSize: 16, color: Colors.white)
                              ),
                            ],
                          )
                        : Text(
                            'Bilgileri Kaydet', 
                            style: TextStyle(fontSize: 16, color: Colors.white)
                          ),
                    ),
                    SizedBox(height: 12),
                    
                    // İptal butonu
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        minimumSize: Size(double.infinity, 48),
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'İptal', 
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700)
                      ),
                    ),
                  ],
                ),
              ),
          
          // Loading overlay
          if (_isSaving)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
  
  // Mesaj gösterimi
  void _showMessage(String title, String message, {Function()? onDismissed}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (onDismissed != null) {
                  onDismissed();
                }
              },
              child: Text("Tamam"),
            ),
          ],
        );
      },
    );
  }
  
  // Bilgi dialogu
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF5181BE)),
              SizedBox(width: 10),
              Text("Bilgi"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• Girdiginiz bilgilere gore size ozel anketler getirilecektir.",),
              SizedBox(height: 8),
              Text('• Yasadiginiz il, yasiniz ve okulunuz gibi bilgiler anketlerin gosteriminde etkilidir.'),
              SizedBox(height: 8),
              Text('• Profil bilgileriniz eksikse bazi anketleri goremeyebilirsiniz.'),
              SizedBox(height: 8),
              Text('• Profil bilgilerinizi 6 ayda sadece bir kez guncelleyebilirsiniz.', style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Anladım", style: TextStyle(color: Color(0xFF5181BE))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
} 