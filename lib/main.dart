import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de arrancar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Aquí puedes inicializar servicios como Supabase, SharedPreferences, etc.
  // await SupabaseService.initialize();

  runApp(const App());
}