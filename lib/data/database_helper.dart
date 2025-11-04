import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = "poster_tool";
  static const _dbVersion = 1;

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    debugPrint("📁 Database path: $path");

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // user table
    await db.execute('''
CREATE TABLE user(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
)
''');

    // poster table
    await db.execute('''
CREATE TABLE poster(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  image1 TEXT,
  image2 TEXT,
  image3 TEXT,
  type TEXT NOT NULL,
  model TEXT NOT NULL,
  price INT,
  distance_traveled INT,
  engine_size TEXT,
  location TEXT,
  notes TEXT, -- store as JSON string for string array
  phone_number TEXT
)
''');
  }
}
