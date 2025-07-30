import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/db/database_helper.dart';
import '../../services/tarifa_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RegistroMensualScreen extends StatefulWidget {
  const RegistroMensualScreen({super.key});

  @override
  State<RegistroMensualScreen> createState() => _RegistroMensualScreenState();
}

class _RegistroMensualScreenState extends State<RegistroMensualScreen> {
  final TextEditingController _placaController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isLoading = false;
  String? _mensaje;
  bool _esExito = false;

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TarifaService _tarifaService = TarifaService();
  List<Map<String, dynamic>> _mensualidadesActivas = [];

  @override
  void initState() {
    super.initState();
    _cargarMensualidadesActivas();
  }

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _cargarMensualidadesActivas() async {
    try {
      final mensualidades = await _databaseHelper
          .obtenerPlacasMensualesActivas();
      setState(() {
        _mensualidadesActivas = mensualidades;
      });
    } catch (e) {
      _mostrarMensaje('Error cargando mensualidades: $e', false);
    }
  }

  void _mostrarMensaje(String mensaje, bool esExito) {
    setState(() {
      _mensaje = mensaje;
      _esExito = esExito;
    });
  }

  bool _validarFormatoPlaca(String placa) {
    // Validar formato: 3 letras + 2 números + 1 carácter opcional
    final regex = RegExp(r'^[A-Z]{3}\d{2}[A-Z0-9]?$');
    return regex.hasMatch(placa.toUpperCase());
  }

  Future<void> _seleccionarFechaInicio() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaInicio = fechaSeleccionada;
        // Calcular fecha de fin (exactamente 1 mes después)
        _fechaFin = DateTime(
          fechaSeleccionada.year,
          fechaSeleccionada.month + 1,
          fechaSeleccionada.day,
        );
      });
    }
  }

  Future<void> _registrarMensualidad() async {
    // Validar campos obligatorios
    if (_placaController.text.isEmpty || _fechaInicio == null) {
      _mostrarMensaje(
        'Por favor complete todos los campos obligatorios',
        false,
      );
      return;
    }

    // Validar formato de placa
    if (!_validarFormatoPlaca(_placaController.text)) {
      _mostrarMensaje(
        'Formato de placa inválido. Use: 3 letras + 2 números + 1 carácter opcional\nEjemplo: CFD45H',
        false,
      );
      return;
    }

    // Verificar si la placa ya tiene una mensualidad activa
    final placaExistente = await _databaseHelper.obtenerPlacaMensualPorPlaca(
      _placaController.text.toUpperCase(),
    );

    if (placaExistente != null) {
      _mostrarMensaje('Esta placa ya tiene una mensualidad activa', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _mensaje = null;
    });

    try {
      // Obtener valor de mensualidad del servicio
      await _tarifaService.cargarConfiguracion();
      final valorMensualidad = _tarifaService.valorMensualidad;

      // Crear registro de mensualidad
      final mensualidad = {
        'placa': _placaController.text.toUpperCase(),
        'fechaInicio': _fechaInicio!.toIso8601String(),
        'fechaFin': _fechaFin!.toIso8601String(),
        'estado': 'activa',
        'valorMensualidad': valorMensualidad,
      };

      // Guardar en base de datos
      await _databaseHelper.insert('placa_mensual', mensualidad);

      // Limpiar formulario
      _placaController.clear();
      setState(() {
        _fechaInicio = null;
        _fechaFin = null;
      });

      // Recargar lista
      await _cargarMensualidadesActivas();

      setState(() {
        _isLoading = false;
        _mensaje = 'Mensualidad registrada exitosamente';
        _esExito = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensaje = 'Error registrando mensualidad: $e';
        _esExito = false;
      });
    }
  }

  Future<void> _cancelarMensualidad(int id) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Mensualidad'),
        content: const Text(
          '¿Está seguro de que desea cancelar esta mensualidad?',
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
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        await _databaseHelper.update(
          'placa_mensual',
          {'estado': 'cancelada'},
          where: 'id = ?',
          whereArgs: [id],
        );

        await _cargarMensualidadesActivas();
        _mostrarMensaje('Mensualidad cancelada exitosamente', true);
      } catch (e) {
        _mostrarMensaje('Error cancelando mensualidad: $e', false);
      }
    }
  }

  void _mostrarMensualidadesActivas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.list, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Mensualidades Activas'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: _mensualidadesActivas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay mensualidades activas',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _mensualidadesActivas.length,
                  itemBuilder: (context, index) {
                    final mensualidad = _mensualidadesActivas[index];
                    final fechaInicio = DateTime.parse(
                      mensualidad['fechaInicio'],
                    );
                    final fechaFin = DateTime.parse(mensualidad['fechaFin']);
                    final valorMensualidad =
                        mensualidad['valorMensualidad'] as double;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            mensualidad['placa'][0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          mensualidad['placa'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inicio: ${DateFormat('dd/MM/yyyy').format(fechaInicio)}',
                            ),
                            Text(
                              'Fin: ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
                            ),
                            Text(
                              'Valor: \$${valorMensualidad.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          onPressed: () =>
                              _cancelarMensualidad(mensualidad['id']),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Cancelar mensualidad',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Mensualidades'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Placa
            CustomTextField(
              controller: _placaController,
              labelText: 'Placa *',
              hintText: 'Ej: CFD45H',
              onChanged: (value) {
                // Auto-uppercase
                if (value.isNotEmpty) {
                  _placaController.text = value.toUpperCase();
                  _placaController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _placaController.text.length),
                  );
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La placa es obligatoria';
                }
                if (!_validarFormatoPlaca(value)) {
                  return 'Formato inválido: 3 letras + 2 números + 1 carácter opcional';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fecha de inicio
            Card(
              child: InkWell(
                onTap: _seleccionarFechaInicio,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha de Inicio *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fechaInicio != null
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaInicio!)
                                  : 'Seleccionar fecha',
                              style: TextStyle(
                                color: _fechaInicio != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fecha de fin (automática)
            if (_fechaFin != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.event_available, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha de Fin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_fechaFin!),
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Botón registrar
            CustomButton(
              onPressed: _isLoading ? null : _registrarMensualidad,
              text: 'Registrar Mensualidad',
              backgroundColor: AppColors.success,
              isLoading: _isLoading,
              icon: Icons.add,
            ),
            const SizedBox(height: 16),

            // Botón ver mensualidades activas
            CustomButton(
              onPressed: _mostrarMensualidadesActivas,
              text: 'Ver Mensualidades Activas',
              backgroundColor: AppColors.info,
              icon: Icons.list,
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
          ],
        ),
      ),
    );
  }
}
