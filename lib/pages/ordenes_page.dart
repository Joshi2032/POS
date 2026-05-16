import 'package:flutter/material.dart';

class OrdenesPage extends StatelessWidget {
  const OrdenesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent, // Deja que el Dashboard maneje el fondo
      body: Center(
        child: Text('Contenido de Órdenes (Historial de Comandos)'),
      ),
    );
  }
}