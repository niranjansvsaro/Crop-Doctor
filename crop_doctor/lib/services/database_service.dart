import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_result.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scans.db');
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
      CREATE TABLE scans (
        id TEXT PRIMARY KEY,
        farmer_id TEXT NOT NULL,
        image_url TEXT NOT NULL,
        disease_name_en TEXT NOT NULL,
        disease_name_local TEXT NOT NULL,
        severity INTEGER NOT NULL,
        confidence REAL NOT NULL,
        affected_area_pct REAL NOT NULL,
        treatment_en TEXT NOT NULL,
        treatment_local TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        language TEXT NOT NULL,
        gps_lat REAL,
        gps_lng REAL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertScan(ScanResult scan) async {
    final db = await instance.database;
    return await db.insert(
      'scans',
      scan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanResult>> getScans() async {
    final db = await instance.database;
    final result = await db.query('scans', orderBy: 'created_at DESC');
    return result.map((json) => ScanResult.fromMap(json)).toList();
  }

  Future<List<ScanResult>> searchScans(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'scans',
      where: 'disease_name_en LIKE ? OR disease_name_local LIKE ? OR crop_type LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => ScanResult.fromMap(json)).toList();
  }

  Future<int> deleteScan(String id) async {
    final db = await instance.database;
    return await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearHistory() async {
    final db = await instance.database;
    return await db.delete('scans');
  }

  // Calculate dashboard statistics
  Future<Map<String, dynamic>> getWeeklyStats() async {
    // Get all scans
    final scans = await getScans();
    if (scans.isEmpty) {
      return {
        'total_scans': 0,
        'diseased_count': 0,
        'healthy_count': 0,
        'average_health_score': 100.0,
        'scans_by_day': [0, 0, 0, 0, 0, 0, 0], // Mon-Sun
      };
    }

    int diseased = 0;
    int healthy = 0;
    double totalSeverity = 0;

    // We assume severity of 1 is healthy/mild, severity > 2 is diseased.
    // Wait, let's look at the scan's disease name. If it contains "healthy" or is empty, we classify as healthy.
    for (var scan in scans) {
      if (scan.diseaseNameEn.toLowerCase().contains('healthy') || 
          scan.diseaseNameEn.isEmpty || 
          scan.severity == 1) {
        healthy++;
      } else {
        diseased++;
        totalSeverity += scan.severity;
      }
    }

    // Health Score calculation (0 to 100)
    // Formula: 100 - (average severity of diseased / max severity 5) * (diseased / total) * 100
    double avgSeverity = diseased > 0 ? totalSeverity / diseased : 0;
    double healthScore = 100.0;
    if (scans.isNotEmpty) {
      healthScore = 100.0 - (diseased / scans.length) * (avgSeverity / 5.0) * 100.0;
    }
    
    // Determine weekly scans by day (past 7 days)
    // We group by day of week of the current week
    List<int> scansByDay = List.filled(7, 0);
    final now = DateTime.now();
    for (var scan in scans) {
      try {
        final date = DateTime.parse(scan.createdAt);
        final difference = now.difference(date).inDays;
        if (difference < 7) {
          // Calculate weekday (0 = Mon, 6 = Sun)
          int dayIndex = date.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            scansByDay[dayIndex]++;
          }
        }
      } catch (e) {
        // Date parsing error
      }
    }

    return {
      'total_scans': scans.length,
      'diseased_count': diseased,
      'healthy_count': healthy,
      'average_health_score': healthScore.clamp(0.0, 100.0),
      'scans_by_day': scansByDay,
    };
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
