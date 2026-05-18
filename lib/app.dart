import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'routes.dart'; // <-- Importamos nuestro archivo de rutas

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Cambiamos de MaterialApp a MaterialApp.router
    return MaterialApp.router(
      title: 'ZAPATA POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Inyectamos la configuración de go_router
      routerConfig: appRouter,
    );
  }
}