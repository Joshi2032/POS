import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../repositories/producto_repository.dart';

class ProductosProvider extends ChangeNotifier {
  final ProductoRepository _repository;

  ProductosProvider(this._repository) {
    cargarDatosCompletos(); // Carga inicial
  }

  List<Producto> _productos = [];

  // DICCIONARIOS: Conectan el nombre en la UI con el UUID de la BD
  final Map<String, String> _categoriaDiccionario = {};
  List<String> _categoriasUI = ['Todos'];

  final Map<String, String> _recetaDiccionario = {};
  List<String> _recetasUI = ['Ninguna'];

  String _searchTerm = '';
  String _selectedCategory = 'Todos';

  bool _isLoading = false;
  String? _errorMessage;

  List<Producto> get productos => _productos;
  String get searchTerm => _searchTerm;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Getters para los chips y dropdowns de la UI
  List<String> get categorias => _categoriasUI;
  List<String> get recetas => _recetasUI;

  // FUNCIONES VITALES: Traducen de Nombre UI a UUID para guardarlo en la BD
  String? getCategoryIdByName(String name) => _categoriaDiccionario[name];
  String? getRecipeIdByName(String name) => _recetaDiccionario[name];

  // --- MÉTODOS CRUD ---
  Future<void> cargarDatosCompletos() async {
    _setLoading(true);
    _clearError();
    try {
      // 1. Cargar categorías
      final catsDb = await _repository.getCategorias();
      _categoriaDiccionario.clear();
      List<String> nombresCat = [];
      for (var cat in catsDb) {
        final nombre = cat['name'].toString();
        _categoriaDiccionario[nombre] = cat['id'].toString();
        nombresCat.add(nombre);
      }
      nombresCat.sort();
      _categoriasUI = ['Todos', ...nombresCat];

      // 1.5. Cargar recetas disponibles
      final recipesDb = await Supabase.instance.client
          .from('recipes')
          .select('id, name')
          .eq('active', true);
      _recetaDiccionario.clear();
      List<String> nombresRecetas = [];
      for (var r in recipesDb) {
        final nombre = r['name'].toString();
        _recetaDiccionario[nombre] = r['id'].toString();
        nombresRecetas.add(nombre);
      }
      nombresRecetas.sort();
      _recetasUI = ['Ninguna', ...nombresRecetas];

      // 2. Cargar los productos
      _productos = await _repository.getAll();

      if (!_categoriasUI.contains(_selectedCategory)) {
        _selectedCategory = 'Todos';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addProducto(Producto producto) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.create(producto);
      await cargarDatosCompletos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addCategoria(String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.createCategoria(name);
      await cargarDatosCompletos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProducto(String id, Producto producto) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.update(id, producto);
      await cargarDatosCompletos();
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
      await _repository.updateCategoria(id, name);
      await cargarDatosCompletos();
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
      await _repository.deleteCategoria(id);
      await cargarDatosCompletos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProducto(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.delete(id);
      await cargarDatosCompletos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<Producto> get productosFiltrados {
    return _productos.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch = product.name
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}
