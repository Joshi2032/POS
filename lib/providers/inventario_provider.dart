import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../repositories/inventario_repository.dart';

class InventarioProvider extends ChangeNotifier {
  final InventarioRepository _repository;
  List<InventoryItem> _items = [];
  String _searchTerm = '';
  
  // --- NUEVOS ESTADOS CENTRALIZADOS DE RED Y FLUJO ---
  bool _isLoading = false;
  String? _errorMessage;

  InventarioProvider(this._repository) {
    cargarInventario(); // Carga inicial
  }

  // --- GETTERS COMPATIBLES AL 100% CON TU MODELO Y UI ORIGINAL ---
  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Getter requerido por tu UI: Listado filtrado por nombre exacto
  List<InventoryItem> get filteredItems {
    if (_searchTerm.isEmpty) return _items;
    return _items
        .where((i) => i.name.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();
  }

  // --- SETTERS ---
  // Setter requerido por tu UI: Actualiza la búsqueda en tiempo real
  void setSearch(String value) {
    _searchTerm = value;
    notifyListeners();
  }

  // --- LÓGICA DE DATOS ROBUSTA ---
  Future<void> cargarInventario() async {
    _setLoading(true);
    _clearError();
    try {
      _items = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error al cargar inventario: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --- MÉTODOS CRUD REQUERIDOS POR INVENTARIO_PAGE.DART CON RETORNO DE CONTROL ---

  Future<bool> addInventoryItem(InventoryItem item) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(item);
      await cargarInventario();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateInventoryItem(String id, InventoryItem item) async {
    _setLoading(true);
    _clearError();
    try {
      // Usamos copyWith para asegurar que el ID coincida con el que viene de la UI
      final itemActualizado = item.copyWith(id: id);
      await _repository.update(id, itemActualizado);
      await cargarInventario();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeInventoryItem(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.delete(id);
      await cargarInventario();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- LÓGICA DE CONTROL DE STOCK CAPTURADA ---

  Future<void> ajustarStock(
      InventoryItem item, double nuevaCantidad, String razon) async {
    _setLoading(true);
    _clearError();
    try {
      final cantidadSegura = nuevaCantidad < 0 ? 0.0 : nuevaCantidad;

      await _repository.actualizarStock(item.id, cantidadSegura);

      // La diferencia es double, igual que tu modelo
      final diferencia = cantidadSegura - item.stock;

      await _repository.registrarMovimiento(item.id, diferencia, razon);
      await cargarInventario();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error al ajustar stock: $e');
      rethrow; // Re-lanzamos para que la UI capture si maneja controladores locales
    } finally {
      _setLoading(false);
    }
  }

  // Usa el ajuste ATÓMICO (delta), no ajustarStock (valor absoluto), porque
  // una compra es un incremento relativo: si dos compras del mismo insumo se
  // registran casi al mismo tiempo, ambas deben sumarse, no que la segunda
  // sobreescriba a la primera.
  Future<void> aumentarStockPorCompra(String itemId, double cantidad) async {
    _setLoading(true);
    _clearError();
    try {
      if (cantidad <= 0) {
        throw Exception('La cantidad de la compra debe ser mayor a 0.');
      }

      await _repository.ajustarStockAtomico(
        itemId,
        cantidad,
        'Compra a proveedor',
      );
      await cargarInventario();
    } catch (e) {
      _errorMessage = 'No se pudo registrar la compra: $e';
      debugPrint('Error en aumentarStockPorCompra: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // --- MÉTODOS AUXILIARES INTERNOS ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}