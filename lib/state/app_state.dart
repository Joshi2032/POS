import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String _userName = 'Invitado';
  bool _darkMode = false;

  // Orders in cart: each has id, name, price, qty
  final List<Map<String, dynamic>> _orders = [];

  // Inventory items
  final List<Map<String, dynamic>> _inventory = [];
  // Mesas (tables)
  final List<Map<String, dynamic>> _mesas = [];
  // Empleados
  final List<Map<String, dynamic>> _empleados = [];
  // Reservaciones
  final List<Map<String, dynamic>> _reservaciones = [];
  // Movimientos de caja
  final List<Map<String, dynamic>> _movimientosCaja = [];
  // Pagos a proveedores
  final List<Map<String, dynamic>> _providerPayments = [
    {
      'id': 'PAG-001',
      'provider': 'Carnes del Norte',
      'category': 'Cortes de res semanal',
      'method': 'Transferencia',
      'amount': 8500.0,
      'date': '2026-02-10',
      'time': '09:00 a.m.',
      'cashier': 'Laura S.'
    },
    {
      'id': 'PAG-002',
      'provider': 'Distribuidora de Bebidas',
      'category': 'Cervezas y refrescos',
      'method': 'Efectivo',
      'amount': 4200.0,
      'date': '2026-02-09',
      'time': '10:30 a.m.',
      'cashier': 'Laura S.'
    },
    {
      'id': 'PAG-003',
      'provider': 'Verduras Frescas MX',
      'category': 'Verduras y legumbres',
      'method': 'Transferencia',
      'amount': 2800.0,
      'date': '2026-02-08',
      'time': '08:15 a.m.',
      'cashier': 'Laura S.'
    },
  ];
  // Combos
  final List<Map<String, dynamic>> _combos = [
    {
      'id': 'CMB-001',
      'title': 'Parrillada para 2',
      'subtitle': 'Arrachera, Chorizo, guarnición y 2 bebidas',
      'tags': [
        'Arrachera 300g',
        'Chorizo Argentino',
        'Papas al Carbón',
        'Cerveza Artesanal'
      ],
      'price': 520.0,
      'oldPrice': 590.0,
      'ahorro': 'Ahorras \$70.00',
    },
    {
      'id': 'CMB-002',
      'title': 'Combo Familiar',
      'subtitle':
          'Costillas BBQ, Pollo a la Brasa, 2 guarniciones y jarra de limonada',
      'tags': [
        'Costillas BBQ',
        'Pollo a la Brasa',
        'Papas al Carbón',
        'Frijoles Charros',
        'Limonada con Hierba Buena'
      ],
      'price': 750.0,
      'oldPrice': 700.0,
      'ahorro': 'Ahorras \$50.00',
    },
  ];

  String get userName => _userName;
  bool get darkMode => _darkMode;
  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);
  List<Map<String, dynamic>> get inventory => List.unmodifiable(_inventory);
  List<Map<String, dynamic>> get mesas => List.unmodifiable(_mesas);
  List<Map<String, dynamic>> get empleados => List.unmodifiable(_empleados);
  List<Map<String, dynamic>> get reservaciones =>
      List.unmodifiable(_reservaciones);
  List<Map<String, dynamic>> get movimientosCaja =>
      List.unmodifiable(_movimientosCaja);
  List<Map<String, dynamic>> get providerPayments =>
      List.unmodifiable(_providerPayments);
  List<Map<String, dynamic>> get combos => List.unmodifiable(_combos);

  // Cart operations
  void setUser(String name) {
    _userName = name;
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void addOrder(Map<String, dynamic> order) {
    // order must contain: id, name, price, optional qty
    final id = order['id'] as String;
    final existing = _orders.indexWhere((o) => o['id'] == id);
    if (existing >= 0) {
      _orders[existing]['qty'] =
          (_orders[existing]['qty'] as int) + (order['qty'] as int? ?? 1);
    } else {
      _orders.add({
        'id': id,
        'name': order['name'],
        'price': order['price'],
        'qty': order['qty'] as int? ?? 1,
      });
    }
    notifyListeners();
  }

  void removeOrder(String id) {
    _orders.removeWhere((o) => o['id'] == id);
    notifyListeners();
  }

  void updateOrderQuantity(String id, int qty) {
    final idx = _orders.indexWhere((o) => o['id'] == id);
    if (idx >= 0) {
      if (qty <= 0) {
        _orders.removeAt(idx);
      } else {
        _orders[idx]['qty'] = qty;
      }
      notifyListeners();
    }
  }

  double get cartTotal => _orders.fold(
      0.0, (s, o) => s + (o['price'] as double) * (o['qty'] as int));

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  // Inventory operations (simple in-memory)
  void addInventoryItem(Map<String, dynamic> item) {
    _inventory.add(item);
    notifyListeners();
  }

  void updateInventoryItem(String id, Map<String, dynamic> data) {
    final idx = _inventory.indexWhere((i) => i['id'] == id);
    if (idx >= 0) {
      _inventory[idx] = {..._inventory[idx], ...data};
      notifyListeners();
    }
  }

  void removeInventoryItem(String id) {
    _inventory.removeWhere((i) => i['id'] == id);
    notifyListeners();
  }

  // Mesas operations
  void addMesa(Map<String, dynamic> mesa) {
    _mesas.add(mesa);
    notifyListeners();
  }

  void updateMesa(String id, Map<String, dynamic> data) {
    final idx = _mesas.indexWhere((m) => m['id'] == id);
    if (idx >= 0) {
      _mesas[idx] = {..._mesas[idx], ...data};
      notifyListeners();
    }
  }

  void removeMesa(String id) {
    _mesas.removeWhere((m) => m['id'] == id);
    notifyListeners();
  }

  // Empleados operations
  void addEmpleado(Map<String, dynamic> emp) {
    _empleados.add(emp);
    notifyListeners();
  }

  void updateEmpleado(String id, Map<String, dynamic> data) {
    final idx = _empleados.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      _empleados[idx] = {..._empleados[idx], ...data};
      notifyListeners();
    }
  }

  void removeEmpleado(String id) {
    _empleados.removeWhere((e) => e['id'] == id);
    notifyListeners();
  }

  // Reservaciones operations
  void addReservacion(Map<String, dynamic> reservacion) {
    _reservaciones.add(reservacion);
    notifyListeners();
  }

  void updateReservacion(String id, Map<String, dynamic> data) {
    final idx = _reservaciones.indexWhere((r) => r['id'] == id);
    if (idx >= 0) {
      _reservaciones[idx] = {..._reservaciones[idx], ...data};
      notifyListeners();
    }
  }

  void removeReservacion(String id) {
    _reservaciones.removeWhere((r) => r['id'] == id);
    notifyListeners();
  }

  // Caja operations
  void addMovimientoCaja(Map<String, dynamic> movimiento) {
    _movimientosCaja.add(movimiento);
    notifyListeners();
  }

  void updateMovimientoCaja(String id, Map<String, dynamic> data) {
    final idx = _movimientosCaja.indexWhere((m) => m['id'] == id);
    if (idx >= 0) {
      _movimientosCaja[idx] = {..._movimientosCaja[idx], ...data};
      notifyListeners();
    }
  }

  void removeMovimientoCaja(String id) {
    _movimientosCaja.removeWhere((m) => m['id'] == id);
    notifyListeners();
  }

  double get ingresosCaja => _movimientosCaja
      .where((m) => m['tipo'] == 'Ingreso')
      .fold(0.0, (sum, m) => sum + (m['monto'] as double));

  double get egresosCaja => _movimientosCaja
      .where((m) => m['tipo'] == 'Egreso')
      .fold(0.0, (sum, m) => sum + (m['monto'] as double));

  double get saldoCaja => ingresosCaja - egresosCaja;

  // Proveedores operations
  void addProviderPayment(Map<String, dynamic> payment) {
    _providerPayments.add(payment);
    notifyListeners();
  }

  void updateProviderPayment(String id, Map<String, dynamic> data) {
    final idx = _providerPayments.indexWhere((p) => p['id'] == id);
    if (idx >= 0) {
      _providerPayments[idx] = {..._providerPayments[idx], ...data};
      notifyListeners();
    }
  }

  void removeProviderPayment(String id) {
    _providerPayments.removeWhere((p) => p['id'] == id);
    notifyListeners();
  }

  // Combos operations
  void addCombo(Map<String, dynamic> combo) {
    _combos.add(combo);
    notifyListeners();
  }

  void updateCombo(String id, Map<String, dynamic> data) {
    final idx = _combos.indexWhere((c) => c['id'] == id);
    if (idx >= 0) {
      _combos[idx] = {..._combos[idx], ...data};
      notifyListeners();
    }
  }

  void removeCombo(String id) {
    _combos.removeWhere((c) => c['id'] == id);
    notifyListeners();
  }

  double get providerPaymentsTodayTotal {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _providerPayments
        .where((p) => p['date'] == today)
        .fold(0.0, (sum, p) => sum + (p['amount'] as double));
  }

  double get providerPaymentsWeekTotal =>
      _providerPayments.fold(0.0, (sum, p) => sum + (p['amount'] as double));

  double get providerPaymentsMonthTotal {
    final now = DateTime.now();
    return _providerPayments.where((p) {
      final date = DateTime.tryParse(p['date'] as String);
      return date != null && date.month == now.month && date.year == now.year;
    }).fold(0.0, (sum, p) => sum + (p['amount'] as double));
  }

  // Recetas
  final List<Map<String, dynamic>> _recetas = [
    {
      'id': 'REC-001',
      'name': 'Arrachera Signature',
      'category': 'Parrilla',
      'yieldPortions': 4,
      'prepMinutes': 25,
      'description': 'Corte marinado con guarnición',
      'active': true,
      'supplies': []
    },
    {
      'id': 'REC-002',
      'name': 'Guacamole Ahumado',
      'category': 'Entradas',
      'yieldPortions': 6,
      'prepMinutes': 15,
      'description': 'Guacamole fresco',
      'active': true,
      'supplies': []
    },
  ];

  // Gastos
  final List<Map<String, dynamic>> _gastos = [];

  // Nóminas
  final List<Map<String, dynamic>> _nominas = [
    {
      'id': 'NOM-001',
      'fecha': '2026-05-02',
      'empleado': 'Ana Mesera',
      'tipo': 'Salario',
      'periodo': 'Quincenal',
      'monto': 4200.0,
      'metodo': 'Transferencia',
      'notas': 'Pago regular'
    },
  ];

  // Cortes de Caja
  final List<Map<String, dynamic>> _cortes = [
    {
      'id': 'C-00045',
      'fecha': '2026-03-21',
      'hora': '10:45 p.m.',
      'cajero': 'Ana Ruiz',
      'metodo': 'Efectivo',
      'monto': 2340.0
    },
  ];

  List<Map<String, dynamic>> get recetas => List.unmodifiable(_recetas);
  List<Map<String, dynamic>> get gastos => List.unmodifiable(_gastos);
  List<Map<String, dynamic>> get nominas => List.unmodifiable(_nominas);
  List<Map<String, dynamic>> get cortes => List.unmodifiable(_cortes);

  // Recetas CRUD
  void addReceta(Map<String, dynamic> receta) {
    _recetas.add(receta);
    notifyListeners();
  }

  void updateReceta(String id, Map<String, dynamic> data) {
    final idx = _recetas.indexWhere((r) => r['id'] == id);
    if (idx >= 0) {
      _recetas[idx] = {..._recetas[idx], ...data};
      notifyListeners();
    }
  }

  void removeReceta(String id) {
    _recetas.removeWhere((r) => r['id'] == id);
    notifyListeners();
  }

  // Gastos CRUD
  void addGasto(Map<String, dynamic> gasto) {
    _gastos.add(gasto);
    notifyListeners();
  }

  void updateGasto(String id, Map<String, dynamic> data) {
    final idx = _gastos.indexWhere((g) => g['id'] == id);
    if (idx >= 0) {
      _gastos[idx] = {..._gastos[idx], ...data};
      notifyListeners();
    }
  }

  void removeGasto(String id) {
    _gastos.removeWhere((g) => g['id'] == id);
    notifyListeners();
  }

  double get totalGastosEstesMes {
    final now = DateTime.now();
    return _gastos.where((g) {
      final d = DateTime.tryParse(g['date'] as String);
      return d != null && d.month == now.month && d.year == now.year;
    }).fold(0.0, (sum, g) => sum + (g['amount'] as double));
  }

  // Nóminas CRUD
  void addNomina(Map<String, dynamic> nomina) {
    _nominas.add(nomina);
    notifyListeners();
  }

  void updateNomina(String id, Map<String, dynamic> data) {
    final idx = _nominas.indexWhere((n) => n['id'] == id);
    if (idx >= 0) {
      _nominas[idx] = {..._nominas[idx], ...data};
      notifyListeners();
    }
  }

  void removeNomina(String id) {
    _nominas.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }

  double get totalNominasEstesMes {
    final now = DateTime.now();
    return _nominas.where((n) {
      final d = DateTime.tryParse(n['fecha'] as String);
      return d != null && d.month == now.month && d.year == now.year;
    }).fold(0.0, (sum, n) => sum + (n['monto'] as double));
  }

  // Cortes CRUD
  void addCorte(Map<String, dynamic> corte) {
    _cortes.add(corte);
    notifyListeners();
  }

  void removeCorte(String id) {
    _cortes.removeWhere((c) => c['id'] == id);
    notifyListeners();
  }

  double get totalCortesGeneral =>
      _cortes.fold(0.0, (sum, c) => sum + (c['monto'] as double));
}
