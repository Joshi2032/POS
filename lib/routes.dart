
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'layout/main_layout.dart';
import 'pages/ajustes_page.dart';
import 'pages/caja_page.dart';
import 'pages/categorias_page.dart';
import 'pages/combos_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/empleados_page.dart';
import 'pages/gastos_page.dart';
import 'pages/historial_cortes_page.dart';
import 'pages/inventario_page.dart';
import 'pages/login_page.dart';
import 'pages/mesas_page.dart';
import 'pages/nominas_page.dart';
import 'pages/ordenes_page.dart';
import 'pages/productos_page.dart';
import 'pages/proveedores_page.dart';
import 'pages/recetas_page.dart';
import 'pages/reportes_page.dart';
import 'pages/reservaciones_page.dart';
import 'pages/tomar_orden_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',

  redirect: (context, state) {
    final session =
        Supabase.instance.client.auth.currentSession;

    final isLoggedIn = session != null;
    final isLoginPage =
        state.uri.path == '/login';

    if (!isLoggedIn && !isLoginPage) {
      return '/login';
    }

    if (isLoggedIn && isLoginPage) {
      return '/dashboard';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            return const DashboardPage();
          },
        ),
        GoRoute(
          path: '/tomar-orden',
          builder: (context, state) {
            return const TomarOrdenPage();
          },
        ),
        GoRoute(
          path: '/caja',
          builder: (context, state) {
            return const CajaPage();
          },
        ),
        GoRoute(
          path: '/proveedores',
          builder: (context, state) {
            return const ProveedoresPage();
          },
        ),
        GoRoute(
          path: '/ordenes',
          builder: (context, state) {
            return const OrdenesPage();
          },
        ),
        GoRoute(
          path: '/reservaciones',
          builder: (context, state) {
            return const ReservacionesPage();
          },
        ),
        GoRoute(
          path: '/productos',
          builder: (context, state) {
            return const ProductosPage();
          },
        ),
        GoRoute(
          path: '/categorias',
          builder: (context, state) {
            return const CategoriasPage();
          },
        ),
        GoRoute(
          path: '/combos',
          builder: (context, state) {
            return const CombosPage();
          },
        ),
        GoRoute(
          path: '/recetas',
          builder: (context, state) {
            return const RecetasPage();
          },
        ),
        GoRoute(
          path: '/empleados',
          builder: (context, state) {
            return const EmpleadosPage();
          },
        ),
        GoRoute(
          path: '/inventario',
          builder: (context, state) {
            return const InventarioPage();
          },
        ),
        GoRoute(
          path: '/mesas',
          builder: (context, state) {
            return const MesasPage();
          },
        ),
        GoRoute(
          path: '/reportes',
          builder: (context, state) {
            return const ReportesPage();
          },
        ),
        GoRoute(
          path: '/gastos',
          builder: (context, state) {
            return const GastosPage();
          },
        ),
        GoRoute(
          path: '/nominas',
          builder: (context, state) {
            return const NominasPage();
          },
        ),
        GoRoute(
          path: '/historial-cortes',
          builder: (context, state) {
            return const HistorialCortesPage();
          },
        ),
        GoRoute(
          path: '/ajustes',
          builder: (context, state) {
            return const AjustesPage();
          },
        ),
      ],
    ),
  ],
);

