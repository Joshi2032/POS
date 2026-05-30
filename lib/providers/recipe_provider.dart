import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository;

  RecipeProvider(this._repository) {
    cargarDatos();
  }

  List<Recipe> _recipes = [];
  List<Map<String, dynamic>> _inventarioDisponible = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  String _searchTerm = '';

  List<Recipe> get recipes => _recipes;
  List<Map<String, dynamic>> get inventarioDisponible => _inventarioDisponible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Recipe> get filtradas {
    if (_searchTerm.isEmpty) return _recipes;
    return _recipes.where((r) => r.name.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
  }

  Future<void> cargarDatos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cargar recetas
      _recipes = await _repository.getAll();
      
      // Cargar inventario activo para armar las recetas
      final inv = await Supabase.instance.client
          .from('inventory_items')
          .select('id, name, unit')
          .eq('active', true);
      _inventarioDisponible = List<Map<String, dynamic>>.from(inv);
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  Future<bool> addRecipe(Recipe recipe) async {
    try {
      await _repository.create(recipe);
      await cargarDatos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecipe(String id, Recipe recipe) async {
    try {
      await _repository.update(id, recipe);
      await cargarDatos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecipe(String id) async {
    try {
      await _repository.delete(id);
      await cargarDatos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}