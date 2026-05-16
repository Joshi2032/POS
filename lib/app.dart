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
          
          // ¡Aquí conectamos tus dos paletas idénticas a Angular!
          theme: AppTheme.lightTheme(), 
          darkTheme: AppTheme.darkTheme(), 
          themeMode: currentMode, 
          
          home: const MainLayout(),
        );
      },
    );
  }
}