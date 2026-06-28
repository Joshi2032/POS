import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importación de dotenv

import 'app.dart';

// --- Servicios y Repositorios ---
import 'services/supabase_service.dart';
import 'repositories/producto_repository.dart';
import 'repositories/categoria_repository.dart';
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
import 'providers/categorias_provider.dart';
import 'providers/provider_payment.dart';
import 'providers/reportes_provider.dart';
import 'providers/reservaciones_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tomar_orden_provider.dart';
import 'providers/inventario_provider.dart';
import 'providers/movimiento_caja_provider.dart';
import 'providers/recipe_provider.dart';
import 'repositories/auth_repository.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  // Asegura que los canales de la plataforma nativa estén listos antes de inicializar servicios externos
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FORMA CORRECTA PARA FLUTTER (LEE DESDE LOS ASSETS COMPILADOS EN EL APK)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Cargado .env correctamente desde los assets');
  } catch (e) {
    debugPrint('No se encontró el archivo .env en los assets. Error: $e');
  }

  final envUrl = dotenv.env['SUPABASE_URL']?.trim();
  final envAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

  // Mantenemos el fallback a Platform.environment por si lo corres en web/escritorio
  final url = (envUrl != null && envUrl.isNotEmpty)
      ? envUrl
      : Platform.environment['SUPABASE_URL']?.trim() ?? '';
  final anonKey = (envAnonKey != null && envAnonKey.isNotEmpty)
      ? envAnonKey
      : Platform.environment['SUPABASE_ANON_KEY']?.trim() ?? '';

  if (url.isEmpty || anonKey.isEmpty) {
    debugPrint(
        'ERROR CRITICO: SUPABASE_URL o SUPABASE_ANON_KEY faltan. url=${url.isEmpty ? 'MISSING' : url}, anonKey length=${anonKey.length}');
    // En lugar de crashear la app con throw StateError, permitimos que la app inicie
    // para evitar la pantalla negra. Puedes mostrar una alerta de error en el login si estas variables fallan.
  } else {
    debugPrint(
        'Supabase inicializado con URL=$url y anonKey length=${anonKey.length}');
  }

  // Inicialización de Supabase usando las credenciales
  await SupabaseService.init(
    url: url,
    anonKey: anonKey,
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
        Provider(create: (_) => CategoriaRepository(SupabaseService.client)),
        Provider(create: (_) => GastoRepository(SupabaseService.client)),
        Provider(create: (_) => OrdenRepository(SupabaseService.client)),
        Provider(create: (_) => CajaRepository(SupabaseService.client)),
        Provider(create: (_) => ReservacionRepository(SupabaseService.client)),
        Provider(create: (_) => MesaRepository(SupabaseService.client)),
        Provider(create: (_) => InventarioRepository(SupabaseService.client)),
        Provider(create: (_) => PaymentRepository(SupabaseService.client)),
        Provider(create: (_) => ComboRepository(SupabaseService.client)),
        Provider(
            create: (_) => MovimientoCajaRepository(SupabaseService.client)),
        Provider(create: (_) => CorteCajaRepository(SupabaseService.client)),
        Provider(create: (_) => EmpleadoRepository(SupabaseService.client)),
        Provider(create: (_) => NominaPagoRepository(SupabaseService.client)),
        Provider(create: (_) => RecipeRepository(SupabaseService.client)),
        Provider(create: (_) => AuthRepository()),

        // ==========================================
        // 3. PROVIDERS REFACTORIZADOS (Conexión a BD)
        // ==========================================
        ChangeNotifierProvider(
          create: (context) =>
              ProductosProvider(context.read<ProductoRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CategoriasProvider(context.read<CategoriaRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => GastosProvider(context.read<GastoRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => OrdenesProvider(context.read<OrdenRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CajaProvider(
              context.read<CajaRepository>(), context.read<OrdenesProvider>()),
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
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
        ),

        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            context.read<OrdenRepository>(),
            context.read<GastoRepository>(),
            context.read<PaymentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
            create: (context) =>
                ReportesProvider(context.read<OrdenRepository>())),

        ChangeNotifierProxyProvider<AuthProvider, TomarOrdenProvider>(
          create: (context) => TomarOrdenProvider(
            context.read<ProductoRepository>(),
            context.read<MesaRepository>(),
            context.read<ComboRepository>(),
          ),
          update: (context, authProvider, tomarOrdenProvider) {
            final provider = tomarOrdenProvider!;

            final authUserId = authProvider.userId;

            if (authUserId != null && authUserId.isNotEmpty) {
              provider.cargarAreasDelUsuario(
                authUserId: authUserId,
                empleadoRepository: context.read<EmpleadoRepository>(),
              );
            }

            return provider;
          },
        ),

        // ==========================================
        // 4. PROVIDERS SIMPLES (Estado Local)
        // ==========================================
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AjustesProvider()),
      ],
      child: const App(),
    ),
  );
}
