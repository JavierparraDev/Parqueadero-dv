import '../data/db/database_helper.dart';

class TarifaService {
  static final TarifaService _instance = TarifaService._internal();
  factory TarifaService() => _instance;
  TarifaService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Configuración de tarifas (valores por defecto)
  double _valorPorHora = 2000.0;
  double _valorPorMediaHora = 1000.0;
  double _valorPorDia = 15000.0;
  double _valorMensualidad = 80000.0;

  // Getters para acceder a los valores
  double get valorPorHora => _valorPorHora;
  double get valorPorMediaHora => _valorPorMediaHora;
  double get valorPorDia => _valorPorDia;
  double get valorMensualidad => _valorMensualidad;

  // Método para cargar configuración desde la base de datos
  Future<void> cargarConfiguracion() async {
    try {
      final tarifa = await _databaseHelper.obtenerTarifaActiva();
      if (tarifa != null) {
        _valorPorHora = tarifa['valorPorHora']?.toDouble() ?? 2000.0;
        _valorPorMediaHora = tarifa['valorPorMediaHora']?.toDouble() ?? 1000.0;
        _valorPorDia = tarifa['valorPorDia']?.toDouble() ?? 15000.0;
        _valorMensualidad = tarifa['valorMensualidad']?.toDouble() ?? 80000.0;
      }
    } catch (e) {
      // Si hay error, mantener valores por defecto
      print('Error cargando configuración: $e');
    }
  }

  // Método para actualizar la configuración
  Future<void> actualizarConfiguracion({
    required double valorPorHora,
    required double valorPorMediaHora,
    required double valorPorDia,
    required double valorMensualidad,
  }) async {
    // Actualizar valores en memoria
    _valorPorHora = valorPorHora;
    _valorPorMediaHora = valorPorMediaHora;
    _valorPorDia = valorPorDia;
    _valorMensualidad = valorMensualidad;

    // Guardar en base de datos
    await _databaseHelper.actualizarTarifa({
      'valorPorHora': valorPorHora,
      'valorPorMediaHora': valorPorMediaHora,
      'valorPorDia': valorPorDia,
      'valorMensualidad': valorMensualidad,
    });
  }

  // Método para calcular tarifa basado en tiempo
  double calcularTarifa(Duration tiempo) {
    final horas = tiempo.inHours;
    final minutos = tiempo.inMinutes % 60;
    final totalMinutos = tiempo.inMinutes;

    // Si es menos de 30 minutos, aplicar tarifa mínima
    if (totalMinutos <= 30) {
      return _valorPorMediaHora;
    }

    // Si es menos de 12 horas, calcular por hora
    if (horas < 12) {
      final tarifaPorHora = _valorPorHora;
      final horasCompletas = horas;
      final fraccionHora = minutos / 60.0;
      return (horasCompletas * tarifaPorHora) + (fraccionHora * tarifaPorHora);
    }

    // Si es 12 horas o más, aplicar nueva lógica de tarifas
    if (horas >= 12) {
      // Calcular ciclos de 12 horas
      final ciclosCompletos = horas ~/ 12;
      final horasRestantes = horas % 12;

      double tarifaTotal = 0.0;

      // Calcular tarifa por ciclos completos
      if (ciclosCompletos == 1) {
        // 12-24 horas: 1 tarifa por día
        tarifaTotal = _valorPorDia;
      } else if (ciclosCompletos == 2) {
        // 24-36 horas: 1 tarifa por día + horas adicionales
        tarifaTotal = _valorPorDia;
        if (horasRestantes > 0) {
          final fraccionHora = minutos / 60.0;
          tarifaTotal +=
              (horasRestantes * _valorPorHora) + (fraccionHora * _valorPorHora);
        }
      } else if (ciclosCompletos == 3) {
        // 36-48 horas: 2 tarifas por día
        tarifaTotal = 2 * _valorPorDia;
      } else if (ciclosCompletos == 4) {
        // 48-60 horas: 2 tarifas por día + horas adicionales
        tarifaTotal = 2 * _valorPorDia;
        if (horasRestantes > 0) {
          final fraccionHora = minutos / 60.0;
          tarifaTotal +=
              (horasRestantes * _valorPorHora) + (fraccionHora * _valorPorHora);
        }
      } else if (ciclosCompletos == 5) {
        // 60-72 horas: 3 tarifas por día
        tarifaTotal = 3 * _valorPorDia;
      } else {
        // Para ciclos mayores, calcular dinámicamente
        final diasCompletos =
            ciclosCompletos ~/ 2; // Cada 2 ciclos = 1 día extra
        final ciclosAdicionales = ciclosCompletos % 2;

        tarifaTotal = diasCompletos * _valorPorDia;

        if (ciclosAdicionales == 1) {
          // Ciclo impar: agregar horas adicionales
          if (horasRestantes > 0) {
            final fraccionHora = minutos / 60.0;
            tarifaTotal +=
                (horasRestantes * _valorPorHora) +
                (fraccionHora * _valorPorHora);
          }
        }
      }

      return tarifaTotal;
    }

    return 0.0; // Caso por defecto
  }

  // Método para obtener descripción de la tarifa aplicada
  String obtenerDescripcionTarifa(Duration tiempo) {
    final horas = tiempo.inHours;
    final minutos = tiempo.inMinutes % 60;
    final totalMinutos = tiempo.inMinutes;

    if (totalMinutos <= 30) {
      return 'Tarifa mínima (media hora)';
    }

    if (horas < 12) {
      return 'Tarifa por hora';
    }

    if (horas >= 12) {
      final ciclosCompletos = horas ~/ 12;
      final horasRestantes = horas % 12;

      if (ciclosCompletos == 1) {
        return 'Tarifa por día (12-24 horas)';
      } else if (ciclosCompletos == 2) {
        if (horasRestantes > 0) {
          return 'Tarifa por día + ${horasRestantes}h adicionales';
        } else {
          return 'Tarifa por día + horas adicionales';
        }
      } else if (ciclosCompletos == 3) {
        return 'Doble tarifa por día (36-48 horas)';
      } else if (ciclosCompletos == 4) {
        if (horasRestantes > 0) {
          return 'Doble tarifa por día + ${horasRestantes}h adicionales';
        } else {
          return 'Doble tarifa por día + horas adicionales';
        }
      } else if (ciclosCompletos == 5) {
        return 'Triple tarifa por día (60-72 horas)';
      } else {
        final diasCompletos = ciclosCompletos ~/ 2;
        final ciclosAdicionales = ciclosCompletos % 2;

        if (ciclosAdicionales == 1 && horasRestantes > 0) {
          return '${diasCompletos} días + ${horasRestantes}h adicionales';
        } else if (ciclosAdicionales == 1) {
          return '${diasCompletos} días + horas adicionales';
        } else {
          return '${diasCompletos} días completos';
        }
      }
    }

    return 'Tarifa por hora';
  }

  // Método para validar configuración
  Map<String, dynamic> validarConfiguracion({
    required double valorPorHora,
    required double valorPorMediaHora,
    required double valorPorDia,
    required double valorMensualidad,
  }) {
    final errores = <String>[];

    // Validar valores positivos
    if (valorPorHora <= 0) errores.add('El valor por hora debe ser mayor a 0');
    if (valorPorMediaHora <= 0)
      errores.add('El valor por media hora debe ser mayor a 0');
    if (valorPorDia <= 0) errores.add('El valor por día debe ser mayor a 0');
    if (valorMensualidad <= 0)
      errores.add('El valor de mensualidad debe ser mayor a 0');

    // Validar lógica básica de tarifas
    if (valorPorMediaHora >= valorPorHora) {
      errores.add('El valor por media hora debe ser menor al valor por hora');
    }

    // Removida la validación de que el día debe ser mayor a 24 veces la hora
    // Ahora el valor por día puede ser flexible según las necesidades del negocio

    if (valorPorDia >= valorMensualidad) {
      errores.add('El valor de mensualidad debe ser mayor al valor por día');
    }

    return {'esValida': errores.isEmpty, 'errores': errores};
  }

  // Método para obtener configuración actual
  Map<String, double> obtenerConfiguracion() {
    return {
      'valorPorHora': _valorPorHora,
      'valorPorMediaHora': _valorPorMediaHora,
      'valorPorDia': _valorPorDia,
      'valorMensualidad': _valorMensualidad,
    };
  }

  // Método para restaurar valores por defecto
  Future<void> restaurarValoresPorDefecto() async {
    _valorPorHora = 2000.0;
    _valorPorMediaHora = 1000.0;
    _valorPorDia = 15000.0;
    _valorMensualidad = 80000.0;

    // Guardar en base de datos
    await actualizarConfiguracion(
      valorPorHora: _valorPorHora,
      valorPorMediaHora: _valorPorMediaHora,
      valorPorDia: _valorPorDia,
      valorMensualidad: _valorMensualidad,
    );
  }
}
