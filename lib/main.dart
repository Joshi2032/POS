import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. Importamos el paquete Provider
import 'app.dart';
import 'state/app_state.dart';            // <-- 2. Importamos tu manejador de estado global

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de arrancar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Aquí puedes inicializar servicios como Supabase, SharedPreferences, etc.
  // await SupabaseService.initialize();

  runApp(
    // 3. Envolvemos la app con el Provider para que esté disponible en todas las páginas
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const App(),
    ),
  );
}