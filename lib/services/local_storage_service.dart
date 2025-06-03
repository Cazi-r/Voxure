// Bu servis, kullanıcı verilerinin yerel depolanmasını yönetir.
// SharedPreferences ve SQLite kullanarak kullanıcı bilgilerini cihaz üzerinde saklar.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  // Singleton pattern uygulaması
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;
  late Database _database;

  // Servisi başlatma ve veritabanı şemasını oluşturma
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _database = await openDatabase(
      join(await getDatabasesPath(), 'user_database.db'),
      onCreate: (db, version) async {
        // Kullanıcı bilgileri için tablo oluştur
        await db.execute(
          'CREATE TABLE users(id TEXT PRIMARY KEY, email TEXT, name TEXT, surname TEXT, birthDate TEXT, city TEXT, school TEXT, updatedAt TEXT)',
        );
      },
      version: 1,
    );
  }

  // SharedPreferences'a kullanıcı verilerini kaydetme
  Future<void> saveUserToPrefs(Map<String, dynamic> userData) async {
    await _prefs.setString('user_email', userData['email'] ?? '');
    await _prefs.setString('user_name', userData['name'] ?? '');
    await _prefs.setString('user_surname', userData['surname'] ?? '');
    await _prefs.setString('user_birthDate', userData['birthDate']?.toString() ?? '');
    await _prefs.setString('user_city', userData['city'] ?? '');
    await _prefs.setString('user_school', userData['school'] ?? '');
    await _prefs.setString('user_updatedAt', userData['updatedAt']?.toString() ?? '');
  }

  // SharedPreferences'dan kullanıcı verilerini okuma
  Map<String, dynamic> getUserFromPrefs() {
    return {
      'email': _prefs.getString('user_email'),
      'name': _prefs.getString('user_name'),
      'surname': _prefs.getString('user_surname'),
      'birthDate': _prefs.getString('user_birthDate'),
      'city': _prefs.getString('user_city'),
      'school': _prefs.getString('user_school'),
      'updatedAt': _prefs.getString('user_updatedAt'),
    };
  }

  // SQLite veritabanına kullanıcı verilerini kaydetme
  Future<void> saveUserToSQLite(Map<String, dynamic> userData) async {
    await _database.insert(
      'users',
      {
        'id': userData['id'],
        'email': userData['email'],
        'name': userData['name'],
        'surname': userData['surname'],
        'birthDate': userData['birthDate']?.toString(),
        'city': userData['city'],
        'school': userData['school'],
        'updatedAt': userData['updatedAt']?.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // SQLite veritabanından kullanıcı verilerini okuma
  Future<Map<String, dynamic>?> getUserFromSQLite(String userId) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
} 