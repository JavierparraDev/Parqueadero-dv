import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Parqueadero'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            // Logo o título principal
            const Icon(Icons.local_parking, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Sistema de Parqueadero',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestión integral de vehículos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),

            // Botones de navegación
            _buildMenuCard(
              context,
              icon: Icons.directions_car,
              title: 'Registro de Placas',
              subtitle: 'Entrada y salida de vehículos',
              color: AppColors.success,
              onTap: () =>
                  Navigator.pushNamed(context, AppConstants.registroPlacaRoute),
            ),
            const SizedBox(height: 16),

            _buildMenuCard(
              context,
              icon: Icons.people,
              title: 'Placas Mensuales',
              subtitle: 'Gestión de abonos mensuales',
              color: AppColors.info,
              onTap: () => Navigator.pushNamed(
                context,
                AppConstants.registroMensualRoute,
              ),
            ),
            const SizedBox(height: 16),

            _buildMenuCard(
              context,
              icon: Icons.settings,
              title: 'Configuración',
              subtitle: 'Tarifas y configuración del sistema',
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(
                context,
                AppConstants.configuracionTarifasRoute,
              ),
            ),
            const SizedBox(height: 16),

            _buildMenuCard(
              context,
              icon: Icons.assessment,
              title: 'Cierre del Día',
              subtitle: 'Reportes y estadísticas',
              color: AppColors.primary,
              onTap: () =>
                  Navigator.pushNamed(context, AppConstants.cierreDiaRoute),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textLight,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
