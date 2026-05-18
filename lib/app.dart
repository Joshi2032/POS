import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'layout/main_layout.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart'; // <-- Importamos el nuevo cerebro del tema

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el proveedor del tema
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'ZAPATA POS',
      debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      
      // Aplicamos el modo según la variable del ThemeProvider
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: const MainLayout(),
    );
  }
}