import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../pages/dashboard_page.dart';
import '../pages/productos_page.dart';
import '../pages/combos_page.dart'; 
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

  final List<Widget> _pages = [
    const DashboardPage(),                       // 0
    const ProductosPage(),                       // 1
    const CombosPage(),                          // 2
    const Center(child: Text('Recetas Page')),   // 3
    const EmpleadosPage(),                       // 4
    const InventarioPage(),                      // 5
    const MesasPage(),                           // 6
    const ReportesPage(),                        // 7
    const GastosPage(),                          // 8
    const Center(child: Text('Nómina Page')),    // 9
    const Center(child: Text('Historial')),      // 10
    const Center(child: Text('Ajustes Page')),   // 11
    const TomarOrdenPage(),                      // 12
    const CajaPage(),                            // 13
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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