import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  String _filterType = 'semana';

  String get filterType => _filterType;

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  // --- Datos transferidos del widget original ---
  final List<String> weekLabels = ['mar', 'mié', 'jue', 'vie', 'sab', 'dom', 'lun'];
  final List<double> weekIngresos = [12000, 15000, 9000, 18000, 21000, 24000, 7000];
  final List<double> weekGastos = [6000, 8000, 7000, 9000, 11000, 12000, 5000];
  final List<double> weekUtilidad = [6000, 7000, 2000, 9000, 10000, 12000, 2000];

  final List<String> monthLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
  final List<double> monthIngresos = [52000, 48000, 61000, 57000];
  final List<double> monthGastos = [26000, 22000, 31000, 27000];
  final List<double> monthUtilidad = [26000, 26000, 30000, 30000];

  final List<String> yearLabels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  final List<double> yearIngresos = [210000, 220000, 205000, 230000, 240000, 250000, 260000, 255000, 245000, 235000, 225000, 215000];
  final List<double> yearGastos = [110000, 115000, 108000, 120000, 125000, 130000, 135000, 132000, 128000, 124000, 120000, 118000];
  final List<double> yearUtilidad = [100000, 105000, 97000, 110000, 115000, 120000, 125000, 123000, 117000, 111000, 105000, 97000];

  List<String> get currentLabels {
    if (_filterType == 'mes') return monthLabels;
    if (_filterType == 'año') return yearLabels;
    return weekLabels;
  }

  List<double> get currentIngresos {
    if (_filterType == 'mes') return monthIngresos;
    if (_filterType == 'año') return yearIngresos;
    return weekIngresos;
  }

  List<double> get currentGastos {
    if (_filterType == 'mes') return monthGastos;
    if (_filterType == 'año') return yearGastos;
    return weekGastos;
  }

  List<double> get currentUtilidad {
    if (_filterType == 'mes') return monthUtilidad;
    if (_filterType == 'año') return yearUtilidad;
    return weekUtilidad;
  }
}