import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/base_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';

class ProfileUpdatePage extends StatefulWidget {
  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  
  User? currentUser;
  String? userEmail;
  
  TextEditingController _nameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();
  
  String? selectedCity;
  String? selectedSchool;
  DateTime? selectedDate;
  int? _age;
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  DateTime? lastUpdateTime;
  
  // Türkiye'deki illerin listesi
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
  
  // Yaşa göre uygun okul listesini döndüren fonksiyon
  List<String> _getAvailableSchools() {
    if (_age != null && _age! < 18) {
      return ['Okumuyorum'];
    }
    return schools;
  }
  
  // Kullanıcının yaşını hesaplama
  void _calculateAge() {
    if (selectedDate != null) {
      final DateTime now = DateTime.now();
      int age = now.year - selectedDate!.year;
      if (now.month < selectedDate!.month || 
          (now.month == selectedDate!.month && now.day < selectedDate!.day)) {
        age--;
      }
      setState(() {
        _age = age;
        // Eğer 18 yaşından küçükse ve üniversite seçiliyse, otomatik olarak "Okumuyorum" yap
        if (_age! < 18 && selectedSchool != 'Okumuyorum') {
          selectedSchool = 'Okumuyorum';
        }
      });
    } else {
      setState(() {
        _age = null;
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    _initializeLocalStorage();
    _loadUserInfo();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeLocalStorage() async {
    await _localStorage.init();
  }
  
  Future<void> _loadUserInfo() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Kullanici kontrolu
      final user = _firebaseService.getCurrentUser();
      if (user == null) {
        throw Exception("Kullanici oturumu bulunamadi");
      }

      userEmail = user.email;
      
      // Yerel depolamadan veri yukleme
      Map<String, dynamic>? localUserData;
      try {
        localUserData = await _localStorage.getUserFromSQLite(user.uid);
        if (localUserData != null) {
          _updateUIFromUserData(localUserData);
        }
      } catch (e) {
        print('Yerel depolama okuma hatasi: $e');
      }
      
      // Firebase'den veri yukleme
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // Yerel depolamaya kaydet
          await _localStorage.saveUserToSQLite({
            'id': user.uid,
            ...userData,
          });
          await _localStorage.saveUserToPrefs(userData);
          
          if (mounted) {
            _updateUIFromUserData(userData);
          }
        } else {
          print('Kullanici verisi bulunamadi');
        }
      } catch (e) {
        print('Firebase veri okuma hatasi: $e');
        // Eger yerel veri varsa onunla devam et, yoksa hatayi goster
        if (localUserData == null) {
          throw e;
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage("Hata", "Kullanici bilgileri yuklenirken bir hata olustu: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _updateUIFromUserData(Map<String, dynamic> userData) {
    if (!mounted) return;

    try {
      // Dogum tarihi kontrolu
      if (userData['birthDate'] != null) {
        if (userData['birthDate'] is Timestamp) {
          selectedDate = (userData['birthDate'] as Timestamp).toDate();
        } else if (userData['birthDate'] is DateTime) {
          selectedDate = userData['birthDate'] as DateTime;
        }
        _calculateAge();
      }
      
      // Son guncelleme zamani kontrolu
      if (userData['updatedAt'] != null) {
        if (userData['updatedAt'] is Timestamp) {
          lastUpdateTime = (userData['updatedAt'] as Timestamp).toDate();
        } else if (userData['updatedAt'] is DateTime) {
          lastUpdateTime = userData['updatedAt'] as DateTime;
        }
      }

      setState(() {
        _nameController.text = userData['name']?.toString() ?? '';
        _surnameController.text = userData['surname']?.toString() ?? '';
        selectedCity = userData['city']?.toString();
        selectedSchool = userData['school']?.toString();
        
        // 18 yas kontrolu
        if (_age != null && _age! < 18 && selectedSchool != 'Okumuyorum') {
          selectedSchool = 'Okumuyorum';
        }
      });
    } catch (e) {
      print('UI guncelleme hatasi: $e');
    }
  }
  
  Future<void> _saveProfile() async {
    try {
      // Form validasyonu
      String name = _nameController.text.trim();
      String surname = _surnameController.text.trim();
      
      if (name.isEmpty) {
        _showMessage("Eksik Bilgi", "Lutfen adinizi girin.");
        return;
      }
      
      if (surname.isEmpty) {
        _showMessage("Eksik Bilgi", "Lutfen soyadinizi girin.");
        return;
      }
      
      if (selectedDate == null) {
        _showMessage("Eksik Bilgi", "Lutfen dogum tarihinizi secin.");
        return;
      }
      
      if (selectedCity == null || selectedCity!.isEmpty) {
        _showMessage("Eksik Bilgi", "Lutfen yasadiginiz ili secin.");
        return;
      }
      
      if (selectedSchool == null || selectedSchool!.isEmpty) {
        _showMessage("Eksik Bilgi", "Lutfen okulunuzu secin.");
        return;
      }

      // 6 aylik guncelleme kontrolu
      if (lastUpdateTime != null) {
        final now = DateTime.now();
        final DateTime nextAllowedUpdate = DateTime(
          lastUpdateTime!.year + ((lastUpdateTime!.month + 6) > 12 ? 1 : 0),
          ((lastUpdateTime!.month + 6) % 12 == 0 ? 12 : (lastUpdateTime!.month + 6) % 12),
          lastUpdateTime!.day,
        );
        
        if (now.isBefore(nextAllowedUpdate)) {
          _showMessage(
            "Guncelleme Sinirlamasi", 
            "Profil bilgilerinizi 6 ayda sadece bir kez guncelleyebilirsiniz. Lutfen ${nextAllowedUpdate.day}/${nextAllowedUpdate.month}/${nextAllowedUpdate.year} tarihinden sonra tekrar deneyin."
          );
          return;
        }
      }

      // Kullanici kontrolu
      final user = _firebaseService.getCurrentUser();
      if (user == null) {
        _showMessage("Hata", "Kullanici bilgisi bulunamadi.");
        return;
      }

      setState(() {
        _isSaving = true;
      });

      // Verileri hazirla
      Map<String, dynamic> userData = {
        'email': user.email,
        'name': name,
        'surname': surname,
        'birthDate': selectedDate,
        'city': selectedCity,
        'school': selectedSchool,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Firebase'e kaydet
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true)
      );
      
      // Yerel depolamaya kaydet
      await _localStorage.saveUserToSQLite({
        'id': user.uid,
        ...userData,
      });
      await _localStorage.saveUserToPrefs(userData);

      // Guncel verileri al
      final updatedDoc = await _firestore.collection('users').doc(user.uid).get();
      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        _updateUIFromUserData(updatedData);
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        "Basarili", 
        "Profil bilgileriniz basariyla guncellendi.",
        onDismissed: () {
          Navigator.pop(context);
        }
      );

    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      print('Profil guncelleme hatasi: $e');
      _showMessage(
        "Hata", 
        "Profil bilgileriniz guncellenirken bir hata olustu. Lutfen tekrar deneyin."
      );
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
        _calculateAge(); // Yaşı hesapla
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Profil Guncelle',
      showSaveButton: false,
      content: Stack(
        children: [
          _isLoading 
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // E-posta bilgisi
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "E-posta Adresiniz",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            userEmail ?? "Yükleniyor...",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
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
                        subtitle: Row(
                          children: [
                            Text(
                              selectedDate != null 
                                ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                : "Seçilmedi",
                              style: TextStyle(fontSize: 14)
                            ),
                            if (_age != null)
                              Text(
                                " (${_age} yaş)", 
                                style: TextStyle(
                                  fontSize: 14, 
                                  color: _age! < 18 ? Colors.red : Colors.green
                                )
                              ),
                          ],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_age != null && _age! < 18)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                              child: Text(
                                "18 yaşından küçük olduğunuz için okul seçimi yapılamaz.",
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          DropdownButtonHideUnderline(
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
                              items: _getAvailableSchools().map((String school) {
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
                              onChanged: (_age != null && _age! < 18) ? null : (String? newValue) {
                                setState(() {
                                  selectedSchool = newValue;
                                });
                              },
                              selectedItemBuilder: (BuildContext context) {
                                return _getAvailableSchools().map<Widget>((String school) {
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
                        ],
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
              Text("• Girdiğiniz bilgilere göre size özel anketler getirilecektir.",),
              SizedBox(height: 8),
              Text('• Yaşadığınız il, yaşınız ve okulunuz gibi bilgiler anketlerin gösteriminde etkilidir.'),
              SizedBox(height: 8),
              Text('• Profil bilgileriniz eksikse bazı anketleri göremeyebilirsiniz.'),
              SizedBox(height: 8),
              Text('• Profil bilgilerinizi 6 ayda sadece bir kez güncelleyebilirsiniz.', style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
              Text('• 18 yaşından küçükseniz, okul seçimi otomatik olarak "Okumuyorum" olarak ayarlanacaktır.', style: TextStyle(color: Colors.red)),
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