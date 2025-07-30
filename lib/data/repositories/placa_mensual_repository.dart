import '../db/database_helper.dart';
import '../../domain/entities/placa_mensual.dart';
import '../../core/constants/app_constants.dart';

class PlacaMensualRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Crear nueva placa mensual
  Future<int> crearPlaca(PlacaMensual placa) async {
    return await _dbHelper.insert(
      AppConstants.tablePlacaMensual,
      placa.toMap(),
    );
  }

  // Obtener todas las placas mensuales
  Future<List<PlacaMensual>> obtenerTodas() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaMensual,
      orderBy: 'fechaCreacion DESC',
    );
    return List.generate(maps.length, (i) {
      return PlacaMensual.fromMap(maps[i]);
    });
  }

  // Obtener placas vigentes
  Future<List<PlacaMensual>> obtenerVigentes() async {
    final ahora = DateTime.now();
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaMensual,
      where: 'activo = ? AND fechaInicio <= ? AND fechaFin >= ?',
      whereArgs: [
        1,
        ahora.millisecondsSinceEpoch,
        ahora.millisecondsSinceEpoch,
      ],
      orderBy: 'fechaCreacion DESC',
    );
    return List.generate(maps.length, (i) {
      return PlacaMensual.fromMap(maps[i]);
    });
  }

  // Obtener placa por ID
  Future<PlacaMensual?> obtenerPorId(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaMensual,
      where: 'id = ?',
      whereArgs: [id as Object],
    );
    if (maps.isNotEmpty) {
      return PlacaMensual.fromMap(maps.first);
    }
    return null;
  }

  // Obtener placa por número de placa
  Future<PlacaMensual?> obtenerPorPlaca(String placa) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaMensual,
      where: 'placa = ? AND activo = ?',
      whereArgs: [placa, 1],
    );
    if (maps.isNotEmpty) {
      return PlacaMensual.fromMap(maps.first);
    }
    return null;
  }

  // Actualizar placa
  Future<int> actualizarPlaca(PlacaMensual placa) async {
    return await _dbHelper.update(
      AppConstants.tablePlacaMensual,
      placa.toMap(),
      where: 'id = ?',
      whereArgs: [placa.id as Object],
    );
  }

  // Desactivar placa
  Future<int> desactivarPlaca(int id) async {
    return await _dbHelper.update(
      AppConstants.tablePlacaMensual,
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id as Object],
    );
  }

  // Eliminar placa
  Future<int> eliminarPlaca(int id) async {
    return await _dbHelper.delete(
      AppConstants.tablePlacaMensual,
      where: 'id = ?',
      whereArgs: [id as Object],
    );
  }

  // Obtener placas que vencen pronto (próximos 7 días)
  Future<List<PlacaMensual>> obtenerVencenPronto() async {
    final ahora = DateTime.now();
    final proximaSemana = ahora.add(const Duration(days: 7));

    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaMensual,
      where: 'activo = ? AND fechaFin >= ? AND fechaFin <= ?',
      whereArgs: [
        1,
        ahora.millisecondsSinceEpoch,
        proximaSemana.millisecondsSinceEpoch,
      ],
      orderBy: 'fechaFin ASC',
    );
    return List.generate(maps.length, (i) {
      return PlacaMensual.fromMap(maps[i]);
    });
  }

  // Obtener estadísticas de mensuales
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    final List<Map<String, dynamic>> todas = await _dbHelper.query(
      AppConstants.tablePlacaMensual,
      where: 'activo = ?',
      whereArgs: [1],
    );

    final vigentes = await obtenerVigentes();
    final vencenPronto = await obtenerVencenPronto();

    double totalIngresos = 0;
    for (var placa in todas) {
      totalIngresos += placa['tarifaMensual'] ?? 0;
    }

    return {
      'totalPlacas': todas.length,
      'placasVigentes': vigentes.length,
      'placasVencenPronto': vencenPronto.length,
      'totalIngresos': totalIngresos,
    };
  }
}
