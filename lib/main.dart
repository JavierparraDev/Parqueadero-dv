import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_colors.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/registro_placa_screen.dart';
import 'presentation/screens/registro_mensual_screen.dart';
import 'presentation/screens/configuracion_tarifas_screen.dart';
import 'presentation/screens/cierre_dia_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      initialRoute: AppConstants.homeRoute,
      routes: {
        AppConstants.homeRoute: (context) => const HomeScreen(),
        AppConstants.registroPlacaRoute: (context) =>
            const RegistroPlacaScreen(),
        AppConstants.registroMensualRoute: (context) =>
            const RegistroMensualScreen(),
        AppConstants.configuracionTarifasRoute: (context) =>
            const ConfiguracionTarifasScreen(),
        AppConstants.cierreDiaRoute: (context) => const CierreDiaScreen(),
      },
    );
  }
}
