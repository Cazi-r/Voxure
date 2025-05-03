# Voxure - Blockchain Destekli Oylama Sistemi

## Genel Bakış

Voxure, demografik verilere göre filtrelenmiş anketlerin sunulduğu ve oyların güvenilir bir şekilde blockchain üzerinde kaydedildiği bir Flutter uygulamasıdır. Uygulama, kullanıcı kimlik doğrulama ve yetkilendirme için Firebase Authentication, kullanıcı profil verilerini saklamak için Firebase Firestore, ve oyları değiştirilemez şekilde kaydetmek için Ethereum blockchain kullanmaktadır.

## Blockchain Entegrasyonu

Oylar, şeffaflık ve değiştirilemezlik ilkelerine dayalı olarak Ethereum blockchain'inde saklanır. Her oy, aşağıdaki avantajlara sahip şekilde kaydedilir:

- **Değiştirilemezlik**: Bir kez kaydedilen oy değiştirilemez
- **Şeffaflık**: Tüm oylar, gizlilik korunarak herkes tarafından doğrulanabilir
- **Güvenilirlik**: Merkezi olmayan yapı, tek bir hata noktasını ortadan kaldırır

## Kurulum ve Gereksinimler

Projeyi çalıştırmak için aşağıdaki adımları izleyin:

1. Dependencies ekleyin:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.7.0
  firebase_auth: ^4.2.10
  cloud_firestore: ^4.4.4
  # Blockchain entegrasyonu için
  web3dart: ^2.6.1
  http: ^0.13.5
  crypto: ^3.0.3
```

2. Ethereum cüzdanı ve Infura hesabı oluşturun:
   - Metamask veya başka bir Ethereum cüzdanı kullanarak bir cüzdan oluşturun
   - [Infura](https://infura.io/) üzerinde hesap açarak bir API anahtarı alın
   - Sepolia veya Rinkeby test ağı için test ETH alın

3. Akıllı kontratı deploy edin:
   - lib/contracts/VoteContract.sol dosyasını Remix IDE veya Truffle gibi bir araç kullanarak deploy edin
   - Deployment sonrası kontrat adresini alın

4. BlockchainService'i yapılandırın:
   - lib/services/blockchain_service.dart dosyasındaki Infura API anahtarını, özel anahtarınızı ve kontrat adresini güncelleyin

## Güvenlik Notları

1. Ethereum özel anahtarınızı asla kodun içine yazmayın. Bunun yerine, güvenli bir depolama veya çevresel değişkenler kullanın.

2. Oyları blockchain'e kaydederken hash kullanarak kullanıcı bilgilerini gizlemeye dikkat edin.

3. Kullanıcı verilerinin işlenmesinde KVKK/GDPR uyumluluğuna dikkat edin.

## Test Etme

Sistemi test etmek için:

1. Test ağında (Sepolia/Rinkeby) kontratı deploy edin
2. BlockchainService içindeki network ID'sini doğru şekilde ayarlayın
3. Geliştirme modunda uygulamayı çalıştırın ve konsolda işlem loglarını izleyin
4. Etherscan üzerinden işlemleri doğrulayın
