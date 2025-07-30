import '../db/database_helper.dart';
import '../../domain/entities/placa_ocasional.dart';
import '../../core/constants/app_constants.dart';

class PlacaOcasionalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Crear nueva placa ocasional
  Future<int> crearPlaca(PlacaOcasional placa) async {
    return await _dbHelper.insert(
      AppConstants.tablePlacaOcasional,
      placa.toMap(),
    );
  }

  // Obtener todas las placas ocasionales
  Future<List<PlacaOcasional>> obtenerTodas() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaOcasional,
      orderBy: 'fechaEntrada DESC',
    );
    return List.generate(maps.length, (i) {
      return PlacaOcasional.fromMap(maps[i]);
    });
  }

  // Obtener placas activas
  Future<List<PlacaOcasional>> obtenerActivas() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaOcasional,
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'fechaEntrada DESC',
    );
    return List.generate(maps.length, (i) {
      return PlacaOcasional.fromMap(maps[i]);
    });
  }

  // Obtener placa por ID
  Future<PlacaOcasional?> obtenerPorId(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaOcasional,
      where: 'id = ?',
      whereArgs: [id as Object],
    );
    if (maps.isNotEmpty) {
      return PlacaOcasional.fromMap(maps.first);
    }
    return null;
  }

  // Obtener placa por número de placa
  Future<PlacaOcasional?> obtenerPorPlaca(String placa) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tablePlacaOcasional,
      where: 'placa = ? AND activo = ?',
      whereArgs: [placa, 1],
    );
    if (maps.isNotEmpty) {
      return PlacaOcasional.fromMap(maps.first);
    }
    return null;
  }

  // Actualizar placa
  Future<int> actualizarPlaca(PlacaOcasional placa) async {
    return await _dbHelper.update(
      AppConstants.tablePlacaOcasional,
      placa.toMap(),
      where: 'id = ?',
      whereArgs: [placa.id as Object],
    );
  }

  // Registrar salida de vehículo
  Future<int> registrarSalida(
    int id,
    DateTime fechaSalida,
    double totalPagar,
  ) async {
    return await _dbHelper.update(
      AppConstants.tablePlacaOcasional,
      {
        'fechaSalida': fechaSalida.millisecondsSinceEpoch,
        'totalPagar': totalPagar,
        'activo': 0,
      },
      where: 'id = ?',
      whereArgs: [id as Object],
    );
  }

  // Eliminar placa
  Future<int> eliminarPlaca(int id) async {
    return await _dbHelper.delete(
      AppConstants.tablePlacaOcasional,
      where: 'id = ?',
      whereArgs: [id as Object],
    );
  }

  // Obtener estadísticas del día
  Future<Map<String, dynamic>> obtenerEstadisticasDia(DateTime fecha) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final List<Map<String, dynamic>> entradas = await _dbHelper.query(
      AppConstants.tablePlacaOcasional,
      where: 'fechaEntrada >= ? AND fechaEntrada < ?',
      whereArgs: [
        inicioDia.millisecondsSinceEpoch,
        finDia.millisecondsSinceEpoch,
      ],
    );

    final List<Map<String, dynamic>> salidas = await _dbHelper.query(
      AppConstants.tablePlacaOcasional,
      where: 'fechaSalida >= ? AND fechaSalida < ?',
      whereArgs: [
        inicioDia.millisecondsSinceEpoch,
        finDia.millisecondsSinceEpoch,
      ],
    );

    double totalIngresos = 0;
    for (var salida in salidas) {
      totalIngresos += salida['totalPagar'] ?? 0;
    }

    return {
      'entradas': entradas.length,
      'salidas': salidas.length,
      'totalIngresos': totalIngresos,
      'vehiculosActivos': await obtenerActivas().then(
        (placas) => placas.length,
      ),
    };
  }
}
