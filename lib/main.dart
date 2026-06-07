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

Future<String?> _findEnvFile() async {
  final candidates = <File>[];

  // 1) Archivo .env en el directorio actual
  candidates.add(File('.env'));

  // 2) Recorremos parents de Directory.current
  var currentDirectory = Directory.current;
  for (var i = 0; i < 8; i++) {
    candidates
        .add(File('${currentDirectory.path}${Platform.pathSeparator}.env'));
    if (currentDirectory.path == currentDirectory.parent.path) break;
    currentDirectory = currentDirectory.parent;
  }

  // 3) Recorremos parents del script actual
  var scriptDirectory = File(Platform.script.toFilePath()).parent;
  for (var i = 0; i < 8; i++) {
    candidates
        .add(File('${scriptDirectory.path}${Platform.pathSeparator}.env'));
    if (scriptDirectory.path == scriptDirectory.parent.path) break;
    scriptDirectory = scriptDirectory.parent;
  }

  // 4) Recorremos parents del ejecutable resuelto
  var execDirectory = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    candidates.add(File('${execDirectory.path}${Platform.pathSeparator}.env'));
    if (execDirectory.path == execDirectory.parent.path) break;
    execDirectory = execDirectory.parent;
  }

  for (final candidate in candidates) {
    if (await candidate.exists()) return candidate.path;
  }
  return null;
}

Future<void> main() async {
  // Asegura que los canales de la plataforma nativa estén listos antes de inicializar servicios externos
  WidgetsFlutterBinding.ensureInitialized();

  final envFile = await _findEnvFile();
  if (envFile != null) {
    await dotenv.load(fileName: envFile);
    debugPrint('Cargado .env desde: $envFile');
  } else {
    debugPrint('No se encontró .env; usando variables de entorno del sistema.');
  }

  final envUrl = dotenv.env['SUPABASE_URL']?.trim();
  final envAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
  final url = (envUrl != null && envUrl.isNotEmpty)
      ? envUrl
      : Platform.environment['SUPABASE_URL']?.trim() ?? '';
  final anonKey = (envAnonKey != null && envAnonKey.isNotEmpty)
      ? envAnonKey
      : Platform.environment['SUPABASE_ANON_KEY']?.trim() ?? '';

  if (url.isEmpty || anonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL o SUPABASE_ANON_KEY faltan. '
      'url=${url.isEmpty ? 'MISSING' : url}, '
      'anonKey length=${anonKey.length}',
    );
  }
  debugPrint(
      'Supabase inicializado con URL=$url y anonKey length=${anonKey.length}');

  // Inicialización de Supabase usando las credenciales protegidas del archivo .env o las variables de entorno
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
          create: (context) => DashboardProvider(
            context.read<OrdenRepository>(),
            context.read<GastoRepository>(),
            context.read<PaymentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
            create: (context) =>
                ReportesProvider(context.read<OrdenRepository>())),
        ChangeNotifierProvider(
          create: (context) => TomarOrdenProvider(
            context.read<ProductoRepository>(),
            context.read<MesaRepository>(),
            context.read<ComboRepository>(), // <-- ¡Esta es la línea que faltaba!
          ),
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
