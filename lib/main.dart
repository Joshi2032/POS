import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
export 'app.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase with placeholders — replace with real values
  await SupabaseService.init(
      url: 'YOUR_SUPABASE_URL', anonKey: 'YOUR_SUPABASE_ANON_KEY');

  runApp(ChangeNotifierProvider(
    create: (_) => AppState(),
    child: const MyApp(),
  ));
}
