import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'tomar_orden_page.dart';
import 'caja_page.dart';
import 'inventario_page.dart';
import 'mesas_page.dart';
import 'productos_page.dart';
import 'empleados_page.dart';
import 'gastos_page.dart';
import 'reportes_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // Lista de todas las páginas del POS sincronizadas con el menú lateral
  final List<Widget> _pages = [
    const TomarOrdenPage(),
    const CajaPage(),
    const MesasPage(),
    const ProductosPage(),
    const InventarioPage(),
    const EmpleadosPage(),
    const GastosPage(),
    const ReportesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // var(--bg-primary) de Angular
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth <= 1024;

          if (isMobile) {
            // Diseño para dispositivos móviles (Con Drawer y BottomNavigationBar)
            return Scaffold(
              appBar: AppBar(
                title: const Text('ZAPATA POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              drawer: AppSidebar(
                currentIndex: _currentIndex,
                onIndexChanged: (index) {
                  setState(() => _currentIndex = index);
                  Navigator.pop(context); // Cierra el drawer
                },
              ),
              body: IndexedStack(index: _currentIndex, children: _pages),
            );
          } else {
            // Diseño Desktop / Tablet Horizontal IGUAL a la UI de Angular
            return Row(
              children: [
                // Barra de navegación lateral fija estilo Web
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
                // Contenedor principal de las páginas del punto de venta
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F9FA),
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}