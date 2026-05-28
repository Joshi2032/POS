import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository;

  RecipeProvider(this._repository) {
    cargarRecetas();
  }

  List<Recipe> _recipes = [];
  bool _isLoading = false;

  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;

  List<Recipe> get recetasActivas => _recipes.where((r) => r.active).toList();

  Future<void> cargarRecetas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _recipes = await _repository.getAll();
    } catch (e) {
      debugPrint('Error cargando recetas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarRecetasActivas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _recipes = await _repository.getActivas();
    } catch (e) {
      debugPrint('Error cargando recetas activas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> agregarReceta(Recipe recipe) async {
    try {
      await _repository.create(recipe);
      await cargarRecetas();
    } catch (e) {
      debugPrint('Error agregando receta: $e');
    }
  }

  Future<void> actualizarReceta(String id, Recipe recipe) async {
    try {
      await _repository.update(id, recipe);
      await cargarRecetas();
    } catch (e) {
      debugPrint('Error actualizando receta: $e');
    }
  }

  Future<void> eliminarReceta(String id) async {
    try {
      await _repository.delete(id);
      await cargarRecetas();
    } catch (e) {
      debugPrint('Error eliminando receta: $e');
    }
  }

  Future<void> toggleRecetaActiva(String id, bool activa) async {
    try {
      await _repository.toggleActiva(id, activa);
      await cargarRecetas();
    } catch (e) {
      debugPrint('Error al cambiar estado de receta: $e');
    }
  }

  Future<Recipe?> obtenerRecetaPorId(String id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      debugPrint('Error obteniendo receta: $e');
      return null;
    }
  }
}
