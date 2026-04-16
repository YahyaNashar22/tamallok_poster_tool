import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'poster_tool.db';
  static const _dbVersion = 2;

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    debugPrint('Database path: $path');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUserTable(db);
    await _createPosterTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE poster RENAME TO poster_old');
        await _createPosterTable(txn);
        await txn.execute('''
INSERT INTO poster (
  id,
  web_id,
  image1,
  image2,
  image3,
  type,
  model,
  price,
  distance_traveled,
  engine_size,
  location,
  notes,
  phone_number
)
SELECT
  id,
  CAST(web_id AS TEXT),
  image1,
  image2,
  image3,
  type,
  model,
  CASE
    WHEN price IS NULL OR TRIM(CAST(price AS TEXT)) = '' THEN NULL
    ELSE CAST(price AS REAL)
  END,
  CASE
    WHEN distance_traveled IS NULL OR TRIM(CAST(distance_traveled AS TEXT)) = '' THEN NULL
    ELSE CAST(distance_traveled AS REAL)
  END,
  engine_size,
  location,
  notes,
  phone_number
FROM poster_old
''');
        await txn.execute('DROP TABLE poster_old');
      });
    }
  }

  Future<void> _createUserTable(DatabaseExecutor db) async {
    await db.execute('''
CREATE TABLE user(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
)
''');
  }

  Future<void> _createPosterTable(DatabaseExecutor db) async {
    await db.execute('''
CREATE TABLE poster(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  web_id TEXT UNIQUE,
  image1 TEXT,
  image2 TEXT,
  image3 TEXT,
  type TEXT NOT NULL,
  model TEXT NOT NULL,
  price REAL,
  distance_traveled REAL,
  engine_size TEXT,
  location TEXT,
  notes TEXT,
  phone_number TEXT
)
''');
  }
}
