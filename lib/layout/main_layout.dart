import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../pages/dashboard_page.dart'; // Tu panel de métricas real
import '../pages/productos_page.dart';
import '../pages/tomar_orden_page.dart';
import '../pages/caja_page.dart';
import '../pages/inventario_page.dart';
import '../pages/mesas_page.dart';
import '../pages/empleados_page.dart';
import '../pages/gastos_page.dart';
import '../pages/reportes_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // El equivalente al <router-outlet>
  final List<Widget> _pages = [
    const DashboardPage(),                       // 0: AHORA SÍ ES EL DASHBOARD REAL
    const ProductosPage(),                       // 1: Productos
    const Center(child: Text('Combos Page')),    // 2: Combos
    const Center(child: Text('Recetas Page')),   // 3: Recetas
    const EmpleadosPage(),                       // 4: Empleados
    const InventarioPage(),                      // 5: Inventario
    const MesasPage(),                           // 6: Mesas
    const ReportesPage(),                        // 7: Reportes
    const GastosPage(),                          // 8: Gastos
    const Center(child: Text('Nómina Page')),    // 9: Nómina
    const Center(child: Text('Historial')),      // 10: Historial
    const Center(child: Text('Ajustes Page')),   // 11: Ajustes
    const TomarOrdenPage(),                      // 12: Tomar Orden
    const CajaPage(),                            // 13: Caja
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth <= 1024;

          if (isMobile) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('La Brasa POS'),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
              drawer: AppSidebar(
                currentIndex: _currentIndex,
                onIndexChanged: (index) {
                  setState(() => _currentIndex = index);
                  Navigator.pop(context); 
                },
              ),
              body: IndexedStack(index: _currentIndex, children: _pages),
            );
          } else {
            return Row(
              children: [
                SizedBox(
                  width: 260,
                  child: AppSidebar(
                    currentIndex: _currentIndex,
                    onIndexChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}