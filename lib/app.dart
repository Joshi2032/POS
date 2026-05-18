import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'routes.dart'; // Importamos el archivo central de rutas

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Cambiamos a MaterialApp.router para que GoRouter tome el control del ciclo de vida
    return MaterialApp.router(
      title: 'ZAPATA POS',
      debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Vinculamos de manera nativa la configuración de tu routes.dart
      routerConfig: appRouter,
    );
  }
}