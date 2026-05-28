import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository;

  RecipeProvider(this._repository) {
    cargarRecetas(); // Carga inicial
  }

  List<Recipe> _recipes = [];
  bool _isLoading = false;

  // --- NUEVA PROPIEDAD CENTRALIZADA DE CONTROL DE EXCEPCIONES ---
  String? _errorMessage;

  // --- GETTERS COMPATIBLES CON TU INTERFAZ ORIGINAL ---
  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<Recipe> get recetasActivas => _recipes.where((r) => r.active).toList();

  // --- LÓGICA DE DATOS ROBUSTA Y CONTROLADA ---
  Future<void> cargarRecetas() async {
    _setLoading(true);
    _clearError();
    try {
      _recipes = await _repository.getAll();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando recetas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarRecetasActivas() async {
    _setLoading(true);
    _clearError();
    try {
      _recipes = await _repository.getActives();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error cargando recetas activas: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --- ACCIONES C.R.U.D CON CAPTURA ASÍNCRONA DE RETORNO ---
  Future<bool> agregarReceta(Recipe recipe) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(recipe);
      await cargarRecetas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error agregando receta: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Soporta dynamic en los identificadores para blindar la comunicación con los widgets
  Future<bool> actualizarReceta(dynamic id, Recipe recipe) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.update(convertedId, recipe);
      await cargarRecetas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error actualizando receta: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarReceta(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.delete(convertedId);
      await cargarRecetas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error eliminando receta: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleRecetaActiva(dynamic id, bool activa) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      await _repository.toggleActiva(convertedId, activa);
      await cargarRecetas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error al cambiar estado de receta: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Recipe?> obtenerRecetaPorId(dynamic id) async {
    _setLoading(true);
    _clearError();
    try {
      final String convertedId = id.toString();
      return await _repository.getById(convertedId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error obteniendo receta: $e');
      return null;
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