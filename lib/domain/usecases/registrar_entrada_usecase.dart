import '../entities/placa_ocasional.dart';
import '../../data/repositories/placa_ocasional_repository.dart';
import '../../data/repositories/placa_mensual_repository.dart';
import '../../data/repositories/tarifa_repository.dart';

class RegistrarEntradaUseCase {
  final PlacaOcasionalRepository _placaOcasionalRepo;
  final PlacaMensualRepository _placaMensualRepo;
  final TarifaRepository _tarifaRepo;

  RegistrarEntradaUseCase({
    required PlacaOcasionalRepository placaOcasionalRepo,
    required PlacaMensualRepository placaMensualRepo,
    required TarifaRepository tarifaRepo,
  }) : _placaOcasionalRepo = placaOcasionalRepo,
       _placaMensualRepo = placaMensualRepo,
       _tarifaRepo = tarifaRepo;

  Future<Map<String, dynamic>> ejecutar(
    String placa, {
    String? observaciones,
  }) async {
    try {
      // Verificar si la placa ya está registrada como activa
      final placaExistente = await _placaOcasionalRepo.obtenerPorPlaca(placa);
      if (placaExistente != null) {
        return {
          'exito': false,
          'mensaje': 'La placa ya está registrada como activa',
          'placa': placaExistente,
        };
      }

      // Verificar si es una placa mensual vigente
      final placaMensual = await _placaMensualRepo.obtenerPorPlaca(placa);
      if (placaMensual != null && placaMensual.estaVigente) {
        return {
          'exito': true,
          'mensaje': 'Placa mensual vigente - No se cobra',
          'esMensual': true,
          'placaMensual': placaMensual,
        };
      }

      // Obtener tarifa activa
      final tarifa = await _tarifaRepo.obtenerTarifaActiva();
      if (tarifa == null) {
        return {'exito': false, 'mensaje': 'No hay tarifa configurada'};
      }

      // Crear nueva placa ocasional
      final nuevaPlaca = PlacaOcasional(
        placa: placa.toUpperCase(),
        fechaEntrada: DateTime.now(),
        tarifa: tarifa.precioPorHora,
        observaciones: observaciones,
      );

      final id = await _placaOcasionalRepo.crearPlaca(nuevaPlaca);
      final placaCreada = nuevaPlaca.copyWith(id: id);

      return {
        'exito': true,
        'mensaje': 'Entrada registrada exitosamente',
        'placa': placaCreada,
        'tarifa': tarifa,
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al registrar entrada: $e'};
    }
  }
}
