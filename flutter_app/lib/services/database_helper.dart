import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConfig.databaseName);
    
    return await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Medicines table
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand_name TEXT NOT NULL,
        generic_name TEXT NOT NULL,
        strength TEXT NOT NULL,
        manufacturer TEXT NOT NULL,
        uses TEXT NOT NULL,
        side_effects TEXT NOT NULL,
        warnings TEXT NOT NULL,
        image_url TEXT,
        barcode TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better search performance
    await db.execute('CREATE INDEX idx_brand_name ON medicines(brand_name)');
    await db.execute('CREATE INDEX idx_generic_name ON medicines(generic_name)');
    await db.execute('CREATE INDEX idx_manufacturer ON medicines(manufacturer)');
    await db.execute('CREATE INDEX idx_barcode ON medicines(barcode)');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Add any migration logic here
    }
  }

  Future<void> _insertSampleData(Database db) async {
    final List<Map<String, dynamic>> sampleMedicines = [
      {
        'brand_name': 'Paracetamol',
        'generic_name': 'Acetaminophen',
        'strength': '500mg',
        'manufacturer': 'ABC Pharmaceuticals',
        'uses': 'Pain relief and fever reduction',
        'side_effects': 'Nausea, stomach upset, allergic reactions',
        'warnings': 'Do not exceed recommended dosage. Consult doctor if symptoms persist.',
        'image_url': null,
        'barcode': '1234567890123',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'brand_name': 'Amoxicillin',
        'generic_name': 'Amoxicillin',
        'strength': '250mg',
        'manufacturer': 'XYZ Pharmaceuticals',
        'uses': 'Treatment of bacterial infections',
        'side_effects': 'Diarrhea, nausea, skin rash',
        'warnings': 'Complete the full course. Do not stop early.',
        'image_url': null,
        'barcode': '9876543210987',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'brand_name': 'Ibuprofen',
        'generic_name': 'Ibuprofen',
        'strength': '400mg',
        'manufacturer': 'DEF Pharmaceuticals',
        'uses': 'Pain relief, inflammation reduction',
        'side_effects': 'Stomach irritation, dizziness, headache',
        'warnings': 'Take with food. Avoid if you have stomach ulcers.',
        'image_url': null,
        'barcode': '4567891230456',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final medicine in sampleMedicines) {
      await db.insert('medicines', medicine);
    }
  }

  // CRUD Operations
  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return await db.insert('medicines', medicine.toMap());
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medicines');
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  Future<Medicine?> getMedicineById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Medicine.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'brand_name LIKE ? OR generic_name LIKE ? OR manufacturer LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  Future<Medicine?> getMedicineByBarcode(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    
    if (maps.isNotEmpty) {
      return Medicine.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final db = await database;
    return await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    final db = await database;
    return await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('medicines');
  }

  Future<int> getMedicineCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM medicines');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Batch operations for syncing with cloud
  Future<void> batchInsertMedicines(List<Medicine> medicines) async {
    final db = await database;
    final batch = db.batch();
    
    for (final medicine in medicines) {
      batch.insert('medicines', medicine.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  Future<void> batchUpdateMedicines(List<Medicine> medicines) async {
    final db = await database;
    final batch = db.batch();
    
    for (final medicine in medicines) {
      batch.update(
        'medicines',
        medicine.toMap(),
        where: 'id = ?',
        whereArgs: [medicine.id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
