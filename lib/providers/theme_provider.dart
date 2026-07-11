import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'isDarkMode';

  // Arranca en modo oscuro por defecto mientras se carga la preferencia
  // real guardada en el dispositivo.
  bool _isDarkMode = true;

  ThemeProvider() {
    _cargarPreferencia();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _cargarPreferencia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getBool(_prefsKey);
      if (guardado != null) {
        _isDarkMode = guardado;
        notifyListeners();
      }
    } catch (_) {
      // Si falla la lectura, seguimos con el valor por defecto.
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _guardarPreferencia();
  }

  Future<void> _guardarPreferencia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDarkMode);
    } catch (_) {
      // Falla silenciosa: el tema seguirá funcionando en esta sesión, solo
      // no se recordará la próxima vez que se abra la app.
    }
  }
}
