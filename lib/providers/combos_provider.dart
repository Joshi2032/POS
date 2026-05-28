import 'package:flutter/material.dart';
import '../models/combo_item.dart';
import '../repositories/combo_repository.dart';

class CombosProvider extends ChangeNotifier {
  final ComboRepository _repository;

  CombosProvider(this._repository) {
    cargarCombos();
  }

  List<ComboItem> _combos = [];
  bool _isLoading = false;
  String _searchTerm = '';

  List<ComboItem> get combos => _combos;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;

  List<ComboItem> get combosFiltrados {
    return _combos.where((c) {
      final matchTitle =
          c.title.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchSubtitle =
          c.subtitle.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchTitle || matchSubtitle;
    }).toList();
  }

  Future<void> cargarCombos() async {
    _isLoading = true;
    notifyListeners();
    try {
      _combos = await _repository.getAll();
    } catch (e) {
      debugPrint('Error cargando combos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  Future<void> agregarCombo(ComboItem combo) async {
    try {
      await _repository.create(combo);
      await cargarCombos();
    } catch (e) {
      debugPrint('Error agregando combo: $e');
    }
  }

  Future<void> actualizarCombo(String id, ComboItem combo) async {
    try {
      await _repository.update(id, combo);
      await cargarCombos();
    } catch (e) {
      debugPrint('Error actualizando combo: $e');
    }
  }

  Future<void> eliminarCombo(String id) async {
    try {
      await _repository.delete(id);
      await cargarCombos();
    } catch (e) {
      debugPrint('Error eliminando combo: $e');
    }
  }
}
