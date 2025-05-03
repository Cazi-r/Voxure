# Voxure - Blockchain Destekli Oylama Sistemi

## Genel Bakis

Voxure, demografik verilere gore filtrelenmis anketlerin sunuldugu ve oylarin guvenilir bir sekilde blockchain uzerinde kaydedildigi bir mobil uygulamadir. Bu sistem, geleneksel oylama sistemlerindeki guvenlik ve seffaflik sorunlarini cozmeyi amaclamaktadir.

## Ozellikler

- **Guvenli Kimlik Dogrulama**: Firebase Authentication ile guvenli kullanici girisi ve kayit
- **Blockchain Tabanli Oylama**: Oylarin degistirilemez sekilde Ethereum blockchain'inde saklanmasi
- **Demografik Filtreleme**: Kullanicilara yas, cinsiyet, egitim durumu gibi demografik ozelliklerine gore uygun anketlerin gosterilmesi
- **Istatistik Goruntuleme**: Anket sonuclarinin grafikler ile gosterilmesi
- **Cok Dilli Destek**: Turkce ve Ingilizce dil destegi

## Teknoloji Yigini

- **Frontend**: Flutter (Dart)
- **Kimlik Dogrulama ve Veritabani**: Firebase (Authentication, Firestore)
- **Blockchain**: Ethereum (web3dart)
- **Coklu Dil Destegi**: Flutter Localization

## Baslangic

### Gereksinimler

- Flutter SDK (en son surum)
- Dart SDK (en son surum)
- Firebase hesabi
- Ethereum cuzdan (Metamask onerilir)
- Infura API anahtari (blockchain erisimi icin)

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

4. Ethereum ayarlarini yapin:
   - lib/services/blockchain_service.dart dosyasindaki Infura API anahtarinizi guncelleyin
   - Akilli kontrat adresi ve ABI'yi ayarlayin

5. Uygulamayi calistirin:
```bash
flutter run
```

## Blockchain Entegrasyonu

Voxure, oylarin degistirilemezligini ve seffafligini saglamak icin Ethereum blockchain teknolojisini kullanir:

- Her oy, kullanici bilgileri gizlenerek blockchain uzerinde saklanir
- Akilli kontratlar sayesinde oylar, degistirilemez ve dogrulanabilir
- Web3dart kutuphanesi kullanilarak Ethereum agina baglanilir

## Guvenlik Ozellikleri

- Kullanici kimlik bilgileri Firebase Authentication ile guvenli sekilde saklanir
- Blockchain'de saklanan veriler kriptografik olarak imzalanir
- Hassas kullanici verileri hash'lenerek saklanir
- Guncellenemez kayit sistemi ile veri butunlugu korunur

## Mimari

Uygulama su katmanlardan olusur:

1. **Sunum Katmani**: Flutter UI bilesenleri
2. **Is Mantigi Katmani**: Servisler (Firebase ve Blockchain)
3. **Veri Katmani**: Firebase Firestore ve Ethereum Blockchain

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
