class Tarifa {
  final int? id;
  final String nombre;
  final double precioPorHora;
  final double precioPorDia;
  final double precioPorMes;
  final bool activa;
  final DateTime fechaCreacion;
  final String? descripcion;

  Tarifa({
    this.id,
    required this.nombre,
    required this.precioPorHora,
    required this.precioPorDia,
    required this.precioPorMes,
    this.activa = true,
    DateTime? fechaCreacion,
    this.descripcion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Calcular precio por tiempo específico
  double calcularPrecio(Duration tiempo) {
    final horas = tiempo.inMinutes / 60.0;
    final dias = tiempo.inDays.toDouble();
    final meses = dias / 30.0;

    if (meses >= 1) {
      return precioPorMes * meses;
    } else if (dias >= 1) {
      return precioPorDia * dias;
    } else {
      return precioPorHora * horas;
    }
  }

  // Copiar con cambios
  Tarifa copyWith({
    int? id,
    String? nombre,
    double? precioPorHora,
    double? precioPorDia,
    double? precioPorMes,
    bool? activa,
    DateTime? fechaCreacion,
    String? descripcion,
  }) {
    return Tarifa(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precioPorHora: precioPorHora ?? this.precioPorHora,
      precioPorDia: precioPorDia ?? this.precioPorDia,
      precioPorMes: precioPorMes ?? this.precioPorMes,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  // Convertir a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precioPorHora': precioPorHora,
      'precioPorDia': precioPorDia,
      'precioPorMes': precioPorMes,
      'activa': activa ? 1 : 0,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
      'descripcion': descripcion,
    };
  }

  // Crear desde Map de base de datos
  factory Tarifa.fromMap(Map<String, dynamic> map) {
    return Tarifa(
      id: map['id'],
      nombre: map['nombre'],
      precioPorHora: map['precioPorHora'],
      precioPorDia: map['precioPorDia'],
      precioPorMes: map['precioPorMes'],
      activa: map['activa'] == 1,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fechaCreacion']),
      descripcion: map['descripcion'],
    );
  }
}
