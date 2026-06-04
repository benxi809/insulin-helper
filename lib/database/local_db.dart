import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:insulin_app/models/models.dart';

/// 本地数据库
/// 存储血糖记录、胰岛素注射记录、用户配置
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'insulin_app.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _migrateTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 血糖记录表
    await db.execute('''
      CREATE TABLE glucose_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        glucose REAL NOT NULL,
        timestamp TEXT NOT NULL,
        tag INTEGER NOT NULL DEFAULT 5
      )
    ''');

    // 胰岛素注射记录表
    await db.execute('''
      CREATE TABLE insulin_doses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        units REAL NOT NULL,
        timestamp TEXT NOT NULL,
        insulinType INTEGER NOT NULL DEFAULT 0,
        tag INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 用户配置表（仅一行）
    await db.execute('''
      CREATE TABLE user_config (
        id INTEGER PRIMARY KEY DEFAULT 1,
        targetGlucoseMin REAL NOT NULL DEFAULT 5.0,
        targetGlucoseMax REAL NOT NULL DEFAULT 7.2,
        isf REAL NOT NULL DEFAULT 2.5,
        icr REAL NOT NULL DEFAULT 12.0,
        insulinType INTEGER NOT NULL DEFAULT 0,
        iobDurationHours INTEGER NOT NULL DEFAULT 4,
        maxDosePerInjection REAL NOT NULL DEFAULT 20.0,
        patientName TEXT NOT NULL DEFAULT '',
        age INTEGER NOT NULL DEFAULT 30,
        diabetesType INTEGER NOT NULL DEFAULT 1,
        diagnosisDate TEXT,
        hba1c REAL,
        medicationRegimen TEXT NOT NULL DEFAULT '每日多次注射（MDI）',
        targetHba1c INTEGER DEFAULT 7,
        weight REAL NOT NULL DEFAULT 65.0,
        reminderBreakfast INTEGER NOT NULL DEFAULT 1,
        reminderLunch INTEGER NOT NULL DEFAULT 1,
        reminderDinner INTEGER NOT NULL DEFAULT 1,
        reminderBedtime INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 插入默认配置
    await db.insert('user_config', UserConfig().toMap());
  }

  /// 数据库迁移
  Future<void> _migrateTables(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: 增加用户信息字段
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE user_config ADD COLUMN patientName TEXT NOT NULL DEFAULT \'\'');
      await db.execute('ALTER TABLE user_config ADD COLUMN age INTEGER NOT NULL DEFAULT 30');
      await db.execute('ALTER TABLE user_config ADD COLUMN diabetesType INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE user_config ADD COLUMN diagnosisDate TEXT');
      await db.execute('ALTER TABLE user_config ADD COLUMN hba1c REAL');
      await db.execute('ALTER TABLE user_config ADD COLUMN medicationRegimen TEXT NOT NULL DEFAULT \'每日多次注射（MDI）\'');
      await db.execute('ALTER TABLE user_config ADD COLUMN targetHba1c INTEGER DEFAULT 7');
      await db.execute('ALTER TABLE user_config ADD COLUMN weight REAL NOT NULL DEFAULT 65.0');
      await db.execute('ALTER TABLE user_config ADD COLUMN reminderBreakfast INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE user_config ADD COLUMN reminderLunch INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE user_config ADD COLUMN reminderDinner INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE user_config ADD COLUMN reminderBedtime INTEGER NOT NULL DEFAULT 1');
    }
  }

  // ========== 血糖记录 CRUD ==========

  Future<int> insertGlucose(GlucoseRecord record) async {
    final db = await database;
    return await db.insert('glucose_records', record.toMap());
  }

  Future<List<GlucoseRecord>> getGlucoseRecords({
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'timestamp BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      where = 'timestamp >= ?';
      whereArgs = [startDate.toIso8601String()];
    } else if (endDate != null) {
      where = 'timestamp <= ?';
      whereArgs = [endDate.toIso8601String()];
    }

    final maps = await db.query(
      'glucose_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => GlucoseRecord.fromMap(m)).toList();
  }

  Future<int> deleteGlucose(int id) async {
    final db = await database;
    return await db.delete('glucose_records', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 胰岛素注射记录 CRUD ==========

  Future<int> insertDose(InsulinDose dose) async {
    final db = await database;
    return await db.insert('insulin_doses', dose.toMap());
  }

  Future<List<InsulinDose>> getDoses({
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'timestamp BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      where = 'timestamp >= ?';
      whereArgs = [startDate.toIso8601String()];
    }

    final maps = await db.query(
      'insulin_doses',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => InsulinDose.fromMap(m)).toList();
  }

  // ========== 用户配置 ==========

  Future<UserConfig> getConfig() async {
    final db = await database;
    final maps = await db.query('user_config', where: 'id = 1');
    if (maps.isEmpty) {
      final config = UserConfig();
      await db.insert('user_config', config.toMap());
      return config;
    }
    return UserConfig.fromMap(maps.first);
  }

  Future<void> updateConfig(UserConfig config) async {
    final db = await database;
    await db.update(
      'user_config',
      config.toMap(),
      where: 'id = 1',
    );
  }

  /// 获取今天或指定日期的汇总
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // 血糖统计
    final glucoseMaps = await db.query(
      'glucose_records',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    final records = glucoseMaps.map((m) => GlucoseRecord.fromMap(m)).toList();

    double? minGlucose;
    double? maxGlucose;
    double sumGlucose = 0;

    for (final r in records) {
      sumGlucose += r.glucose;
      if (minGlucose == null || r.glucose < minGlucose) minGlucose = r.glucose;
      if (maxGlucose == null || r.glucose > maxGlucose) maxGlucose = r.glucose;
    }

    // 胰岛素统计
    final doseMaps = await db.query(
      'insulin_doses',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    final doses = doseMaps.map((m) => InsulinDose.fromMap(m)).toList();
    double totalDose = 0;
    for (final d in doses) {
      totalDose += d.units;
    }

    // 低血糖次数 (glucose < 3.9)
    final lowCount = records.where((r) => r.glucose < 3.9).length;

    return {
      'recordCount': records.length,
      'minGlucose': minGlucose,
      'maxGlucose': maxGlucose,
      'avgGlucose': records.isEmpty ? null : sumGlucose / records.length,
      'totalDose': totalDose,
      'lowCount': lowCount,
      'doseCount': doses.length,
    };
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
