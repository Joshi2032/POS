import 'package:flutter/material.dart';
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

  // --- NUEVO ESTADO DE RED CENTRALIZADO ---
  String? _errorMessage;

  // --- GETTERS COMPATIBLES AL 100% CON TU UI ORIGINAL ---
  List<ComboItem> get combos => _combos;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<ComboItem> get combosFiltrados {
    return _combos.where((c) {
      final matchTitle =
          c.title.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchSubtitle =
          c.subtitle.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchTitle || matchSubtitle;
    }).toList();
  }

  // --- LÓGICA DE DATOS SEGURA ---
  Future<void> cargarCombos() async {
    _setLoading(true);
    _clearError();
    try {
      _combos = await _repository.getAll();
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
  Future<bool> agregarCombo(ComboItem combo) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(combo);
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

  // Acepta dynamic en el identificador para evitar conflictos con la pantalla
  Future<bool> actualizarCombo(dynamic id, ComboItem combo) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, combo);
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

  // --- MÉTODOS AUXILIARES ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}