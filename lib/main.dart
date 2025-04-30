import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/survey_page.dart';
import 'screens/statistics_page.dart';
import 'screens/register_page.dart';
import 'screens/profile_update_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Flutter widget bağlamını başlat
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Firebase'i başlat
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  
  // Kullanıcı giriş durumunu kontrol et
  Future<void> _checkLoginStatus() async {
    try {
      _isLoggedIn = _firebaseService.isUserLoggedIn();
    } catch (e) {
      print('Login check error: $e');
    } finally {
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Uygulama başlatılana kadar yükleniyor göster
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'Voxure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF5181BE),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF5181BE)),
        useMaterial3: true,
      ),
      // Lokalizasyon delegeleri ekle
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Desteklenen diller
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe
        Locale('en', 'US'), // İngilizce
      ],
      // Varsayılan dil
      locale: const Locale('tr', 'TR'),
      initialRoute: _isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/survey': (context) => SurveyPage(),
        '/statistics': (context) => StatisticsPage(),
        '/profile_update': (context) => ProfileUpdatePage(),
      },
    );
  }
}

/*
tckimlik
şifre
doğum tarihi
yaşadığı il
okul(bu bos olabilir, bos ise null değer olacak)

giriş ekranında kayıt ol tuşu olsun. giriş yapması için veritabanında tcsinin ve şifresinin kayıtlı olması lazım eğer değilse kayıt olmadan giriş yapamaz.
kayıt ol ekranında üstteki veriler için giriş kutucukları olsun tc ve şifre text olarak girilsin. doğum tarihi ajanda gibi acılan widgettan seçilsin.
yasadığı il 81 ilden biri olarak seçilsin. okulu da istanbuldaki 20 üniversiteden biri ve okumuyorum seçilsin. anket sayfasında kaydet tusu olucak.
kaydet tuşuna basmadan seçtiği oyu değiştirebilir ama kaydet tuşuna bastıktan sonra aynı kulllanıcı bir daha oyunu değiştiremez. oylar blockchain ile kayıt edilir.(nasıl yapılır bakılacak)

anketler:

cb secimi(doğum tarihine göre eleme > 18)
belediye secimi(yasadığı ile ve doğum tarihine göre eleme)
okul temsilcisi(eğer okulu varsa okula göre eleme)
işletim sistemi(doğum tarihine göre eleme > 12)
sosyal medya(doğum tarihine göre eleme > 15)
*/