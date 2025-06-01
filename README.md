# Voxure - Firebase Tabanli Oylama Sistemi

## Genel Bakis

Voxure, demografik verilere gore filtrelenmis anketlerin sunuldugu ve oylarin guvenilir bir sekilde Firebase uzerinde kaydedildigi bir mobil uygulamadir. Bu sistem, geleneksel oylama sistemlerindeki guvenlik ve seffaflik sorunlarini cozmeyi amaclamaktadir.

## Ozellikler

- **Guvenli Kimlik Dogrulama**: Firebase Authentication ile guvenli kullanici girisi ve kayit
- **Gercek Zamanli Veri**: Firebase Firestore ile aninda guncellenen oy verileri
- **Demografik Filtreleme**: Kullanicilara yas, cinsiyet, egitim durumu gibi demografik ozelliklerine gore uygun anketlerin gosterilmesi
- **Istatistik Goruntuleme**: Anket sonuclarinin grafikler ile gosterilmesi
- **Cok Dilli Destek**: Turkce ve Ingilizce dil destegi

## Teknoloji Yigini

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore)
- **Coklu Dil Destegi**: Flutter Localization
- **Grafikler**: fl_chart

## Baslangic

### Gereksinimler

- Flutter SDK (en son surum)
- Dart SDK (en son surum)
- Firebase hesabi
- Firebase CLI

### Kurulum

1. Projeyi klonlayin:
```bash
git clone https://github.com/kullaniciadi/voxure.git
cd voxure
```

2. Bagimli paketleri yukleyin:
```bash
flutter pub get
```

3. Firebase yapilandirmasini tamamlayin:
   - Firebase konsolunda yeni bir proje olusturun
   - Flutter uygulamanizi Firebase'e ekleyin
   - Authentication ve Firestore hizmetlerini etkinlestirin
   - Firebase CLI ile projeyi baglatin:
   ```bash
   firebase login
   flutterfire configure
   ```

4. Uygulamayi calistirin:
```bash
flutter run
```

## Firebase Entegrasyonu

Voxure, kullanici kimlik dogrulama ve veri depolama icin Firebase hizmetlerini kullanir:

- **Authentication**: Guvenli kullanici girisi ve kayit islemleri
- **Firestore**: Anket ve oy verilerinin gercek zamanli depolanmasi
- **Security Rules**: Veri erisim kontrolu ve guvenlik kurallari

## Guvenlik Ozellikleri

- Kullanici kimlik bilgileri Firebase Authentication ile guvenli sekilde saklanir
- Firestore guvenlik kurallari ile veri erisimi kontrol edilir
- Hassas kullanici verileri sifrelenerek saklanir
- Gercek zamanli veri senkronizasyonu ile veri tutarliligi saglanir

## Mimari

Uygulama su katmanlardan olusur:

1. **Sunum Katmani**: Flutter UI bilesenleri
2. **Is Mantigi Katmani**: Firebase servisleri
3. **Veri Katmani**: Firebase Firestore

## Katki Saglama

Projeye katki saglamak istiyorsaniz:

1. Projeyi fork edin
2. Ozellik dali olusturun (`git checkout -b yeni-ozellik`)
3. Degisikliklerinizi commit edin (`git commit -m 'Yeni ozellik: Ozellik aciklamasi'`)
4. Dali puslayin (`git push origin yeni-ozellik`)
5. Bir Pull Request olusturun

## Lisans

Bu proje MIT lisansi altinda lisanslanmistir. Daha fazla bilgi icin `LICENSE` dosyasina bakin.

## Iletisim

Sorular ve geri bildirimler icin:
- E-posta: ornek@email.com
- GitHub: [github.com/kullaniciadi](https://github.com/kullaniciadi)
