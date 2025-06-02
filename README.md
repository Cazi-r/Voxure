# Voxure

Voxure, kullanicilarin demografik verilerine gore filtrelenmis anketleri goruntuleyebildigi ve oy kullanabilecegi bir Flutter uygulamasidir. Bu uygulama, modern bir arayuz ve guclu ozellikler ile anket oylama sistemini gelistirmeyi amaclamaktadir.

## Projenin Amaci

Bu projenin temel amaci, kullanicilarin demografik verilerine gore uygun anketleri goruntuleyebilecekleri ve guvenli bir sekilde oy kullanabilecekleri bir platform sunmaktir. Kullanici dostu bir arayuz ve guclu ozellikler ile anket oylama islemlerini kolaylastirmak hedeflenmistir.

## Teknik Detaylar

* Flutter: Uygulamanin temel gelistirme platformu.
* Firebase: Kullanici kimlik dogrulama (Authentication) ve anket verilerinin saklanmasi (Firestore).
* Provider: Durum yonetimi icin tercih edilmistir.
* HTTP: API istekleri icin kullanilmistir.

## One Cikan Ozellikler

* Kullanici Girisi: Firebase Authentication ile guvenli giris.
* Anket Yonetimi: Anket olusturma, duzenleme, silme ve oylama.
* Responsive Tasarim: Tum cihazlarda uyumlu bir kullanici deneyimi.
* Istatistikler: Anket sonuclarini grafiklerle goruntuleme.
* Cloud Firestore: Anket verilerinin guvenli saklanmasi.

## Kullanilan Teknolojiler

* Flutter
* Firebase (Authentication, Firestore)
* Provider (State Management)
* Shared Preferences (Yerel Veri Depolama)
* Supabase (Veritabani ve Kimlik Dogrulama)
* SQLite (Yerel Veritabani)
* HTTP (API istekleri)

## Sayfalarin Gorevleri ve Icerikleri

1. Giris Ekrani (login_screen.dart)
   * Kullanici e-posta ve sifre ile giris yapabilir
   * Google ve GitHub hesaplari ile tek tiklama ile giris yapabilir
   * "Giris Yap" ve "Kayit Ol" secenekleri mevcuttur
   * Basarili giristen sonra kullanici ana sayfaya yonlendirilir
   * Modern ve kullanici dostu arayuz

2. Kayit Ol Ekrani (register_screen.dart)
   * Kullanici, e-posta ve sifre bilgilerini girerek yeni bir hesap olusturabilir
   * Sifre dogrulama ozelligi ile kullanicidan iki kez sifre girmesi istenir
   * Firebase Authentication kullanilarak kullanici kaydi gerceklestirilir
   * Basarili kayit sonrasi kullanici ana sayfaya yonlendirilir

3. Ana Sayfa (home_screen.dart)
   * Kullaniciyi karsilayan bir hos geldiniz mesaji icerir
   * Kullanici bilgileri eksikse veya yoksa "Lutfen profil bilgilerinizi tamamlayin" uyarisi gosterir
   * Uygulamanin ana ozelliklerine (Anketler, Istatistikler, Profil, Ayarlar) hizli erisim saglayan kartlar sunar
   * Gorsel olarak sade arayuz

4. Anketler Ekrani (surveys_page.dart)
   * Kullanicinin kisisel bilgilerine uygun anketleri listeler
   * Her anket icin oylama islemleri

5. Yeni Anket Ekle Ekrani (survey_admin.dart)
   * Baslik ve sorular ile yeni anket olusturma
   * Mevcut anketleri goruntuleyebilme
   * Anketleri duzenleme veya silme
   * Kullanici dostu popup pencere ile anket ekleme arayuzu

6. Istatistikler Ekrani (statistics_screen.dart)
   * Anket sonuclarini grafiklerle gosterir
   * Detayli analiz ve raporlama
   * Kullanici bazli anket katilim oranlari

7. Profil Guncelleme Ekrani (profile_update_page.dart)
   * Kullanici bilgilerini guncelleme imkani
   * Kullanici bilgilerinin Firestore'da saklanmasi
   * Responsive tasarim ile tum cihazlarda uyumlu arayuz
   * Kullanici dostu form validasyonu
   * Basarili guncelleme sonrasi bildirim gosterme
   * Yerel veri depolama ozellikleri:
     - Shared Preferences ile kullanici tercihlerini saklama
     - SQLite ile profil bilgilerini yerel depolama
     - Veri yedekleme

## Drawer Menu

Drawer menu, kullanicilarin uygulama icinde kolay gezinmesini saglayan temel navigasyon yapisini icerir:

### Menu Ogeleri
* Ana Sayfa: Kullaniciyi karsilama ekrani ve ozet bilgiler
* Anketler: Kullanicinin katilabilecegi aktif anketler
* Istatistikler: Anket sonuclarinin grafik gosterimi
* Profil: Kullanici bilgileri ve guncelleme
* Cikis: Oturum kapatma

### BasePage Widget Yapisi
Tum sayfalar `BasePage` widget'ini kullanir ve su ozellikleri icerir:
* Standart app bar tasarimi
* Drawer menu entegrasyonu
* Sayfa basligi yonetimi
* Responsive tasarim destegi
* Kullanici yetkilendirme kontrolu

## Login Bilgilerinin Saklanmasi

Kullanici kimlik dogrulama ve veri saklama islemleri asagidaki sekilde gerceklestirilmektedir:

1. Kimlik Dogrulama:
   * E-posta/sifre ile giris yapildiginda Firebase Authentication kullanilir
   * Google ve GitHub ile sosyal medya girisleri desteklenir
   * Tum kimlik dogrulama islemleri Firebase tarafindan yonetilir

2. Veri Saklama:
   * Hassas bilgiler (sifre, token vb.) cihazda saklanmaz
   * Kullanici profili bilgileri Firestore'da tutulur
   * Oturum durumu ve tercihler SharedPreferences ile yerel olarak saklanir
   * Anket verileri ve istatistikler Supabase veritabaninda tutulur

3. Guvenlik:
   * Tum veri transferleri SSL/TLS ile sifrelenir
   * Firebase'in guvenlik kurallari ile veri erisimi kontrol edilir
   * Kullanici yetkilendirmesi token tabanli yapilir

## Firebase Authentication Kullanici Bilgileri

Firebase Authentication'da kayitli kullanicilar asagidaki gibidir:

1. Kullanici 1
   * E-posta: admin@example.com
   * Olusturulma Tarihi: 3 Haziran 2025
   * Son Giris Tarihi: 3 Nisan 2025
   * User UID: RSoZIw4KBRRbVmcwMfYvzSzNtqA2

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
* Windows

Her platform icin API anahtarlari, uygulama kimlikleri ve diger yapilandirma bilgileri bu dosyada bulunmaktadir.

## Supabase'de Anket Saklama Ornegi

Asagida, Supabase'de bir anketin nasil saklandigini gosteren bir ornek bulunmaktadir:

```json
{
  "id": "079fe4db-18cd-4f59-a543-02bb7dcba0a0",
  "soru": "Hangi Sosyal Medya Platformunu Kullanmayi Tercih Ediyorsunuz",
  "secenekler": ["Instagram", "X (Twitter)", "Facebook"],
  "oylar": ["0", "1", "0"],
  "kilitlendi": false,
  "ikon": "public",
  "renk": "blue",
  "minYas": 15,
  "ilFiltresi": false,
  "belirliIl": null,
  "okulFiltresi": false,
  "belirliOkul": null,
  "created_at": "2025-06-02 20:04:54.276308+00",
  "updated_at": "2025-06-02 20:29:36.83764+00"
}
```

## Cloud Firestore'da Kullanici Saklama Ornegi

Asagida, Cloud Firestore'da bir kullanicinin nasil saklandigini gosteren bir ornek bulunmaktadir:

```json
{
  "birthDate": "June 3, 1994 at 12:00:00 AM UTC+3",
  "city": "Istanbul",
  "email": "admin@example.com",
  "name": "Admin",
  "school": "Istanbul Sabahattin Zaim Universitesi",
  "surname": "Admin",
  "updatedAt": "June 3, 2025 at 12:30:30 AM UTC+3"
}
```

## Grup Uyelerinin Projeye Katkisi

* Yusuf Erdodu:
  * Ana sayfa (home_page.dart)
  * Anketler ekrani (survey_page.dart)
  * Istatistikler ekrani (statistics_page.dart)
  * Servisler (auth_service.dart, firebase_service.dart, local_storage_service.dart, supabase_service.dart)
  * Supabase entegrasyonu

* Metehan Beyaz:
  * Firebase Authentication entegrasyonu ve yapilandirmasi
  * Login ekrani (login_page.dart) gelistirme
  * Kayit ol ekrani (register_page.dart)
  * Drawer (custom_drawer.dart)

* Furkan Yilmaz:
  * Profil guncelleme ekrani (profile_update_page.dart)
  * Yeni anket ekle ekrani (survey_admin.dart)
  * Supabase yapilandirmasi
  * Kullanici bilgileri yonetimi
  * Kullanici arayuzu gelistirmeleri

## Modulerlik ve Kod Yapisi

1. Widgetlar:
   * custom_drawer.dart: Uygulamanin yan menusu icin ozel tasarlanmis bilesen
   * base_page.dart: Temel sayfa yapisi icin kullanilan ana widget
   * custom_app_bar.dart: Ozel tasarlanmis uygulama cubugu

2. Servisler:
   * firestore.dart: Cloud Firestore ile veri islemleri bir servis olarak yapilandirilmistir.
   * auth_service.dart: Firebase Authentication islemleri icin ayri bir servis olarak tasarlanmistir.
   * supabase_service.dart: Supabase veritabani islemleri icin ayri bir servis olarak tasarlanmistir.
   * local_storage_service.dart: Yerel depolama islemleri icin ayri bir servis olarak tasarlanmistir.

4. Ekranlar (Screens):
   * Her bir ekran (ornegin: login_screen.dart, surveys_screen.dart) ayri bir dosyada tanimlanmistir.
   * Bu ekranlar, ilgili islevsellikleri kapsar ve diger bilesenlerle kolayca entegre edilebilir.

5. Yapilandirma:
   * firebase_options.dart: Firebase yapilandirma bilgilerini icerir.

6. Tekrar Kullanilabilirlik:
   * Kodun farkli bolumleri (ornegin: Firestore islemleri, widgetlar) moduler yapilar sayesinde birden fazla yerde tekrar kullanilabilir.
   * Bu, kodun daha temiz ve surdurulebilir olmasini saglar.

## Gelistirme Ortami

Bu uygulamanin gelistirilmesi icin asagidaki araclar kullanilmistir:

* Flutter SDK
* Firebase CLI
* Visual Studio Code
* Android Studio

## Iletisim

Proje baglantisi: https://github.com/MetoisTaken/Vote_APP
