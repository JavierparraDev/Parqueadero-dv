class PlacaMensual {
  final int? id;
  final String placa;
  final String propietario;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double tarifaMensual;
  final String? telefono;
  final String? email;
  final String? direccion;
  final bool activo;
  final DateTime fechaCreacion;

  PlacaMensual({
    this.id,
    required this.placa,
    required this.propietario,
    required this.fechaInicio,
    required this.fechaFin,
    required this.tarifaMensual,
    this.telefono,
    this.email,
    this.direccion,
    this.activo = true,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Verificar si el plan está vigente
  bool get estaVigente {
    final ahora = DateTime.now();
    return activo && ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
  }

  // Días restantes del plan
  int get diasRestantes {
    final ahora = DateTime.now();
    if (!estaVigente) return 0;
    return fechaFin.difference(ahora).inDays;
  }

  // Copiar con cambios
  PlacaMensual copyWith({
    int? id,
    String? placa,
    String? propietario,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? tarifaMensual,
    String? telefono,
    String? email,
    String? direccion,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return PlacaMensual(
      id: id ?? this.id,
      placa: placa ?? this.placa,
      propietario: propietario ?? this.propietario,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      tarifaMensual: tarifaMensual ?? this.tarifaMensual,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  // Convertir a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'placa': placa,
      'propietario': propietario,
      'fechaInicio': fechaInicio.millisecondsSinceEpoch,
      'fechaFin': fechaFin.millisecondsSinceEpoch,
      'tarifaMensual': tarifaMensual,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'activo': activo ? 1 : 0,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
    };
  }

  // Crear desde Map de base de datos
  factory PlacaMensual.fromMap(Map<String, dynamic> map) {
    return PlacaMensual(
      id: map['id'],
      placa: map['placa'],
      propietario: map['propietario'],
      fechaInicio: DateTime.fromMillisecondsSinceEpoch(map['fechaInicio']),
      fechaFin: DateTime.fromMillisecondsSinceEpoch(map['fechaFin']),
      tarifaMensual: map['tarifaMensual'],
      telefono: map['telefono'],
      email: map['email'],
      direccion: map['direccion'],
      activo: map['activo'] == 1,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fechaCreacion']),
    );
  }
}
