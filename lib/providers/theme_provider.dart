import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Define si tu app arranca en modo oscuro por defecto
  bool _isDarkMode = true; 

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}