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
import 'services/blockchain_service.dart';
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
    
    // Blockchain servisini başlat
    final blockchainService = BlockchainService();
    // Burada herhangi bir metodu çağırmamıza gerek yok,
    // constructor içinde _initialize() metodu çağrılacak
    
    print('Blockchain service initialized');
  } catch (e) {
    print('Initialization error: $e');
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
Basit bir oy verme işlemi Ethereum ana ağında şu an için yaklaşık ₺1.75 – ₺5.00 arasında bir maliyete yol açar.
 Bu fiyat ağın yoğunluğuna ve fonksiyonun karmaşıklığına göre değişebilir.
*/