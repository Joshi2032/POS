import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/dashboard_page.dart';
import 'pages/tomar_orden_page.dart'; // Tu lógica de ordenes reactiva ya importada

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zapata POS',
      debugShowCheckedModeBanner: false,
      // Configuración de paleta de colores corporativos del SCSS de tu web
      theme: ThemeData(
        primaryColor: const Color(0xFF6366F1), // var(--accent-primary) Índigo elegante
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899), // var(--accent-secondary) Rosa
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}