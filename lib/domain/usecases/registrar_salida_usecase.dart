import '../../data/repositories/placa_ocasional_repository.dart';
import '../../data/repositories/tarifa_repository.dart';

class RegistrarSalidaUseCase {
  final PlacaOcasionalRepository _placaOcasionalRepo;
  final TarifaRepository _tarifaRepo;

  RegistrarSalidaUseCase({
    required PlacaOcasionalRepository placaOcasionalRepo,
    required TarifaRepository tarifaRepo,
  }) : _placaOcasionalRepo = placaOcasionalRepo,
       _tarifaRepo = tarifaRepo;

  Future<Map<String, dynamic>> ejecutar(String placa) async {
    try {
      // Buscar la placa activa
      final placaActiva = await _placaOcasionalRepo.obtenerPorPlaca(placa);
      if (placaActiva == null) {
        return {
          'exito': false,
          'mensaje': 'No se encontró una entrada activa para esta placa',
        };
      }

      // Calcular tiempo de estacionamiento
      final fechaSalida = DateTime.now();
      final tiempoEstacionamiento = fechaSalida.difference(
        placaActiva.fechaEntrada,
      );

      // Obtener tarifa activa
      final tarifa = await _tarifaRepo.obtenerTarifaActiva();
      if (tarifa == null) {
        return {'exito': false, 'mensaje': 'No hay tarifa configurada'};
      }

      // Calcular total a pagar
      final totalPagar = tarifa.calcularPrecio(tiempoEstacionamiento);

      // Registrar salida
      await _placaOcasionalRepo.registrarSalida(
        placaActiva.id!,
        fechaSalida,
        totalPagar,
      );

      // Crear objeto de respuesta
      final placaActualizada = placaActiva.copyWith(
        fechaSalida: fechaSalida,
        totalPagar: totalPagar,
        activo: false,
      );

      return {
        'exito': true,
        'mensaje': 'Salida registrada exitosamente',
        'placa': placaActualizada,
        'tiempoEstacionamiento': tiempoEstacionamiento,
        'totalPagar': totalPagar,
        'tarifa': tarifa,
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al registrar salida: $e'};
    }
  }

  // Calcular precio sin registrar salida
  Future<Map<String, dynamic>> calcularPrecio(String placa) async {
    try {
      final placaActiva = await _placaOcasionalRepo.obtenerPorPlaca(placa);
      if (placaActiva == null) {
        return {
          'exito': false,
          'mensaje': 'No se encontró una entrada activa para esta placa',
        };
      }

      final fechaSalida = DateTime.now();
      final tiempoEstacionamiento = fechaSalida.difference(
        placaActiva.fechaEntrada,
      );

      final tarifa = await _tarifaRepo.obtenerTarifaActiva();
      if (tarifa == null) {
        return {'exito': false, 'mensaje': 'No hay tarifa configurada'};
      }

      final totalPagar = tarifa.calcularPrecio(tiempoEstacionamiento);

      return {
        'exito': true,
        'tiempoEstacionamiento': tiempoEstacionamiento,
        'totalPagar': totalPagar,
        'tarifa': tarifa,
        'placa': placaActiva,
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al calcular precio: $e'};
    }
  }
}
