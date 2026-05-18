import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  // Helper para el título del AppBar en móviles
  String _getTitle() {
    switch (currentPath) {
      case '/dashboard': return 'Dashboard';
      case '/tomar-orden': return 'Tomar Orden';
      case '/caja': return 'Caja';
      case '/proveedores': return 'Proveedores';
      case '/ordenes': return 'Órdenes';
      case '/reservaciones': return 'Reservaciones';
      case '/productos': return 'Productos';
      case '/combos': return 'Combos';
      case '/recetas': return 'Recetas';
      case '/empleados': return 'Empleados';
      case '/inventario': return 'Inventario';
      case '/mesas': return 'Mesas';
      case '/reportes': return 'Reportes';
      case '/gastos': return 'Gastos';
      case '/nominas': return 'Nóminas';
      case '/historial-cortes': return 'Cortes de Caja';
      case '/ajustes': return 'Ajustes';
      default: return 'Zapata POS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final isMobile = MediaQuery.of(context).size.width < 900;

    Widget sidebar = CustomSidebar(
      currentPath: currentPath,
      onPathSelected: (String path) {
        context.go(path); // <-- Aquí usamos la magia del enrutador
        if (isMobile) Navigator.of(context).pop(); // Cierra el menú en móviles
      },
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: isMobile
          ? AppBar(
              title: Text(_getTitle()),
              elevation: 0,
              backgroundColor: Theme.of(context).cardColor,
            )
          : null,
      drawer: isMobile ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          if (!isMobile) sidebar,
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: child, // <-- El contenido inyectado por GoRouter
            ),
          ),
        ],
      ),
    );
  }
}