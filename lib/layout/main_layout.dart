import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../pages/dashboard_page.dart';
import '../pages/tomar_orden_page.dart';
import '../pages/productos_page.dart';
import '../pages/empleados_page.dart';
import '../pages/mesas_page.dart';
import '../pages/nominas_page.dart';
import '../pages/caja_page.dart';
import '../pages/gastos_page.dart';
import '../pages/inventario_page.dart';
import '../pages/ordenes_page.dart';
import '../pages/reservaciones_page.dart';
import '../pages/recetas_page.dart';
import '../pages/proveedores_page.dart'; 
import '../pages/combos_page.dart';
import '../pages/reportes_page.dart';
import '../pages/historial_cortes_page.dart';
import '../pages/ajustes_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentSection = 'Dashboard';

  Widget _getBodyWidget() {
    switch (_currentSection) {
      case 'Tomar Orden': return const TomarOrdenPage();
      case 'Caja': return const CajaPage();
      case 'Proveedores': return const ProveedoresPage();
      case 'Órdenes': return const OrdenesPage();
      case 'Reservaciones': return const ReservacionesPage();
      case 'Dashboard': return const DashboardPage();
      case 'Productos': return const ProductosPage();
      case 'Combos': return const CombosPage();
      case 'Recetas': return const RecetasPage();
      case 'Empleados': return const EmpleadosPage();
      case 'Inventario': return const InventarioPage();
      case 'Mesas': return const MesasPage();
      case 'Reportes': return const ReportesPage();
      case 'Gastos': return const GastosPage();
      case 'Nóminas': return const NominasPage();
      case 'Cortes de Caja': return const HistorialCortesPage();
      case 'Ajustes': return const AjustesPage();
      default: return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    // 1. Detectar si es móvil
    final isMobile = MediaQuery.of(context).size.width < 900;

    // 2. Instancia del sidebar
    Widget sidebar = CustomSidebar(
      currentSection: _currentSection,
      onSectionSelected: (String section) {
        setState(() {
          _currentSection = section;
        });
        // Si es móvil, cierra el menú lateral automáticamente al tocar una opción
        if (isMobile) Navigator.of(context).pop();
      },
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      // 3. AppBar con botón de menú solo en móviles
      appBar: isMobile
          ? AppBar(
              title: Text(_currentSection),
              elevation: 0,
              backgroundColor: Theme.of(context).cardColor,
            )
          : null,
      // 4. Drawer deslizable solo en móviles
      drawer: isMobile ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          // 5. Sidebar fijo solo en Escritorio/Tablet
          if (!isMobile) sidebar,
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: _getBodyWidget(),
            ),
          ),
        ],
      ),
    );
  }
}