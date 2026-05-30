import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/combo_item.dart';
import '../repositories/combo_repository.dart';

class CombosProvider extends ChangeNotifier {
  final ComboRepository _repository;

  CombosProvider(this._repository) {
    cargarCombos(); // Carga inicial
  }

  List<ComboItem> _combos = [];
  bool _isLoading = false;
  String _searchTerm = '';
  String? _errorMessage;

  // Catálogo de productos reales para armar los combos
  List<Map<String, dynamic>> _productosDisponibles = [];
  List<Map<String, dynamic>> get productosDisponibles => _productosDisponibles;

  List<ComboItem> get combos => _combos;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<ComboItem> get combosFiltrados {
    return _combos.where((c) {
      final matchTitle = c.title.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchSubtitle = c.subtitle.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchTitle || matchSubtitle;
    }).toList();
  }

  // --- LÓGICA DE DATOS SEGURA ---
  Future<void> cargarCombos() async {
    _setLoading(true);
    _clearError();
    try {
      _combos = await _repository.getAll();
      
      // Descargamos todos los productos activos para mostrar en el formulario
      final resProds = await Supabase.instance.client.from('products').select('id, name').eq('active', true);
      _productosDisponibles = List<Map<String, dynamic>>.from(resProds);
      
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando combos: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  // --- ACCIONES C.R.U.D CON RETORNO DE CONTROL ---
  Future<bool> agregarCombo(ComboItem combo, List<String> productIds) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(combo, productIds);
      await cargarCombos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error agregando combo: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarCombo(dynamic id, ComboItem combo, List<String> productIds) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, combo, productIds);
      await cargarCombos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error actualizando combo: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarCombo(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
      await cargarCombos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error eliminando combo: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}