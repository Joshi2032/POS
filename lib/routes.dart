import 'package:flutter/material.dart';
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

class Routes {
  static const dashboard = '/';
  static const ordenes = '/ordenes';
  static const productos = '/productos';
  static const tomarOrden = '/tomar-orden';
  static const inventario = '/inventario';
  static const mesas = '/mesas';
  static const empleados = '/empleados';
  static const reservaciones = '/reservaciones';
  static const caja = '/caja';
  static const proveedores = '/proveedores';
  static const combos = '/combos';
  static const recetas = '/recetas';
  static const reportes = '/reportes';
  static const gastos = '/gastos';
  static const nominas = '/nominas';
  static const historialCortes = '/historial-cortes';
  static const ajustes = '/ajustes';

  static Map<String, WidgetBuilder> get map => {
        dashboard: (_) => const DashboardPage(),
        ordenes: (_) => const OrdenesPage(),
        productos: (_) => const ProductosPage(),
        tomarOrden: (_) => const TomarOrdenPage(),
        inventario: (_) => const InventarioPage(),
        mesas: (_) => const MesasPage(),
        empleados: (_) => const EmpleadosPage(),
        reservaciones: (_) => const ReservacionesPage(),
        caja: (_) => const CajaPage(),
        proveedores: (_) => const ProveedoresPage(),
        combos: (_) => const CombosPage(),
        recetas: (_) => const RecetasPage(),
        reportes: (_) => const ReportesPage(),
        gastos: (_) => const GastosPage(),
        nominas: (_) => const NominasPage(),
        historialCortes: (_) => const HistorialCortesPage(),
        ajustes: (_) => const AjustesPage(),
      };
}
