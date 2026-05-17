import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Asegúrate de importar Provider
import 'layout/main_layout.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart'; // 2. Importa tu AppState

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Escucha activamente los cambios de tu AppState global
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'ZAPATA POS',
      debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      
      // 4. Vincula el modo directamente al estado de tu Provider
      themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: const MainLayout(),
    );
  }
}