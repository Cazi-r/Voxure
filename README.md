# Not Cepte

Not Cepte, kullanicilarin notlarini hizli ve kolay bir sekilde olusturmasina, duzenlemesine ve yonetmesine olanak taniyan bir Flutter uygulamasidir. Bu uygulama, modern bir arayuz ve guclu ozellikler ile kullanici deneyimini gelistirmeyi amaclamaktadir.

## Projenin Amaci

Bu projenin temel amaci, kullanicilarin dijital notlarini guvenli bir sekilde saklayabilecekleri ve yonetebilecekleri bir platform sunmaktir. Kullanici dostu bir arayuz ve guclu ozellikler ile not alma islemlerini kolaylastirmak hedeflenmistir.

## Teknik Detaylar

* Flutter: Uygulamanin temel gelistirme platformu.
* Firebase: Kullanici kimlik dogrulama (Authentication) ve notlarin saklanmasi (Firestore).
* Provider: Durum yonetimi icin tercih edilmistir.
* HTTP: API istekleri icin kullanilmistir.

## One Cikan Ozellikler

* Kullanici Girisi: Firebase Authentication ile guvenli giris.
* Not Yonetimi: Not olusturma, duzenleme, silme ve favorilere ekleme.
* Tema Yonetimi: Karanlik ve acik tema arasinda gecis yapabilme.
* Responsive Tasarim: Tum cihazlarda uyumlu bir kullanici deneyimi.
* Arama Fonksiyonu: Notlar arasinda hizli arama yapabilme.
* Favoriler: Onemli notlari favorilere ekleme ve yonetme.
* Cloud Firestore: Not verilerinin guvenli saklanmasi.

## Kullanilan Teknolojiler

* Flutter
* Firebase (Authentication, Firestore)
* Provider (State Management)
* HTTP (API istekleri)

## Sayfalarin Gorevleri ve Icerikleri

1. Giris Yap Ekrani (login_screen.dart)
   * Kullanici e-posta ve sifre ile giris yapabilir
   * "Sifremi Unuttum" ve "Kayit Ol" secenekleri mevcuttur
   * Basarili giristen sonra kullanici ana sayfaya yonlendirilir
   * Modern ve kullanici dostu arayuz

2. Sifremi Unuttum Ekrani (forgot_password_screen.dart)
   * Kullanici, e-posta adresini girerek sifre sifirlama baglantisi talep edebilir.
   * Firebase Authentication uzerinden sifre sifirlama e-postasi gonderilir.
   * Basarili islem sonrasi kullanici bilgilendirilir ve giris ekranina yonlendirilir.

3. Kayit Ol Ekrani (register_screen.dart)
   * Kullanici, e-posta, sifre ve kullanici adi bilgilerini girerek yeni bir hesap olusturabilir.
   * Sifre dogrulama ozelligi ile kullanicidan iki kez sifre girmesi istenir.
   * Firebase Authentication kullanilarak kullanici kaydi gerceklestirilir.
   * Basarili kayit sonrasi kullanici ana sayfaya yonlendirilir.

4. Ana Sayfa (home_screen.dart)
   * Kullaniciyi karsilayan bir hos geldiniz mesaji icerir
   * Uygulamanin ana ozelliklerine (Yeni Not, Notlarim, Favoriler, Ayarlar) hizli erisim saglayan kartlar sunar
   * Renk gradyanlari ile gorsel olarak cekici bir arayuz

5. Notlarim Ekrani (notes_screen.dart)
   * Kullanicinin tum notlarini listeler
   * Notlari arama fonksiyonu
   * Her not icin duzenleme, silme ve yildizlama/favorilere ekleme islemleri
   * Floating action button ile yeni not ekleme

6. Yeni Not Ekle Ekrani (add_note_screen.dart)
   * Baslik ve icerik ile yeni not olusturma
   * Mevcut notlari goruntuleyebilme
   * Notlari duzenleme veya silme
   * Kullanici dostu modal dialog ile not ekleme arayuzu

7. Favoriler Ekrani (favorites_screen.dart)
   * Yildizlanmis/favorilere eklenmis notlari gosterir
   * Favorilerden cikarma secenegi
   * Favori notlari duzenleme ve silme

8. Ayarlar Ekrani (settings_screen.dart)
   * Uygulama temasini degistirme (karanlik/acik mod)
   * Kullanici profili ve hesap ayarlari
   * Bildirim tercihleri
   * Uygulama hakkinda bilgiler ve yardim secenekleri

## Drawer Menu ve Logo API Bilgileri

Drawer menude kullanilan logo, Brandfetch API'sinden alinmaktadir:

API URL: https://cdn.brandfetch.io/notejoy.com/v1/196/h/196/logo?c=118m3Jx8ZugQwuDb2f

Bu logo, LogoProvider sinifi tarafindan yonetilmektedir. fetchLogoFromApi() metodu, API'den logo URL'sini alir ve uygulama genelinde kullanilabilir hale getirir.

## Login Bilgilerinin Saklanmasi

-firebase e posta: ayseflutter@gmail.com -firebase sifre: flutter123.

Kullanici giris bilgileri Firebase Authentication kullanilarak guvenli bir sekilde saklanmaktadir:

1. Kullanici, e-posta ve sifre ile giris yaptiginda, bilgiler Firebase Authentication'a gonderilir
2. Firebase, kullanici bilgilerini kendi guvenli veritabaninda saklar
3. Basarili giris sonrasi, oturum belirteci (token) uygulamada saklanir ve API isteklerinde kullanilir
4. Hassas bilgiler (sifre vb.) cihazda saklanmaz; tum kimlik dogrulama Firebase tarafindan yonetilir

## Firebase Authentication Kullanici Bilgileri

Firebase Authentication'da kayitli kullanicilar asagidaki gibidir:

1. Kullanici 1
   * E-posta: aysegulerrgun@gmail.com
   * Olusturulma Tarihi: 4 Nisan 2025
   * Son Giris Tarihi: 6 Nisan 2025
   * User UID: 7wdOFSpBmttWF4N1Fmmuow3FwtBx1

2. Kullanici 2
   * E-posta: test@gmail.com
   * Olusturulma Tarihi: Apr 7, 2025
   * Son Giris Tarihi: Apr 7, 2025
   * User UID: 69ULJ65ikVDpQ7y5RqhivPosqV2

3. Kullanici 3
   * E-posta: test2@gmail.com
   * Olusturulma Tarihi: Apr 7, 2025
   * Son Giris Tarihi: Apr 7, 2025
   * User UID: ZnZkWmHuEz40UMbvSxXmJA0JVJ3

## Firebase Yapilandirmasi

Uygulama, farkli platformlar icin Firebase yapilandirmasini `firebase_options.dart` dosyasinda icerir:

* Web
* Android
* iOS
* macOS
* Windows

Her platform icin API anahtarlari, uygulama kimlikleri ve diger yapilandirma bilgileri bu dosyada bulunmaktadir.

## Tema Yonetimi

Uygulama, karanlik ve acik tema arasinda gecis yapma ozelligine sahiptir:

1. Tema tercihleri, `ThemeProvider` sinifi tarafindan yonetilir
2. Kullanicilar, Ayarlar ekranindan tema tercihlerini degistirebilirler
3. Secilen tema, uygulama genelinde tutarli bir gorunum saglar

## Cloud Firestore'da Not Saklama Ornegi

Asagida, Cloud Firestore'da bir notun nasil saklandigini gosteren bir ornek bulunmaktadir:

```json
{
  "content": "OYS ve projeyi yukle",
  "email": "aysegulerrgun@gmail.com",
  "isStarred": true,
  "timestamp": "April 7, 2025 at 11:08:47 PM UTC+3",
  "title": "Odev1",
  "uid": "7wdOFSpBmttWF4N1Fmmuow3FwtBx1"
}
```

* email: Notu olusturan kullanicinin mail adresi
* uid: Notu olusturan kullanicinin id'si
* title: Notun basligi (string).
* content: Notun icerigi (string).
* isStarred: Notun favorilere eklenip eklenmedigini belirten durum (boolean).
* timestamp: Notun olusturulma veya guncellenme zamani (timestamp).

## Cloud Firestore'da Kullanici Saklama Ornegi

Asagida, Cloud Firestore'da bir kullanicinin nasil saklandigini gosteren bir ornek bulunmaktadir:

```json
{
  "createdAt": "April 7, 2025 at 10:07:34 PM UTC+3",
  "email": "test2@gmail.com",
  "uid": "ZnZkWmHuEz40UMbvSxXmJA0JVJ3",
  "username": "Test-2 kullanici"
}
```

* createdAt: Kullanicinin ekledigi tarih
* email: Kullanicinin e-posta adresi (string).
* uid: Kullanicinin id'si
* username: Kullanici adi (string).

## Grup Uyelerinin Projeye Katkisi

* Aysegul Ergun:
  * Ana sayfa (home_screen.dart)
  * notlarim ekrani (notes_screen.dart)
  * Yeni not ekle ekrani (add_note_screen.dart)
  * Favoriler ekrani (favorites_screen.dart)
  * Ayarlar ekrani (settings_screen.dart)
  * drawer (drawer.dart)
  * providers (logo_provider.dart) ve (theme_provider.dart)
  * services (auth_service.dart) ve (firestore.dart)
  * theme (theme.dart)
  * widgets (logo_display.dart)
  * Tema yonetimi ve responsive tasarim
  * Firebase yapilandirmasi

* Omer Demirtas:
  * Kayit ol ve sifremi unuttum ozellikleri
  * Firebase Authentication entegrasyonu
  * Login ekrani (login_screen.dart) gelistirme
  * Sifremi unuttum ekrani (forgot_password_screen.dart)
  * Kayit ol ekrani (register_screen.dart)

## Modulerlik ve Kod Yapisi

1. Widgetlar:
   * drawer.dart: Uygulamanin yan menusu (Drawer) icin bir bilesen olarak tasarlanmistir.
   * logo_display.dart: Logo goruntulenme islemleri icin ayri bir widget olarak olusturulmustur.

2. Servisler:
   * firestore.dart: Cloud Firestore ile veri islemleri (CRUD) icin bir servis olarak yapilandirilmistir.
   * auth_service.dart: Firebase Authentication islemleri icin ayri bir servis olarak tasarlanmistir.

3. Saglayicilar (Providers):
   * theme_provider.dart: Tema yonetimi icin bir saglayici olarak kullanilmistir.
   * logo_provider.dart: Logo yukleme ve yonetimi icin bir saglayici olarak yapilandirilmistir.

4. Ekranlar (Screens):
   * Her bir ekran (ornegin: login_screen.dart, notes_screen.dart) ayri bir dosyada tanimlanmistir.
   * Bu ekranlar, ilgili islevsellikleri kapsar ve diger bilesenlerle kolayca entegre edilebilir.

5. Tema ve Yapilandirma:
   * theme.dart: Karanlik ve acik tema yonetimi icin merkezi bir yapi sunar.
   * firebase_options.dart: Firebase yapilandirma bilgilerini icerir.

6. Tekrar Kullanilabilirlik:
   * Kodun farkli bolumleri (ornegin: Firestore islemleri, tema yonetimi) moduler yapilar sayesinde birden fazla yerde tekrar kullanilabilir.
   * Bu, kodun daha temiz ve surdurulebilir olmasini saglar.

## Gelistirme Ortami

Bu uygulamanin gelistirilmesi icin asagidaki araclar kullanilmistir:

* Flutter SDK
* Firebase CLI
* Visual Studio Code
* Android Studio

## Iletisim

Proje baglantisi: https://github.com/AysegulErgun/notcepte