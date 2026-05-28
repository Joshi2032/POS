import '../models/restaurant_order.dart';
import '../repositories/orden_repository.dart';
import 'base_provider.dart';

class OrdenesProvider extends BaseProvider {
  final OrdenRepository _repository;
  final int pageSize = 6;

  List<RestaurantOrder> _orders = [];
  String _searchQuery = '';
  String _selectedFilterStatus = 'Todos';
  String _selectedFilterService = 'Todos';
  int _currentPage = 1;

  bool _showModal = false;
  RestaurantOrder? _selectedOrderForModal;

  OrdenesProvider(this._repository) : super() {
    cargarOrdenes();
  }

  // --- GETTERS (Exactamente como los necesita tu UI original) ---
  List<RestaurantOrder> get orders => _orders;
  String get searchQuery => _searchQuery;
  String get selectedFilterStatus => _selectedFilterStatus;
  String get selectedFilterService => _selectedFilterService;
  int get currentPage => _currentPage;
  bool get showModal => _showModal;
  RestaurantOrder? get selectedOrderForModal => _selectedOrderForModal;

  List<RestaurantOrder> get filteredOrders {
    return _orders.where((order) {
      final matchesSearch =
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.tableOrCustomer.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedFilterStatus == 'Todos' ||
          order.status.toLowerCase() == _selectedFilterStatus.toLowerCase();

      final matchesService = _selectedFilterService == 'Todos' ||
          order.serviceType.toLowerCase() == _selectedFilterService.toLowerCase();

      return matchesSearch && matchesStatus && matchesService;
    }).toList();
  }

  List<RestaurantOrder> get paginatedOrders {
    final list = filteredOrders;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, (start + pageSize) > list.length ? list.length : (start + pageSize));
  }

  int get totalPages => (filteredOrders.length / pageSize).ceil().clamp(1, 999999);
  
  // Condicionales basadas estrictamente en las propiedades de tus modelos
  int get activeOrdersCount => _orders.where((o) => o.status == 'pendiente' || o.status == 'preparando').length;
  int get readyOrdersCount => _orders.where((o) => o.status == 'lista').length;

  // --- CONTROLES DE INTERFAZ ---
  void onSearchChange(String val) {
    _searchQuery = val;
    _currentPage = 1;
    notifyListeners();
  }
  
  void onStatusFilterChange(String val) {
    _selectedFilterStatus = val;
    _currentPage = 1;
    notifyListeners();
  }
  
  void onServiceFilterChange(String val) {
    _selectedFilterService = val;
    _currentPage = 1;
    notifyListeners();
  }
  
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }
  
  void abrirDetalleModal(RestaurantOrder order) {
    _selectedOrderForModal = order;
    _showModal = true;
    notifyListeners();
  }
  
  void cerrarModal() {
    _showModal = false;
    _selectedOrderForModal = null;
    notifyListeners();
  }

  // ==========================================
  // CONEXIÓN A SUPABASE MEDIANTE BASE_PROVIDER
  // ==========================================

  Future<void> cargarOrdenes() async {
    await ejecutarOperacion(() async {
      _orders = await _repository.getOrdenesActivas();
    });
  }

  Future<void> insertarNuevaComanda(RestaurantOrder nuevaOrden) async {
    await ejecutarOperacion(() async {
      final itemsMap = nuevaOrden.items.map((i) => {
        'product_name': i.productName,
        'quantity': i.quantity,
        'total': i.total,
      }).toList();

      await _repository.crearOrden(nuevaOrden, itemsMap);
      await cargarOrdenes(); // Re-sincroniza el listado activo
    });
  }

  Future<bool> cambiarEstadoOrden(String id, String nuevoEstado) async {
    bool exito = false;
    await ejecutarOperacion(() async {
      await _repository.actualizarEstado(id, nuevoEstado);
      await cargarOrdenes();
      
      // Mantiene la actualización reactiva del modal si el usuario lo tiene abierto
      if (_selectedOrderForModal?.id == id) {
        final idx = _orders.indexWhere((o) => o.id == id);
        if (idx != -1) _selectedOrderForModal = _orders[idx];
      }
      exito = true;
    });
    return exito;
  }
}