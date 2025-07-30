class AppConstants {
  // Rutas de navegación
  static const String homeRoute = '/';
  static const String registroPlacaRoute = '/registro-placa';
  static const String registroMensualRoute = '/registro-mensual';
  static const String configuracionRoute = '/configuracion';
  static const String configuracionTarifasRoute = '/configuracion-tarifas';
  static const String cierreDiaRoute = '/cierre-dia';

  // Nombres de la aplicación
  static const String appName = 'Parqueadero DV';
  static const String appTitle = 'Sistema de Parqueadero';

  // Tablas de base de datos
  static const String tablePlacaOcasional = 'placa_ocasional';
  static const String tablePlacaMensual = 'placa_mensual';
  static const String tableTarifa = 'tarifa';

  // Estados
  static const String estadoActiva = 'activa';
  static const String estadoCompletada = 'completada';
  static const String estadoCancelada = 'cancelada';
  static const String estadoInactiva = 'inactiva';

  // Configuración por defecto
  static const double valorPorHoraDefault = 2000.0;
  static const double valorPorMediaHoraDefault = 1000.0;
  static const double valorPorDiaDefault = 15000.0;
  static const double valorMensualidadDefault = 80000.0;

  // Configuración de impresión
  static const int paperSize = 80; // mm
  static const String printerName = 'Ticket Printer';

  // Configuración de PDF
  static const String pdfFileName = 'cierre_dia_';
}
