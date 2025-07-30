import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/tarifa_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ConfiguracionTarifasScreen extends StatefulWidget {
  const ConfiguracionTarifasScreen({super.key});

  @override
  State<ConfiguracionTarifasScreen> createState() =>
      _ConfiguracionTarifasScreenState();
}

class _ConfiguracionTarifasScreenState
    extends State<ConfiguracionTarifasScreen> {
  final TextEditingController _valorPorHoraController = TextEditingController();
  final TextEditingController _valorPorMediaHoraController =
      TextEditingController();
  final TextEditingController _valorPorDiaController = TextEditingController();
  final TextEditingController _valorMensualidadController =
      TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;
  String? _mensaje;
  bool _esExito = false;

  final TarifaService _tarifaService = TarifaService();

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _valorPorHoraController.dispose();
    _valorPorMediaHoraController.dispose();
    _valorPorDiaController.dispose();
    _valorMensualidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Cargar configuración desde la base de datos
      await _tarifaService.cargarConfiguracion();

      final configuracion = _tarifaService.obtenerConfiguracion();

      _valorPorHoraController.text = configuracion['valorPorHora'].toString();
      _valorPorMediaHoraController.text = configuracion['valorPorMediaHora']
          .toString();
      _valorPorDiaController.text = configuracion['valorPorDia'].toString();
      _valorMensualidadController.text = configuracion['valorMensualidad']
          .toString();
    } catch (e) {
      _mostrarMensaje('Error cargando configuración: $e', false);
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _mostrarMensaje(String mensaje, bool esExito) {
    setState(() {
      _mensaje = mensaje;
      _esExito = esExito;
    });
  }

  Future<void> _guardarConfiguracion() async {
    // Validar que todos los campos tengan valores válidos
    if (_valorPorHoraController.text.isEmpty ||
        _valorPorMediaHoraController.text.isEmpty ||
        _valorPorDiaController.text.isEmpty ||
        _valorMensualidadController.text.isEmpty) {
      _mostrarMensaje('Por favor complete todos los campos', false);
      return;
    }

    try {
      final valorPorHora = double.parse(_valorPorHoraController.text);
      final valorPorMediaHora = double.parse(_valorPorMediaHoraController.text);
      final valorPorDia = double.parse(_valorPorDiaController.text);
      final valorMensualidad = double.parse(_valorMensualidadController.text);

      // Validar configuración usando el servicio
      final validacion = _tarifaService.validarConfiguracion(
        valorPorHora: valorPorHora,
        valorPorMediaHora: valorPorMediaHora,
        valorPorDia: valorPorDia,
        valorMensualidad: valorMensualidad,
      );

      if (!validacion['esValida']) {
        final errores = validacion['errores'] as List<String>;
        _mostrarMensaje(errores.join('\n'), false);
        return;
      }

      setState(() {
        _isLoading = true;
        _mensaje = null;
      });

      // Guardar configuración en la base de datos
      await _tarifaService.actualizarConfiguracion(
        valorPorHora: valorPorHora,
        valorPorMediaHora: valorPorMediaHora,
        valorPorDia: valorPorDia,
        valorMensualidad: valorMensualidad,
      );

      setState(() {
        _isLoading = false;
        _mensaje = 'Configuración guardada exitosamente';
        _esExito = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensaje = 'Error: Ingrese valores numéricos válidos';
        _esExito = false;
      });
    }
  }

  Future<void> _restaurarValoresPorDefecto() async {
    setState(() {
      _isLoading = true;
      _mensaje = null;
    });

    try {
      await _tarifaService.restaurarValoresPorDefecto();
      await _cargarConfiguracion();
      _mostrarMensaje('Valores restaurados por defecto', true);
    } catch (e) {
      _mostrarMensaje('Error restaurando valores: $e', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Tarifas'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Tarifas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campos de configuración
            _buildTarifaCard(
              'Valor por Hora',
              'Tarifa por cada hora de estacionamiento',
              _valorPorHoraController,
              Icons.access_time,
              'Ej: 2000',
            ),
            const SizedBox(height: 16),

            _buildTarifaCard(
              'Valor por Media Hora',
              'Tarifa mínima para estancias cortas',
              _valorPorMediaHoraController,
              Icons.timer,
              'Ej: 1000',
            ),
            const SizedBox(height: 16),

            _buildTarifaCard(
              'Valor por Día',
              'Tarifa completa por día (se aplica desde 12 horas)',
              _valorPorDiaController,
              Icons.calendar_today,
              'Ej: 15000',
            ),
            const SizedBox(height: 16),

            _buildTarifaCard(
              'Valor Mensualidad',
              'Tarifa mensual para suscriptores',
              _valorMensualidadController,
              Icons.calendar_month,
              'Ej: 80000',
            ),
            const SizedBox(height: 24),

            // Información de lógica de tarifas
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Lógica de Tarifas por Ciclos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• ≤ 30 min: Tarifa mínima\n'
                      '• 30 min - 12 horas: Tarifa por hora\n'
                      '• 12-24 horas: 1 tarifa por día\n'
                      '• 24-36 horas: 1 día + horas adicionales\n'
                      '• 36-48 horas: 2 tarifas por día\n'
                      '• 48-60 horas: 2 días + horas adicionales\n'
                      '• 60+ horas: 3+ tarifas por día',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ejemplo: 30 horas = 1 día + 6 horas por tarifa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: _isLoading ? null : _restaurarValoresPorDefecto,
                    text: 'Restaurar',
                    backgroundColor: Colors.grey,
                    icon: Icons.restore,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    onPressed: _isLoading ? null : _guardarConfiguracion,
                    text: 'Guardar',
                    backgroundColor: AppColors.success,
                    isLoading: _isLoading,
                    icon: Icons.save,
                  ),
                ),
              ],
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

            const SizedBox(height: 24), // Espacio adicional al final
          ],
        ),
      ),
    );
  }

  Widget _buildTarifaCard(
    String titulo,
    String descripcion,
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              descripcion,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: controller,
              labelText: 'Valor',
              hintText: hint,
              keyboardType: TextInputType.number,
              suffixIcon: const Text('\$'),
            ),
          ],
        ),
      ),
    );
  }
}
