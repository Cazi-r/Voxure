import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

/// BlockchainService: Oylama verilerini dogrudan Ganache blockchain uzerinde saklayan servis.
///
/// Bu servis, yerel Ganache blockchain emulatorunu kullanarak oy verilerini saklar.
/// Veri kaliciligi SADECE blockchain uzerinde saglanir, yerel onbellek KULLANILMAZ.
class BlockchainService {
  // Ganache URL (platform'a gore otomatik ayarlanir)
  late final String _blockchainUrl;
  
  // Web3 istemcisi
  late final Web3Client _web3client;
  
  // Akilli sozlesme adresi - sozlesme deploy edildiginde buraya girin
  
  //  http://127.0.0.1:7545
  static const String _contractAddress = '0xcFf524Ee95B6860C7a31492CE854819B87C36C2f';
  
  // Ethereum cuzdan bilgileri - Ganache'ten aldiginiz hesap ozel anahtarini buraya girin
  static const String _adminPrivateKey = '7a311416002f0c25cf9bfc4ddf04094447869477899425be5479e15afddec5a6';
  
  // Akilli sozlesme ABI 
  static const String _contractABI = '''
[
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "string",
        "name": "surveyId",
        "type": "string"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "voter",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "optionIndex",
        "type": "uint256"
      }
    ],
    "name": "VoteCast",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "surveyId",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "userId",
        "type": "string"
      }
    ],
    "name": "getUserVote",
    "outputs": [
      {
        "internalType": "int256",
        "name": "",
        "type": "int256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "surveyId",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "optionIndex",
        "type": "uint256"
      }
    ],
    "name": "getVoteCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "surveyId",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "optionIndex",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "userId",
        "type": "string"
      }
    ],
    "name": "vote",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
''';

  // Baslatma durumu
  bool _isInitialized = false;
  
  // Singleton pattern
  static final BlockchainService _instance = BlockchainService._internal();
  
  // Factory constructor
  factory BlockchainService() {
    return _instance;
  }
  
  // Private constructor
  BlockchainService._internal() {
    _initialize();
  }
  
  // Servisi baslat
  Future<void> _initialize() async {
    if (!_isInitialized) {
      try {
        // Platform'a gore blockchain URL'ini belirle
        _blockchainUrl = Platform.isAndroid
            ? 'http://45.87.173.15:7545/'  // Android emulator icin
            : 'http://127.0.0.1:7545'; // iOS simulator veya desktop
        
        print('Blockchain URL: $_blockchainUrl');
        
        // Web3 istemcisini olustur
        final httpClient = http.Client();
        _web3client = Web3Client(_blockchainUrl, httpClient);
        
        // Blockchain ile baglanti testi
        try {
          final blockNumber = await _web3client.getBlockNumber();
          print('Ganache baglantisi basarili. Guncel blok: $blockNumber');
        } catch (e) {
          print('Blockchain baglanti hatasi: $e');
          throw Exception('Blockchain baglantisi kurulamadi. Lutfen Ganache calistigindan emin olun.');
        }
        
        _isInitialized = true;
      } catch (e) {
        print('Blockchain servisi baslatilirken hata: $e');
        rethrow; // Hatayi yeniden firlat
      }
    }
  }
  
  // Akilli sozlesmeyi getir
  DeployedContract _getDeployedContract() {
    final contract = DeployedContract(
      ContractAbi.fromJson(_contractABI, 'VoteContract'),
      EthereumAddress.fromHex(_contractAddress),
    );
    return contract;
  }
  
  // Admin kimlik bilgilerini olustur
  Credentials _getAdminCredentials() {
    return EthPrivateKey.fromHex(_adminPrivateKey);
  }
  
  // Oy verme islemini kaydet - SADECE blockchain'e yazar
  Future<bool> saveVote(Map<String, dynamic> voteData) async {
    try {
      // Servisin baslatildigindan emin ol
      if (!_isInitialized) {
        await _initialize();
      }
      
      final String surveyId = voteData['surveyId'] as String;
      final int optionIndex = voteData['optionIndex'] as int;
      final String userId = voteData['userId'] as String;
      
      // Kullanici daha once oy vermis mi kontrol et
      final userVote = await getUserVote(userId, surveyId);
      if (userVote != null) {
        print('Kullanici bu ankete zaten oy vermis: $userId, $surveyId');
        return false;
      }
      
      try {
        // Akilli sozlesmeyi cagir - blockchain'e oy verme islemini gonder
        final contract = _getDeployedContract();
        final function = contract.function('vote');
        
        // Admin kimlik bilgileri
        final credentials = _getAdminCredentials();
        
        // Islemi gonder - senkron olarak bekle
        final transaction = await _web3client.sendTransaction(
          credentials,
          Transaction.callContract(
            contract: contract,
            function: function,
            parameters: [surveyId, BigInt.from(optionIndex), userId],
          ),
          chainId: 1337, // Ganache icin chain ID
        );
        
        print('Oy islemi blockchain\'e gonderildi, TX: $transaction');
        return true;
        
      } catch (e) {
        print('Blockchain\'e islem gonderilirken hata: $e');
        return false;
      }
      
    } catch (e) {
      print('Oy kaydedilirken hata: $e');
      return false;
    }
  }
  
  // Toplu oy verme islemini kaydet
  Future<bool> saveBulkVotes(List<Map<String, dynamic>> votesData) async {
    try {
      // Servisin baslatildigindan emin ol
      if (!_isInitialized) {
        await _initialize();
      }
      
      bool allSuccessful = true;
      
      // Her oy icin kayit olustur
      for (var voteData in votesData) {
        final bool success = await saveVote(voteData);
        if (!success) {
          allSuccessful = false;
        }
      }
      
      return allSuccessful;
    } catch (e) {
      print('Toplu oy kaydedilirken hata: $e');
      return false;
    }
  }
  
  // Bir anket icin oy verilerini getir - HER SEFERINDE BLOCKCHAIN'DEN ALIR
  Future<Map<int, int>> getSurveyVotes(String surveyId) async {
    // Servisin baslatildigindan emin ol
    if (!_isInitialized) {
      await _initialize();
    }
    
    try {
      Map<int, int> voteCount = {};
      
      // Blockchain'den oy sayilarini al
      final contract = _getDeployedContract();
      final function = contract.function('getVoteCount');
      
      // 10 secenege kadar destek var
      for (int i = 0; i < 10; i++) {
        try {
          final result = await _web3client.call(
            contract: contract, 
            function: function, 
            params: [surveyId, BigInt.from(i)]
          );
          
          if (result.isNotEmpty && result[0] is BigInt) {
            final count = (result[0] as BigInt).toInt();
            if (count > 0) {
              voteCount[i] = count;
            }
          }
        } catch (e) {
          // Secenekte oy yoksa veya baska bir hata olursa devam et
        }
      }
      
      return voteCount;
    } catch (e) {
      print('Anket oylari alinirken hata: $e');
      return {};
    }
  }
  
  // Kullanicinin belirli bir anketteki oyunu getir - HER SEFERINDE BLOCKCHAIN'DEN ALIR
  Future<Map<String, dynamic>?> getUserVote(String userId, String surveyId) async {
    // Servisin baslatildigindan emin ol
    if (!_isInitialized) {
      await _initialize();
    }
    
    try {
      // Blockchain'den kullanicinin oyunu sorgula
      final contract = _getDeployedContract();
      final function = contract.function('getUserVote');
      
      final result = await _web3client.call(
        contract: contract, 
        function: function, 
        params: [surveyId, userId]
      );
      
      if (result.isNotEmpty && result[0] is BigInt) {
        final optionIndex = (result[0] as BigInt).toInt();
        
        // -1 degeri oy verilmedigini gosterir
        if (optionIndex >= 0) {
          return {
            'userId': userId,
            'surveyId': surveyId,
            'optionIndex': optionIndex,
          };
        }
      }
      
      return null; // Kullanici oy vermemis
    } catch (e) {
      print('Kullanici oyu alinirken hata: $e');
      return null;
    }
  }
  
  // Oy verme islemini dogrula - DOGRUDAN BLOCKCHAIN'DEN KONTROL EDER
  Future<bool> verifyVote(Map<String, dynamic> voteData) async {
    final userId = voteData['userId'] as String;
    final surveyId = voteData['surveyId'] as String;
    final optionIndex = voteData['optionIndex'] as int;
    
    final userVote = await getUserVote(userId, surveyId);
    
    if (userVote != null && userVote['optionIndex'] == optionIndex) {
      return true;
    }
    
    return false;
  }
  
  // Blockchain baglanti durumunu kontrol et
  Future<bool> isConnected() async {
    try {
      if (!_isInitialized) {
        await _initialize();
      }
      
      await _web3client.getBlockNumber();
      return true;
    } catch (e) {
      return false;
    }
  }
} 