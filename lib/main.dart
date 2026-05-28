import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';

// --- Servicios y Repositorios ---
import 'services/supabase_service.dart';
import 'repositories/producto_repository.dart';
import 'repositories/gasto_repository.dart';
import 'repositories/orden_repository.dart';
import 'repositories/caja_repository.dart'; // Repositorio de caja integrado
import 'repositories/reservacion_repository.dart';
import 'repositories/mesa_repository.dart';
import 'repositories/inventario_repository.dart'; // Repositorio de inventario integrado
import 'repositories/payment_repository.dart'; // Repositorio de pagos integrado

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
import 'providers/proveedores_provider.dart';

Future<void> main() async {
  // Asegura que los canales de la plataforma nativa estén listos antes de inicializar servicios externos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización asíncrona de Supabase antes del arranque de la UI
  // Coloca aquí tu URL y Anon Key reales correspondientes a tu proyecto de Supabase
  await SupabaseService.init(
    url: 'https://tu-proyecto.supabase.co',
    anonKey: 'tu-anon-key-aqui',
  );

  runApp(
    MultiProvider(
      providers: [
        // ==========================================
        // 1. SERVICIOS BASE
        // ==========================================
        Provider(create: (_) => SupabaseService()),

        // ==========================================
        // 2. REPOSITORIOS (Capa de Datos Estática)
        // ==========================================
        Provider(create: (_) => ProductoRepository()),
        Provider(create: (_) => GastoRepository()),
        Provider(create: (_) => OrdenRepository()),
        Provider(create: (_) => CajaRepository()),
        Provider(create: (_) => ReservacionRepository()),
        Provider(create: (_) => MesaRepository()),
        Provider(create: (_) => InventarioRepository()),
        Provider(create: (_) => PaymentRepository()),
        // ==========================================
        // 3. PROVIDERS REFACTORIZADOS (Conexión a BD)
        // ==========================================
        ChangeNotifierProvider(
          create: (context) =>
              ProductosProvider(context.read<ProductoRepository>()),
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
        ChangeNotifierProvider(
            create: (context) =>
                ReservacionesProvider(context.read<ReservacionRepository>())),
        ChangeNotifierProvider(
            create: (context) => MesasProvider(context.read<MesaRepository>())),
        ChangeNotifierProvider(
          create: (context) =>
              InventarioProvider(context.read<InventarioRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProveedoresProvider(context.read<PaymentRepository>()),
        ),

        // ==========================================
        // 4. PROVIDERS SIMPLES (Estado Local)
        // ==========================================
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AjustesProvider()),
        ChangeNotifierProvider(create: (_) => CombosProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmpleadosProvider()),
        ChangeNotifierProvider(create: (_) => HistorialCortesProvider()),
        ChangeNotifierProvider(create: (_) => NominasProvider()),
        ChangeNotifierProvider(create: (_) => ReportesProvider()),
        ChangeNotifierProvider(create: (_) => TomarOrdenProvider()),
      ],
      child: const App(),
    ),
  );
}
