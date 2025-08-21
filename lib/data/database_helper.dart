import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracking_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_minutes INTEGER DEFAULT 0,
        screenshots_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE screenshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES tracking_sessions (id)
      )
    ''');
  }

  Future<int> insertTrackingSession(Map<String, dynamic> session) async {
    final db = await instance.database;
    return await db.insert('tracking_sessions', session);
  }

  Future<void> updateTrackingSession(int id, Map<String, dynamic> session) async {
    final db = await instance.database;
    await db.update(
      'tracking_sessions',
      session,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertScreenshot(Map<String, dynamic> screenshot) async {
    final db = await instance.database;
    return await db.insert('screenshots', screenshot);
  }

  Future<List<Map<String, dynamic>>> getWeeklyReport() async {
    final db = await instance.database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().split('T')[0];

    return await db.query(
      'tracking_sessions',
      where: 'DATE(created_at) >= ?',
      whereArgs: [weekStartStr],
      orderBy: 'created_at DESC',
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}