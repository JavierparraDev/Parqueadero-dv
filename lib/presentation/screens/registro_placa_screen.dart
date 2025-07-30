import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/db/database_helper.dart';
import '../../services/tarifa_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RegistroPlacaScreen extends StatefulWidget {
  const RegistroPlacaScreen({super.key});

  @override
  State<RegistroPlacaScreen> createState() => _RegistroPlacaScreenState();
}

class _RegistroPlacaScreenState extends State<RegistroPlacaScreen> {
  final TextEditingController _placaController = TextEditingController();
  bool _dejaCasco = false;
  int _cantidadCascos = 0;
  bool _isLoading = false;
  String? _mensaje;
  bool _esExito = false;

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TarifaService _tarifaService = TarifaService();
  List<Map<String, dynamic>> _placasRegistradas = [];

  @override
  void initState() {
    super.initState();
    _cargarPlacasRegistradas();
  }

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPlacasRegistradas() async {
    try {
      final placas = await _databaseHelper.obtenerPlacasOcasionalesDelDia();
      setState(() {
        _placasRegistradas = placas;
      });
    } catch (e) {
      _mostrarMensaje('Error cargando placas: $e', false);
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

  void _mostrarDialogoCascos() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Gestión de Cascos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Deja casco:'),
                  const SizedBox(width: 16),
                  Switch(
                    value: _dejaCasco,
                    onChanged: (value) {
                      setStateDialog(() {
                        _dejaCasco = value;
                        if (!value) _cantidadCascos = 0;
                      });
                    },
                  ),
                ],
              ),
              if (_dejaCasco) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Cantidad:'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            _cantidadCascos = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Actualizar estado en la pantalla principal
                });
                Navigator.of(context).pop();
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarEntrada() async {
    if (_placaController.text.isEmpty) {
      _mostrarMensaje('Por favor ingrese la placa', false);
      return;
    }

    if (!_validarFormatoPlaca(_placaController.text)) {
      _mostrarMensaje(
        'Formato de placa inválido. Use: 3 letras + 2 números + 1 carácter opcional\nEjemplo: CFD45H',
        false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _mensaje = null;
    });

    try {
      // Verificar si la placa ya está registrada como activa
      final placaExistente = await _databaseHelper
          .obtenerPlacaOcasionalPorPlaca(_placaController.text.toUpperCase());

      if (placaExistente != null) {
        _mostrarMensaje('Esta placa ya está registrada como activa', false);
        return;
      }

      // Verificar si tiene mensualidad activa
      final mensualidadExistente = await _databaseHelper
          .obtenerPlacaMensualPorPlaca(_placaController.text.toUpperCase());

      if (mensualidadExistente != null) {
        _mostrarMensaje('Esta placa tiene una mensualidad activa', false);
        return;
      }

      // Crear registro de entrada
      final entrada = {
        'placa': _placaController.text.toUpperCase(),
        'fechaEntrada': DateTime.now().toIso8601String(),
        'estado': 'activa',
        'dejaCasco': _dejaCasco ? 1 : 0,
        'cantidadCascos': _cantidadCascos,
        'observaciones': _dejaCasco ? 'Deja ${_cantidadCascos} casco(s)' : null,
      };

      // Guardar en base de datos
      await _databaseHelper.insert('placa_ocasional', entrada);

      // Limpiar formulario
      _placaController.clear();
      setState(() {
        _dejaCasco = false;
        _cantidadCascos = 0;
      });

      // Recargar lista
      await _cargarPlacasRegistradas();

      setState(() {
        _isLoading = false;
        _mensaje = 'Entrada registrada exitosamente';
        _esExito = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensaje = 'Error registrando entrada: $e';
        _esExito = false;
      });
    }
  }

  Future<void> _registrarSalida() async {
    if (_placaController.text.isEmpty) {
      _mostrarMensaje('Por favor ingrese la placa', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _mensaje = null;
    });

    try {
      // Buscar la placa activa
      final placa = await _databaseHelper.obtenerPlacaOcasionalPorPlaca(
        _placaController.text.toUpperCase(),
      );

      if (placa == null) {
        _mostrarMensaje(
          'No se encontró una entrada activa para esta placa',
          false,
        );
        return;
      }

      // Calcular tiempo de estancia
      final fechaEntrada = DateTime.parse(placa['fechaEntrada']);
      final fechaSalida = DateTime.now();
      final tiempoEstancia = fechaSalida.difference(fechaEntrada);

      // Calcular tarifa
      await _tarifaService.cargarConfiguracion();
      final totalPagar = _tarifaService.calcularTarifa(tiempoEstancia);
      final descripcionTarifa = _tarifaService.obtenerDescripcionTarifa(
        tiempoEstancia,
      );

      // Mostrar diálogo de confirmación de pago
      final confirmacion = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Salida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${placa['placa']}'),
              Text(
                'Entrada: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaEntrada)}',
              ),
              Text(
                'Salida: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaSalida)}',
              ),
              Text(
                'Tiempo: ${tiempoEstancia.inHours}h ${tiempoEstancia.inMinutes % 60}min',
              ),
              const SizedBox(height: 8),
              Text('Tarifa: $descripcionTarifa'),
              Text(
                'Total a pagar: \$${totalPagar.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
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
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Pago'),
            ),
          ],
        ),
      );

      if (confirmacion == true) {
        // Actualizar registro con salida
        await _databaseHelper.update(
          'placa_ocasional',
          {
            'fechaSalida': fechaSalida.toIso8601String(),
            'totalPagar': totalPagar,
            'estado': 'completada',
          },
          where: 'id = ?',
          whereArgs: [placa['id']],
        );

        // Limpiar formulario
        _placaController.clear();

        // Recargar lista
        await _cargarPlacasRegistradas();

        setState(() {
          _isLoading = false;
          _mensaje = 'Salida registrada exitosamente';
          _esExito = true;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensaje = 'Error registrando salida: $e';
        _esExito = false;
      });
    }
  }

  void _mostrarPlacasRegistradas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Placas Registradas Hoy'),
        content: SizedBox(
          width: double.maxFinite,
          child: _placasRegistradas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay placas registradas hoy',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placasRegistradas.length,
                  itemBuilder: (context, index) {
                    final placa = _placasRegistradas[index];
                    final fechaEntrada = DateTime.parse(placa['fechaEntrada']);
                    final estado = placa['estado'] as String;

                    return ListTile(
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
                      subtitle: Text(
                        'Entrada: ${DateFormat('HH:mm').format(fechaEntrada)}\n'
                        'Estado: ${estado == 'activa' ? 'Activa' : 'Completada'}',
                      ),
                      trailing: estado == 'activa'
                          ? IconButton(
                              onPressed: () {
                                _placaController.text = placa['placa'];
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(
                                Icons.exit_to_app,
                                color: Colors.orange,
                              ),
                              tooltip: 'Seleccionar para salida',
                            )
                          : const Icon(Icons.check_circle, color: Colors.grey),
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
        title: const Text('Registro de Placas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo de placa
            CustomTextField(
              controller: _placaController,
              labelText: 'Placa',
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

            // Gestión de cascos
            Card(
              child: InkWell(
                onTap: _mostrarDialogoCascos,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _dejaCasco
                            ? Icons.motorcycle
                            : Icons.motorcycle_outlined,
                        color: _dejaCasco ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gestión de Cascos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dejaCasco
                                  ? 'Deja ${_cantidadCascos} casco(s)'
                                  : 'No deja casco',
                              style: TextStyle(
                                color: _dejaCasco ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Column(
              children: [
                CustomButton(
                  onPressed: _isLoading ? null : _registrarEntrada,
                  text: 'Registrar Entrada',
                  backgroundColor: AppColors.success,
                  isLoading: _isLoading,
                  icon: Icons.login,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onPressed: _isLoading ? null : _registrarSalida,
                  text: 'Registrar Salida',
                  backgroundColor: AppColors.warning,
                  isLoading: _isLoading,
                  icon: Icons.logout,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onPressed: _isLoading ? null : _mostrarPlacasRegistradas,
                  text: 'Ver Placas Registradas',
                  backgroundColor: AppColors.info,
                  icon: Icons.list,
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
          ],
        ),
      ),
    );
  }
}
