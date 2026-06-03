import 'package:flutter/material.dart';
import '../repositories/categoria_repository.dart';

class CategoriasProvider extends ChangeNotifier {
  final CategoriaRepository _repository;

  CategoriasProvider(this._repository) {
    cargarCategorias();
  }

  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> cargarCategorias() async {
    _setLoading(true);
    _clearError();
    try {
      _categorias = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addCategoria(String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(name);
      await cargarCategorias();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategoria(String id, String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.update(id, name);
      await cargarCategorias();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategoria(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.delete(id);
      await cargarCategorias();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
