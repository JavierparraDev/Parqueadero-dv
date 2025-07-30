import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/db/database_helper.dart';
import '../widgets/custom_button.dart';

class CierreDiaScreen extends StatefulWidget {
  const CierreDiaScreen({super.key});

  @override
  State<CierreDiaScreen> createState() => _CierreDiaScreenState();
}

class _CierreDiaScreenState extends State<CierreDiaScreen> {
  bool _isLoading = false;
  String? _mensaje;
  bool _esExito = false;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Estadísticas del día
  int _totalPlacasRegistradas = 0;
  int _totalPlacasCompletadas = 0;
  double _totalGanancias = 0.0;
  List<Map<String, dynamic>> _placasDelDia = [];

  @override
  void initState() {
    super.initState();
    _cargarEstadisticasDelDia();
  }

  Future<void> _cargarEstadisticasDelDia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener todas las placas del día
      final placas = await _databaseHelper.obtenerPlacasOcasionalesDelDia();

      // Calcular estadísticas
      int totalRegistradas = 0;
      int totalCompletadas = 0;
      double totalGanancias = 0.0;

      for (final placa in placas) {
        totalRegistradas++;

        if (placa['estado'] == 'completada') {
          totalCompletadas++;
          totalGanancias += (placa['totalPagar'] as double?) ?? 0.0;
        }
      }

      setState(() {
        _totalPlacasRegistradas = totalRegistradas;
        _totalPlacasCompletadas = totalCompletadas;
        _totalGanancias = totalGanancias;
        _placasDelDia = placas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensaje = 'Error cargando estadísticas: $e';
        _esExito = false;
      });
    }
  }

  void _mostrarMensaje(String mensaje, bool esExito) {
    setState(() {
      _mensaje = mensaje;
      _esExito = esExito;
    });
  }

  Future<void> _realizarCierreDia() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cierre del Día'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Está seguro de que desea realizar el cierre del día?'),
            const SizedBox(height: 8),
            Text('Placas registradas: $_totalPlacasRegistradas'),
            Text('Placas completadas: $_totalPlacasCompletadas'),
            Text('Total ganancias: \$${_totalGanancias.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            const Text(
              'Esta acción marcará todas las placas activas como inactivas.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Cierre'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      setState(() {
        _isLoading = true;
        _mensaje = null;
      });

      try {
        // Realizar cierre del día
        await _databaseHelper.limpiarRegistrosDelDia();

        // Recargar estadísticas
        await _cargarEstadisticasDelDia();

        setState(() {
          _isLoading = false;
          _mensaje = 'Cierre del día realizado exitosamente';
          _esExito = true;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _mensaje = 'Error realizando cierre del día: $e';
          _esExito = false;
        });
      }
    }
  }

  void _mostrarDetallePlacas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.list, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Detalle del Día'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: _placasDelDia.isEmpty
              ? const Center(
                  child: Text(
                    'No hay placas registradas hoy',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _placasDelDia.length,
                  itemBuilder: (context, index) {
                    final placa = _placasDelDia[index];
                    final fechaEntrada = DateTime.parse(placa['fechaEntrada']);
                    final estado = placa['estado'] as String;
                    final totalPagar = placa['totalPagar'] as double?;
                    final fechaSalida = placa['fechaSalida'] != null
                        ? DateTime.parse(placa['fechaSalida'])
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: estado == 'activa'
                              ? Colors.green
                              : Colors.grey,
                          child: Text(
                            placa['placa'][0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          placa['placa'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrada: ${DateFormat('HH:mm').format(fechaEntrada)}',
                            ),
                            if (fechaSalida != null)
                              Text(
                                'Salida: ${DateFormat('HH:mm').format(fechaSalida)}',
                              ),
                            Text(
                              'Estado: ${estado == 'activa' ? 'Activa' : 'Completada'}',
                            ),
                            if (totalPagar != null)
                              Text(
                                'Total: \$${totalPagar.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generarPDF() async {
    // TODO: Implementar generación de PDF
    // Por ahora mostrar mensaje
    _mostrarMensaje('Funcionalidad de PDF en desarrollo', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre del Día'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Resumen del día
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assessment, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Resumen del Día',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placas registradas: $_totalPlacasRegistradas',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placas completadas: $_totalPlacasCompletadas',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total ganancias: \$${_totalGanancias.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            CustomButton(
              onPressed: _isLoading ? null : _mostrarDetallePlacas,
              text: 'Ver Detalle de Placas',
              backgroundColor: AppColors.info,
              icon: Icons.list,
            ),
            const SizedBox(height: 12),

            CustomButton(
              onPressed: _isLoading ? null : _generarPDF,
              text: 'Descargar PDF',
              backgroundColor: AppColors.warning,
              icon: Icons.download,
            ),
            const SizedBox(height: 12),

            CustomButton(
              onPressed: _isLoading ? null : _realizarCierreDia,
              text: 'Realizar Cierre del Día',
              backgroundColor: AppColors.error,
              isLoading: _isLoading,
              icon: Icons.close,
            ),

            const SizedBox(height: 16),

            // Mensaje de estado
            if (_mensaje != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _esExito
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _esExito ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Text(
                  _mensaje!,
                  style: TextStyle(
                    color: _esExito ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Información adicional
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Información del Cierre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• El cierre del día marcará todas las placas activas como inactivas\n'
                      '• Las ganancias se calculan solo de las placas completadas\n'
                      '• Puede descargar un reporte en PDF con todos los detalles\n'
                      '• Se recomienda realizar el cierre al final del día laboral',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
