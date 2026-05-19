import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/ajustes_provider.dart';
import 'providers/caja_provider.dart';
import 'providers/combos_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/empleados_provider.dart';
import 'providers/gastos_provider.dart';
import 'providers/historial_cortes_provider.dart';
import 'providers/mesas_provider.dart';
import 'providers/nominas_provider.dart';
import 'providers/ordenes_provider.dart';
import 'providers/productos_provider.dart';
import 'providers/proveedores_provider.dart';
import 'providers/reportes_provider.dart';
import 'providers/reservaciones_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tomar_orden_provider.dart';
import 'providers/inventario_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AjustesProvider()),
        ChangeNotifierProvider(create: (_) => CajaProvider()),
        ChangeNotifierProvider(create: (_) => CombosProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmpleadosProvider()),
        ChangeNotifierProvider(create: (_) => GastosProvider()),
        ChangeNotifierProvider(create: (_) => HistorialCortesProvider()),
        ChangeNotifierProvider(create: (_) => MesasProvider()),
        ChangeNotifierProvider(create: (_) => NominasProvider()),
        ChangeNotifierProvider(create: (_) => OrdenesProvider()),
        ChangeNotifierProvider(create: (_) => ProductosProvider()),
        ChangeNotifierProvider(create: (_) => ProveedoresProvider()),
        ChangeNotifierProvider(create: (_) => ReportesProvider()),
        ChangeNotifierProvider(create: (_) => ReservacionesProvider()),
        ChangeNotifierProvider(create: (_) => TomarOrdenProvider()),
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
      ],
      child: const App(),
    ),
  );
}
