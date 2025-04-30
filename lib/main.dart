import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/survey_page.dart';
import 'screens/statistics_page.dart';
import 'screens/register_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anket Uygulaması',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/survey': (context) => SurveyPage(),
        '/statistics': (context) => StatisticsPage(),
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

giriş ekranında kayıt ol tuşu olsun. giriş yapması için veritabanında tcsinin ve şifresinin kayıtlı olması lazım eğer değilse kayıt olmadan giriş yapamaz. kayıt ol ekranında üstteki veriler için giriş kutucukları olsun tc ve şifre text olarak girilsin. doğum tarihi ajanda gibi acılan widgettan seçilsin. yasadığı il 81 ilden biri olarak seçilsin. okulu da istanbuldaki 20 üniversiteden biri ve okumuyorum seçilsin. anket sayfasında kaydet tusu olucak. kaydet tuşuna basmadan seçtiği oyu değiştirebilir ama kaydet tuşuna bastıktan sonra aynı kulllanıcı bir daha oyunu değiştiremez. oylar blockchain ile kayıt edilir.(nasıl yapılır bakılacak)

anketler:

cb secimi(doğum tarihine göre eleme > 18)
belediye secimi(yasadığı ile ve doğum tarihine göre eleme)
okul temsilcisi(eğer okulu varsa okula göre eleme)
işletim sistemi(doğum tarihine göre eleme > 12)
sosyal medya(doğum tarihine göre eleme > 15)
*/