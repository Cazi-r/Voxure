import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/survey_page.dart';
import 'screens/statistics_page.dart';
import 'screens/register_page.dart';
import 'screens/profile_update_page.dart';
import 'screens/admin/survey_admin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  // Flutter widget bağlamını başlat
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Firebase'i başlat
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Yerel depolama servisini başlat
    await LocalStorageService().init();
    
    print('Firebase initialized successfully');
  } catch (e) {
    print('Initialization error: $e');
  }

  await Supabase.initialize(
    url: 'https://bkytzrsygidkkshpzsyd.supabase.co', // Supabase proje URL'niz
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJreXR6cnN5Z2lka2tzaHB6c3lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3ODcwMTksImV4cCI6MjA2NDM2MzAxOX0.CmZIdh2bQ6xIVbLjj_ZCbTfVOudw2vTLHiVRGhDKK2E', // Supabase anonim anahtariniz
  );
  
  print('Supabase initialized successfully');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voxure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5181BE),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5181BE)),
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
      home: StreamBuilder(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData) {
            return HomePage();
          }
          
          return LoginPage();
        },
      ),
      routes: {
        '/home': (context) => HomePage(),
        '/survey': (context) => SurveyPage(),
        '/statistics': (context) => StatisticsPage(),
        '/profile_update': (context) => ProfileUpdatePage(),
        '/admin/survey': (context) => SurveyAdminPage(),
        '/register': (context) => RegisterPage(),
      },
    );
  }
}
