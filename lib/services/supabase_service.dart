import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init(
      {required String url, required String anonKey}) async {
    if (url.isEmpty || anonKey.isEmpty) {
      throw ArgumentError(
        'Supabase url y anonKey no pueden ser vacíos. '
        'url=${url.isEmpty ? 'EMPTY' : 'PRESENT'}, anonKey length=${anonKey.length}',
      );
    }

    debugPrint(
        'SupabaseService.init() usando url=$url, anonKey length=${anonKey.length}');
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
