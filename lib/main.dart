import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importación de dotenv

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

  // Carga asíncrona de las variables de entorno desde el archivo .env
  await dotenv.load(fileName: ".env");

  // Inicialización de Supabase usando las credenciales protegidas del archivo .env
  await SupabaseService.init(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
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
        Provider(create: (_) => ProductoRepository(SupabaseService.client)),
        Provider(create: (_) => GastoRepository(SupabaseService.client)),
        Provider(create: (_) => OrdenRepository(SupabaseService.client)),
        Provider(create: (_) => CajaRepository(SupabaseService.client)),
        Provider(create: (_) => ReservacionRepository(SupabaseService.client)),
        Provider(create: (_) => MesaRepository(SupabaseService.client)),
        Provider(create: (_) => InventarioRepository(SupabaseService.client)),
        Provider(create: (_) => PaymentRepository()),
        Provider(create: (_) => ComboRepository(SupabaseService.client)),
        Provider(create: (_) => MovimientoCajaRepository()),
        Provider(create: (_) => CorteCajaRepository()),
        Provider(create: (_) => EmpleadoRepository(SupabaseService.client)),
        Provider(create: (_) => NominaPagoRepository(SupabaseService.client)),
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