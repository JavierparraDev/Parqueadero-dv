import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

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
    String path = join(await getDatabasesPath(), 'parqueadero_dv.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla para placas ocasionales
    await db.execute('''
      CREATE TABLE placa_ocasional (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        placa TEXT NOT NULL,
        fechaEntrada TEXT NOT NULL,
        fechaSalida TEXT,
        totalPagar REAL,
        estado TEXT NOT NULL DEFAULT 'activa',
        dejaCasco BOOLEAN DEFAULT 0,
        cantidadCascos INTEGER DEFAULT 0,
        observaciones TEXT
      )
    ''');

    // Tabla para placas mensuales
    await db.execute('''
      CREATE TABLE placa_mensual (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        placa TEXT NOT NULL,
        fechaInicio TEXT NOT NULL,
        fechaFin TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'activa',
        valorMensualidad REAL NOT NULL,
        observaciones TEXT
      )
    ''');

    // Tabla para configuración de tarifas
    await db.execute('''
      CREATE TABLE tarifa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valorPorHora REAL NOT NULL,
        valorPorMediaHora REAL NOT NULL,
        valorPorDia REAL NOT NULL,
        valorMensualidad REAL NOT NULL,
        fechaCreacion TEXT NOT NULL,
        fechaActualizacion TEXT NOT NULL
      )
    ''');

    // Insertar configuración por defecto
    await db.insert('tarifa', {
      'valorPorHora': 2000.0,
      'valorPorMediaHora': 1000.0,
      'valorPorDia': 15000.0,
      'valorMensualidad': 80000.0,
      'fechaCreacion': DateTime.now().toIso8601String(),
      'fechaActualizacion': DateTime.now().toIso8601String(),
    });
  }

  // Métodos genéricos CRUD
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Métodos específicos para tarifas
  Future<Map<String, dynamic>?> obtenerTarifaActiva() async {
    final result = await query(
      'tarifa',
      orderBy: 'fechaActualizacion DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> actualizarTarifa(Map<String, dynamic> tarifa) async {
    final tarifaActual = await obtenerTarifaActiva();
    if (tarifaActual != null) {
      // Actualizar tarifa existente
      await update(
        'tarifa',
        {...tarifa, 'fechaActualizacion': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [tarifaActual['id']],
      );
    } else {
      // Crear nueva tarifa
      await insert('tarifa', {
        ...tarifa,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });
    }
  }

  // Métodos específicos para placas ocasionales
  Future<List<Map<String, dynamic>>> obtenerPlacasOcasionalesActivas() async {
    return await query(
      'placa_ocasional',
      where: 'estado = ?',
      whereArgs: ['activa'],
      orderBy: 'fechaEntrada DESC',
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPlacasOcasionalesDelDia() async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    return await query(
      'placa_ocasional',
      where: 'fechaEntrada >= ? AND fechaEntrada < ?',
      whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
      orderBy: 'fechaEntrada DESC',
    );
  }

  Future<Map<String, dynamic>?> obtenerPlacaOcasionalPorId(int id) async {
    final result = await query(
      'placa_ocasional',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> obtenerPlacaOcasionalPorPlaca(
    String placa,
  ) async {
    final result = await query(
      'placa_ocasional',
      where: 'placa = ? AND estado = ?',
      whereArgs: [placa, 'activa'],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Métodos específicos para placas mensuales
  Future<List<Map<String, dynamic>>> obtenerPlacasMensualesActivas() async {
    return await query(
      'placa_mensual',
      where: 'estado = ?',
      whereArgs: ['activa'],
      orderBy: 'fechaInicio DESC',
    );
  }

  Future<Map<String, dynamic>?> obtenerPlacaMensualPorPlaca(
    String placa,
  ) async {
    final result = await query(
      'placa_mensual',
      where: 'placa = ? AND estado = ?',
      whereArgs: [placa, 'activa'],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Método para limpiar registros del día (cierre de día)
  Future<void> limpiarRegistrosDelDia() async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    // Marcar como inactivas las placas del día
    await update(
      'placa_ocasional',
      {'estado': 'inactiva'},
      where: 'fechaEntrada >= ? AND fechaEntrada < ? AND estado = ?',
      whereArgs: [
        inicioDia.toIso8601String(),
        finDia.toIso8601String(),
        'activa',
      ],
    );
  }
}
