import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Importación corregida para evitar el conflicto con Provider:
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:zapata_flutter/repositories/caja_repository.dart';

import 'app.dart';

// --- Servicios y Repositorios ---
import 'services/supabase_service.dart';
import 'repositories/producto_repository.dart';
import 'repositories/gasto_repository.dart';
import 'repositories/orden_repository.dart';

// --- Providers ---
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

Future<void> main() async {
  // 1. Asegurar que los widgets y el motor de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Supabase antes de arrancar la App
  await Supabase.initialize(
    url: 'https://cavapauhxtotjtlousch.supabase.co', // Reemplaza si es necesario
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhdmFwYXVoeHRvdGp0bG91c2NoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExODkxMTMsImV4cCI6MjA4Njc2NTExM30.32eAT6dH05FAy86vhXMsRZD0jwdeGoQjYUnpmdvvQCA', // REEMPLAZA CON TU CLAVE REAL
  );

  runApp(
    MultiProvider(
      providers: [
        // ==========================================
        // 1. SERVICIOS BASE
        // ==========================================
        Provider(create: (_) => SupabaseService()),

        // ==========================================
        // 2. REPOSITORIOS (Capa de Datos)
        // ==========================================
        Provider(create: (_) => ProductoRepository()),
        Provider(create: (_) => GastoRepository()),
        Provider(create: (_) => OrdenRepository()),
        Provider(create: (_) => CajaRepository()),

        // ==========================================
        // 3. PROVIDERS CONECTADOS A REPOSITORIOS
        // ==========================================
        ChangeNotifierProvider(
          create: (context) => ProductosProvider(context.read<ProductoRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => GastosProvider(context.read<GastoRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => OrdenesProvider(context.read<OrdenRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CajaProvider(context.read<CajaRepository>()), 
        ),

        // ==========================================
        // 4. PROVIDERS DE ESTADO LOCAL
        // ==========================================
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AjustesProvider()),
        //ChangeNotifierProvider(create: (_) => CajaProvider()),
        ChangeNotifierProvider(create: (_) => CombosProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmpleadosProvider()),
        ChangeNotifierProvider(create: (_) => HistorialCortesProvider()),
        ChangeNotifierProvider(create: (_) => MesasProvider()),
        ChangeNotifierProvider(create: (_) => NominasProvider()),
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