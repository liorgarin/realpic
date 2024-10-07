// lib/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  // Singleton pattern to ensure only one instance exists
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  static const int _databaseVersion = 3; // Updated database version

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'films.db'); // Database file name
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE films(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        max_photos INTEGER,
        status TEXT,
        receiver_name TEXT,
        phone_number TEXT,
        country TEXT,
        city TEXT,
        street_address TEXT,
        postal_code TEXT,
        additional_details TEXT
      )
      ''',
    );
    await db.execute(
      '''
      CREATE TABLE photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        film_id INTEGER,
        path TEXT,
        FOREIGN KEY(film_id) REFERENCES films(id)
      )
      ''',
    );
    print('Database tables created');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Upgrade to version 2
      await db.execute("ALTER TABLE films ADD COLUMN receiver_name TEXT;");
      await db.execute("ALTER TABLE films ADD COLUMN phone_number TEXT;");
      await db.execute("ALTER TABLE films ADD COLUMN country TEXT;");
      await db.execute("ALTER TABLE films ADD COLUMN city TEXT;");
      await db.execute("ALTER TABLE films ADD COLUMN street_address TEXT;");
      await db.execute("ALTER TABLE films ADD COLUMN postal_code TEXT;");
      await db.execute("ALTER TABLE films ADD COLUMN additional_details TEXT;");
      print('Database upgraded to version 2 and 3');
    }
  }

  // Insert a new film
  Future<int> insertFilm(String name, int maxPhotos) async {
    final db = await database;
    int filmId = await db.insert('films', {
      'name': name,
      'max_photos': maxPhotos,
      'status': FilmStatus.active,
    });
    print('Inserted film with ID: $filmId, Name: $name, Max Photos: $maxPhotos');
    return filmId;
  }

  // Fetch films by status
  Future<List<Map<String, dynamic>>> getFilmsByStatus(String status) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'films',
      where: 'status = ?',
      whereArgs: [status],
    );
    print('Fetched ${result.length} film(s) with status "$status".');
    return result;
  }

  // Insert a new photo
  Future<int> insertPhoto(String path, int filmId) async {
    final db = await database;
    int photoId = await db.insert('photos', {
      'path': path,
      'film_id': filmId,
    });
    print('Inserted photo with ID: $photoId for film ID: $filmId at path: $path');
    return photoId;
  }

  // Fetch photos by film ID
  Future<List<Map<String, dynamic>>> getPhotosByFilm(int filmId) async {
    final db = await database;
    return await db.query(
      'photos',
      where: 'film_id = ?',
      whereArgs: [filmId],
    );
  }

  // Get the count of photos for a film
  Future<int> getPhotoCount(int filmId) async {
    final db = await database;
    int? count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM photos WHERE film_id = ?',
        [filmId],
      ),
    );
    print('Film ID: $filmId has $count photo(s).');
    return count ?? 0;
  }

  // Fetch a film by its ID
  Future<Map<String, dynamic>?> getFilmById(int filmId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'films',
      where: 'id = ?',
      whereArgs: [filmId],
    );
    if (result.isNotEmpty) {
      print('Fetched film by ID: $filmId.');
      return result.first;
    } else {
      print('No film found with ID: $filmId.');
      return null;
    }
  }

  // Update a film's status
  Future<void> updateFilmStatus(int filmId, String newStatus) async {
    final db = await database;
    int count = await db.update(
      'films',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [filmId],
    );
    print('Updated film ID: $filmId to status "$newStatus". Rows affected: $count');
  }

  // Update a film's shipping details and set status to 'on the way'
  Future<void> updateFilmShippingDetails({
    required int filmId,
    required String receiverName,
    required String phoneNumber,
    required String country,
    required String city,
    required String streetAddress,
    required String postalCode,
    String? additionalDetails,
  }) async {
    final db = await database;
    int count = await db.update(
      'films',
      {
        'receiver_name': receiverName,
        'phone_number': phoneNumber,
        'country': country,
        'city': city,
        'street_address': streetAddress,
        'postal_code': postalCode,
        'additional_details': additionalDetails,
        'status': FilmStatus.onTheWay,
      },
      where: 'id = ?',
      whereArgs: [filmId],
    );
    print('Updated shipping details for film ID: $filmId. Rows affected: $count');
  }
}

// Define consistent status strings
class FilmStatus {
  static const String active = 'active';
  static const String readyToPrint = 'ready to print';
  static const String onTheWay = 'on the way';
  static const String arrived = 'arrived';
}