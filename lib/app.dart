import 'package:flutter/material.dart';
import 'layout/main_layout.dart';
import 'theme/app_theme.dart';

// Definición del notificador global para el tema
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'ZAPATA POS',
          debugShowCheckedModeBanner: false,
          
          // Configuración de tus temas (Claro y Oscuro)
          theme: AppTheme.lightTheme(),
          darkTheme: ThemeData.dark().copyWith(
            // Aquí puedes extender el tema oscuro usando tus constantes de AppTheme si lo deseas
          ),
          themeMode: currentMode,
          
          // Apunta al nuevo MainLayout que creamos como contenedor principal
          home: const MainLayout(),
        );
      },
    );
  }
}