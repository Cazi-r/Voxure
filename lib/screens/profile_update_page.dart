import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
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
    _loadUserInfo();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }
  
  void _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      currentUser = _firebaseService.getCurrentUser();
      
      if (currentUser != null) {
        userEmail = currentUser!.email;
        
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          Timestamp? birthDateTimestamp = userData['birthDate'] as Timestamp?;
          if (birthDateTimestamp != null) {
            selectedDate = birthDateTimestamp.toDate();
            _calculateAge(); // Yaşı hesapla
          }
          
          Timestamp? updatedAtTimestamp = userData['updatedAt'] as Timestamp?;
          if (updatedAtTimestamp != null) {
            lastUpdateTime = updatedAtTimestamp.toDate();
          }
          
          setState(() {
            _nameController.text = userData['name'] as String? ?? '';
            _surnameController.text = userData['surname'] as String? ?? '';
            selectedCity = userData['city'] as String?;
            selectedSchool = userData['school'] as String?;
            
            // Yaş kontrolü
            if (_age != null && _age! < 18 && selectedSchool != 'Okumuyorum') {
              selectedSchool = 'Okumuyorum';
            }
            
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
      setState(() {
        _isLoading = false;
      });
      _showMessage("Hata", "Kullanıcı bilgileri yüklenirken bir hata oluştu.");
    }
  }
  
  Future<void> _saveProfile() async {
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
    
    if (lastUpdateTime != null) {
      final now = DateTime.now();
      
      final DateTime nextAllowedUpdate = DateTime(
        lastUpdateTime!.year + ((lastUpdateTime!.month + 6) > 12 ? 1 : 0),
        ((lastUpdateTime!.month + 6) % 12 == 0 ? 12 : (lastUpdateTime!.month + 6) % 12),
        lastUpdateTime!.day,
      );
      
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
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'email': userEmail,
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
          Navigator.pop(context);
        });
      } else {
        setState(() {
          _isSaving = false;
        });
        _showMessage("Hata", "Kullanıcı bilgisi bulunamadı.");
      }
    } catch (e) {
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
        _calculateAge(); // Yaşı hesapla
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Profil Guncelle',
      showSaveButton: true,
      onSavePressed: _saveProfile,
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