import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'layout/main_layout.dart';
import 'pages/dashboard_page.dart';
import 'pages/ordenes_page.dart';
import 'pages/productos_page.dart';
import 'pages/tomar_orden_page.dart';
import 'pages/inventario_page.dart';
import 'pages/mesas_page.dart';
import 'pages/empleados_page.dart';
import 'pages/reservaciones_page.dart';
import 'pages/caja_page.dart';
import 'pages/proveedores_page.dart';
import 'pages/combos_page.dart';
import 'pages/recetas_page.dart';
import 'pages/reportes_page.dart';
import 'pages/gastos_page.dart';
import 'pages/nominas_page.dart';
import 'pages/historial_cortes_page.dart';
import 'pages/ajustes_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // Enviamos las variables exactas que espera recibir el constructor de MainLayout
        return MainLayout(currentPath: state.uri.path, child: child);
      },
      routes: [
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
        GoRoute(path: '/tomar-orden', builder: (context, state) => const TomarOrdenPage()),
        GoRoute(path: '/caja', builder: (context, state) => const CajaPage()),
        GoRoute(path: '/proveedores', builder: (context, state) => const ProveedoresPage()),
        GoRoute(path: '/ordenes', builder: (context, state) => const OrdenesPage()),
        GoRoute(path: '/reservaciones', builder: (context, state) => const ReservacionesPage()),
        GoRoute(path: '/productos', builder: (context, state) => const ProductosPage()),
        GoRoute(path: '/combos', builder: (context, state) => const CombosPage()),
        GoRoute(path: '/recetas', builder: (context, state) => const RecetasPage()),
        GoRoute(path: '/empleados', builder: (context, state) => const EmpleadosPage()),
        GoRoute(path: '/inventario', builder: (context, state) => const InventarioPage()),
        GoRoute(path: '/mesas', builder: (context, state) => const MesasPage()),
        GoRoute(path: '/reportes', builder: (context, state) => const ReportesPage()),
        GoRoute(path: '/gastos', builder: (context, state) => const GastosPage()),
        GoRoute(path: '/nominas', builder: (context, state) => const NominasPage()),
        GoRoute(path: '/historial-cortes', builder: (context, state) => const HistorialCortesPage()),
        GoRoute(path: '/ajustes', builder: (context, state) => const AjustesPage()),
      ],
    ),
  ],
);