import '../db/database_helper.dart';
import '../../domain/entities/tarifa.dart';
import '../../core/constants/app_constants.dart';

class TarifaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Crear nueva tarifa
  Future<int> crearTarifa(Tarifa tarifa) async {
    return await _dbHelper.insert(AppConstants.tableTarifa, tarifa.toMap());
  }

  // Obtener todas las tarifas
  Future<List<Tarifa>> obtenerTodas() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableTarifa,
      orderBy: 'fechaCreacion DESC',
    );
    return List.generate(maps.length, (i) {
      return Tarifa.fromMap(maps[i]);
    });
  }

  // Obtener tarifas activas
  Future<List<Tarifa>> obtenerActivas() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableTarifa,
      where: 'activa = ?',
      whereArgs: [1],
      orderBy: 'fechaCreacion DESC',
    );
    return List.generate(maps.length, (i) {
      return Tarifa.fromMap(maps[i]);
    });
  }

  // Obtener tarifa por ID
  Future<Tarifa?> obtenerPorId(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableTarifa,
      where: 'id = ?',
      whereArgs: [id as Object],
    );
    if (maps.isNotEmpty) {
      return Tarifa.fromMap(maps.first);
    }
    return null;
  }

  // Obtener tarifa activa por defecto
  Future<Tarifa?> obtenerTarifaActiva() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      AppConstants.tableTarifa,
      where: 'activa = ?',
      whereArgs: [1],
      orderBy: 'fechaCreacion DESC',
    );
    if (maps.isNotEmpty) {
      return Tarifa.fromMap(maps.first);
    }
    return null;
  }

  // Actualizar tarifa
  Future<int> actualizarTarifa(Tarifa tarifa) async {
    return await _dbHelper.update(
      AppConstants.tableTarifa,
      tarifa.toMap(),
      where: 'id = ?',
      whereArgs: [tarifa.id as Object],
    );
  }

  // Desactivar tarifa
  Future<int> desactivarTarifa(int id) async {
    return await _dbHelper.update(
      AppConstants.tableTarifa,
      {'activa': 0},
      where: 'id = ?',
      whereArgs: [id as Object],
    );
  }

  // Activar tarifa
  Future<int> activarTarifa(int id) async {
    return await _dbHelper.update(
      AppConstants.tableTarifa,
      {'activa': 1},
      where: 'id = ?',
      whereArgs: [id as Object],
    );
  }

  // Eliminar tarifa
  Future<int> eliminarTarifa(int id) async {
    return await _dbHelper.delete(
      AppConstants.tableTarifa,
      where: 'id = ?',
      whereArgs: [id as Object],
    );
  }

  // Cambiar tarifa activa (desactiva todas y activa la nueva)
  Future<void> cambiarTarifaActiva(int nuevaTarifaId) async {
    // Desactivar todas las tarifas
    await _dbHelper.update(AppConstants.tableTarifa, {'activa': 0});

    // Activar la nueva tarifa
    await activarTarifa(nuevaTarifaId);
  }
}
