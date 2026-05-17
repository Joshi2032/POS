import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
// Importaciones de todas tus páginas del repositorio corregidas
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
import '../pages/proveedores_page.dart'; // Módulo de proveedores
import '../pages/combos_page.dart';
import '../pages/historial_cortes_page.dart';
import '../pages/ajustes_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Estado que controla qué página del POS se está visualizando actualmente
  String _currentSection = 'Dashboard';

  // Mapeador dinámico que inyecta la página correspondiente en el contenedor principal
  Widget _getBodyWidget() {
    switch (_currentSection) {
      case 'Dashboard':
        return const DashboardPage();
      case 'Tomar Orden':
        return const TomarOrdenPage();
      case 'Órdenes':
        return const OrdenesPage();
      case 'Productos':
        return const ProductosPage();
      case 'Combos':
        return const CombosPage();
      case 'Mesas':
        return const MesasPage();
      case 'Reservaciones':
        return const ReservacionesPage();
      case 'Empleados':
        return const EmpleadosPage();
      case 'Nóminas':
        return const NominasPage();
      case 'Caja':
        return const CajaPage();
      case 'Gastos':
        return const GastosPage();
      case 'Inventario':
        return const InventarioPage();
      case 'Recetas':
        return const RecetasPage();
      case 'Proveedores':
        return const ProveedoresPage(); // <-- CORREGIDO: Cambiado de ProvidersPage a ProveedoresPage
      case 'Cortes de Caja':
        return const HistorialCortesPage();
      case 'Ajustes':
        return const AjustesPage();
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hereda dinámicamente el color de fondo oficial de AppTheme (Claro u Oscuro)
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Row(
        children: [
          // Sidebar izquierdo pasando la sección activa y escuchando los eventos de click
          CustomSidebar(
            currentSection: _currentSection,
            onSectionSelected: (String section) {
              setState(() {
                _currentSection = section;
              });
            },
          ),
          
          // Contenedor principal de contenidos de la derecha
          Expanded(
            child: Container(
              color: Colors.transparent, // Permite visualizar el fondo del Scaffold subyacente
              child: _getBodyWidget(),
            ),
          ),
        ],
      ),
    );
  }
}