class PlacaOcasional {
  final int? id;
  final String placa;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final double? tarifa;
  final double? totalPagar;
  final String? observaciones;
  final bool activo;

  PlacaOcasional({
    this.id,
    required this.placa,
    required this.fechaEntrada,
    this.fechaSalida,
    this.tarifa,
    this.totalPagar,
    this.observaciones,
    this.activo = true,
  });

  // Calcular tiempo de estacionamiento
  Duration? get tiempoEstacionamiento {
    if (fechaSalida == null) return null;
    return fechaSalida!.difference(fechaEntrada);
  }

  // Calcular horas de estacionamiento
  double? get horasEstacionamiento {
    final tiempo = tiempoEstacionamiento;
    if (tiempo == null) return null;
    return tiempo.inMinutes / 60.0;
  }

  // Verificar si está activo
  bool get estaActivo => activo && fechaSalida == null;

  // Copiar con cambios
  PlacaOcasional copyWith({
    int? id,
    String? placa,
    DateTime? fechaEntrada,
    DateTime? fechaSalida,
    double? tarifa,
    double? totalPagar,
    String? observaciones,
    bool? activo,
  }) {
    return PlacaOcasional(
      id: id ?? this.id,
      placa: placa ?? this.placa,
      fechaEntrada: fechaEntrada ?? this.fechaEntrada,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      tarifa: tarifa ?? this.tarifa,
      totalPagar: totalPagar ?? this.totalPagar,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
    );
  }

  // Convertir a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'placa': placa,
      'fechaEntrada': fechaEntrada.millisecondsSinceEpoch,
      'fechaSalida': fechaSalida?.millisecondsSinceEpoch,
      'tarifa': tarifa,
      'totalPagar': totalPagar,
      'observaciones': observaciones,
      'activo': activo ? 1 : 0,
    };
  }

  // Crear desde Map de base de datos
  factory PlacaOcasional.fromMap(Map<String, dynamic> map) {
    return PlacaOcasional(
      id: map['id'],
      placa: map['placa'],
      fechaEntrada: DateTime.fromMillisecondsSinceEpoch(map['fechaEntrada']),
      fechaSalida: map['fechaSalida'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaSalida'])
          : null,
      tarifa: map['tarifa'],
      totalPagar: map['totalPagar'],
      observaciones: map['observaciones'],
      activo: map['activo'] == 1,
    );
  }
}
