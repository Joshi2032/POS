import 'package:flutter/material.dart';
import 'inventario_provider.dart'; // Importamos el almacén para poder comunicarnos

class ProveedoresProvider extends ChangeNotifier {
  final int pageSize = 10;
  final List<Map<String, dynamic>> _payments = [];
  String _searchTerm = '';
  int _currentPage = 1;

  String get searchTerm => _searchTerm;
  int get currentPage => _currentPage;
  List<Map<String, dynamic>> get payments => _payments;

  List<Map<String, dynamic>> get filteredPayments {
    if (_searchTerm.isEmpty) return _payments;
    final q = _searchTerm.toLowerCase();
    return _payments.where((payment) {
      return [
        payment['provider'],
        payment['category'],
        payment['method'],
        payment['cashier']
      ].whereType<String>().any((v) => v.toLowerCase().contains(q));
    }).toList();
  }

  int get totalPages => (filteredPayments.length / pageSize).ceil().clamp(1, 999999);

  List<Map<String, dynamic>> get paginatedPayments {
    final start = (_currentPage - 1) * pageSize;
    return filteredPayments.skip(start).take(pageSize).toList();
  }

  double get todayTotal {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _payments.where((p) => p['date'] == today).fold(0.0, (sum, p) => sum + (p['amount'] ?? 0.0));
  }

  int get todayPaymentsCount {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _payments.where((p) => p['date'] == today).length;
  }

  double get weekTotal {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _payments.where((p) {
      if (p['date'] == null) return false;
      final date = DateTime.tryParse(p['date']);
      return date != null && date.isAfter(weekAgo);
    }).fold(0.0, (sum, p) => sum + (p['amount'] ?? 0.0));
  }

  double get monthTotal {
    final now = DateTime.now();
    return _payments.where((p) {
      if (p['date'] == null) return false;
      final date = DateTime.tryParse(p['date']);
      return date != null && date.month == now.month && date.year == now.year;
    }).fold(0.0, (sum, p) => sum + (p['amount'] ?? 0.0));
  }

  int get uniqueProvidersCount {
    return _payments.map((e) => e['provider']).whereType<String>().toSet().length;
  }

  void setSearch(String val) {
    _searchTerm = val;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  // MODIFICADO: Ahora requiere recibir la instancia del Inventario para actualizarlo en tiempo real
  void addPayment(Map<String, dynamic> data, InventarioProvider inventario) {
    _payments.insert(0, data);
    
    // Si en el concepto del pago pusiste algo como "Carne Molida" y tienes stock o notas, 
    // extraemos el incremento. Para hacerlo simple y automatizado: usamos el campo 'category' (Concepto)
    // incrementando la cantidad que se registre.
    final nombreInsumo = data['category'] as String;
    
    // Asumimos por defecto un paquete/unidad de compra (puedes adaptarlo según tus notas)
    // En este simulador, cada orden recibida suma 10 unidades al stock local de forma automática.
    inventario.aumentarStockPorCompra(nombreInsumo, 10);
    
    notifyListeners();
  }

  void updatePayment(String id, Map<String, dynamic> data) {
    final idx = _payments.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      _payments[idx] = data;
      notifyListeners();
    }
  }

  void removePayment(String id) {
    _payments.removeWhere((p) => p['id'] == id);
    notifyListeners();
  }
}