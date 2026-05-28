import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';

// --- Servicios y Repositorios ---
import 'services/supabase_service.dart';
import 'repositories/producto_repository.dart';
import 'repositories/gasto_repository.dart';
import 'repositories/orden_repository.dart';
import 'repositories/caja_repository.dart';
import 'repositories/reservacion_repository.dart';
import 'repositories/mesa_repository.dart';
import 'repositories/inventario_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/combo_repository.dart';
import 'repositories/movimiento_caja_repository.dart';
import 'repositories/corte_caja_repository.dart';
import 'repositories/empleado_repository.dart';
import 'repositories/nomina_pago_repository.dart';
import 'repositories/recipe_repository.dart';

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
import 'providers/provider_payment.dart';
import 'providers/reportes_provider.dart';
import 'providers/reservaciones_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tomar_orden_provider.dart';
import 'providers/inventario_provider.dart';
import 'providers/movimiento_caja_provider.dart';
import 'providers/recipe_provider.dart';

Future<void> main() async {
  // Asegura que los canales de la plataforma nativa estén listos antes de inicializar servicios externos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización asíncrona de Supabase antes del arranque de la UI
  // Coloca aquí tu URL y Anon Key reales correspondientes a tu proyecto de Supabase
  await SupabaseService.init(
    url:
        'https://cavapauhxtotjtlousch.supabase.co', // Reemplaza si es necesario
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhdmFwYXVoeHRvdGp0bG91c2NoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExODkxMTMsImV4cCI6MjA4Njc2NTExM30.32eAT6dH05FAy86vhXMsRZD0jwdeGoQjYUnpmdvvQCA', // REEMPLAZA CON TU CLAVE REAL
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
        Provider(create: (_) => ComboRepository()),
        Provider(create: (_) => MovimientoCajaRepository()),
        Provider(create: (_) => CorteCajaRepository()),
        Provider(create: (_) => EmpleadoRepository()),
        Provider(create: (_) => NominaPagoRepository()),
        Provider(create: (_) => RecipeRepository()),
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
              PaymentsProvider(context.read<PaymentRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CombosProvider(context.read<ComboRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              MovimientoCajaProvider(context.read<MovimientoCajaRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              HistorialCortesProvider(context.read<CorteCajaRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              EmpleadosProvider(context.read<EmpleadoRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              NominasProvider(context.read<NominaPagoRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => RecipeProvider(context.read<RecipeRepository>()),
        ),

        // ==========================================
        // 4. PROVIDERS SIMPLES (Estado Local)
        // ==========================================
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AjustesProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ReportesProvider()),
        ChangeNotifierProvider(create: (_) => TomarOrdenProvider()),
      ],
      child: const App(),
    ),
  );
}
