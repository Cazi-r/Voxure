import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Form alanlari icin controller'lar
  final tcController = TextEditingController();
  final sifreController = TextEditingController();
  final sifreTekrarController = TextEditingController();
  
  // Il secimi icin deger tutucu
  String? selectedCity;
  
  // Okul secimi icin deger tutucu
  String? selectedSchool;
  
  // Dogum tarihi secimi icin deger tutucu
  DateTime? selectedDate;
  
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
  
  // Istanbul'daki universiteler
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
    'Yıldız Teknik Üniversitesi'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5181BE),
        title: Text("Kayıt Sayfası"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
      ),
      // Klavye açıldığında sayfanın tekrar boyutlandırılmasını sağlar
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        // Klavye açıldığında ilave alt padding ekleyerek içeriğin yukarı kaymasını sağlar
        padding: EdgeInsets.only(
          left: 16.0, 
          right: 16.0, 
          top: 16.0, 
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0
        ),
        // Otomatik kaydırma özelliğini etkinleştir
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Baslik
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'images/icon.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, size: 100, color: Color(0xFF5181BE));
                    },
                  ),
                  SizedBox(height: 12),
                  Text(
                    'VOXURE - Kayıt Formu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
            
            // TC Kimlik No
            TextField(
              controller: tcController,
              decoration: InputDecoration(
                labelText: "TC Kimlik No",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
              ),
              keyboardType: TextInputType.number,
              maxLength: 11,
              textInputAction: TextInputAction.next,
            ),
                  
            SizedBox(height: 10),
            
            // Dogum Tarihi Secici
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Doğum Tarihi",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  selectedDate == null 
                      ? "Doğum Tarihi Seçiniz" 
                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Il Secimi
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Yaşadığınız İl",
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              value: selectedCity,
              hint: Text("İl Seçiniz"),
              items: cities.map((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCity = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            
            // Okul Secimi (Opsiyonel)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Okulunuz",
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              value: selectedSchool,
              hint: Text("Okul Seçiniz"),
              items: schools.map((String school) {
                return DropdownMenuItem<String>(
                  value: school,
                  child: Text(school),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSchool = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            
            // Sifre
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),
            
            // Sifre Tekrar
            TextField(
              controller: sifreTekrarController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre Tekrar",
                prefixIcon: Icon(Icons.lock_reset),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 30),
            
            // Kayit Ol Butonu
            ElevatedButton(
              onPressed: registerUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 240, 76, 64),
                padding: EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('KAYIT OL', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  // Dogum tarihi secimi icin tarih secici dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
  
  // TC kimlik numarası geçerlilik kontrolü
  bool isIdValid(String? tc) {
    if (tc == null || tc.isEmpty) return false;  // Boş değer kontrolü
    if (tc.length != 11) return false;           // 11 hane kontrolü
    if (tc[0] == '0') return false;              // İlk rakam 0 olmamalı
    return true;
  }
  
  // Kullanıcı kaydını gerçekleştiren metot
  void registerUser() {
    // TC Kimlik kontrolü
    if (!isIdValid(tcController.text)) {
      showMessage("Hata", "Geçerli bir TC kimlik numarası giriniz.");
      return;
    }
    
    // Şifre kontrolü
    if (sifreController.text.isEmpty) {
      showMessage("Hata", "Şifre alanı boş bırakılamaz.");
      return;
    }
    
    // Şifre eşleşme kontrolü
    if (sifreController.text != sifreTekrarController.text) {
      showMessage("Hata", "Şifreler eşleşmiyor.");
      return;
    }
    
    // Doğum tarihi kontrolü
    if (selectedDate == null) {
      showMessage("Hata", "Doğum tarihi seçilmelidir.");
      return;
    }
    
    // İl seçimi kontrolü
    if (selectedCity == null) {
      showMessage("Hata", "Yaşadığınız ili seçmelisiniz.");
      return;
    }
    
    // Okul seçimi kontrolü
    if (selectedSchool == null) {
      showMessage("Hata", "Okul bilgisi girilmedi.");
      return;
    }
    
    // Başarılı kayıt durumu
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Kayıt Başarılı"),
          content: Text("Kayıt işleminiz başarıyla tamamlandı. Giriş sayfasına yönlendiriliyorsunuz."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Text("Tamam"),
            ),
          ],
        );
      },
    );
  }
  
  // Hata ve bilgi mesajlarını gösteren yardımcı metot
  void showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tamam"),
            ),
          ],
        );
      },
    );
  }
} 