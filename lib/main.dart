import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/theme_provider.dart'; // <-- Importamos el nuevo cerebro del tema

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // Inyectamos el ThemeProvider a nivel global para que cubra toda la app
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const App(),
    ),
  );
}