import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    // In absence of a Realtime subscription, poll periodically as a safe fallback
    _startPolling();
    _initRealtimeSubscription();
  }

  Timer? _pollTimer;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        await cargarOrdenes();
      } catch (_) {}
    });
  }

  dynamic _ordersChannel;
  // Refleja si Realtime está confirmado y activo en este momento. No se
  // consume internamente todavía, pero queda disponible como getter para
  // que la UI pueda mostrar un indicador de "conexión en vivo" si se desea.
  bool _realtimeConfirmado = false;
  bool get realtimeActivo => _realtimeConfirmado;

  void _initRealtimeSubscription() {
    try {
      final channel = Supabase.instance.client.channel('orders-channel');

      channel.on(RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'orders'),
          (payload, [ref]) {
        // Any change on orders -> reload
        cargarOrdenes();
      });

      // La firma exacta de subscribe() en realtime_client v1.x es:
      //   void Function(String status, [Object? error])?
      // El segundo parámetro es opcional pero debe declararse para que
      // Dart asigne el callback correctamente. El valor de éxito es 'SUBSCRIBED'.
      channel.subscribe((status, [error]) {
        debugPrint('ORDENES_PROVIDER: Realtime status=$status');

        if (status == 'SUBSCRIBED') {
          _realtimeConfirmado = true;
          _pollTimer?.cancel();
          debugPrint('ORDENES_PROVIDER: Realtime confirmado, polling detenido.');
        } else {
          _realtimeConfirmado = false;
          if (_pollTimer == null || !_pollTimer!.isActive) {
            debugPrint(
                'ORDENES_PROVIDER: Realtime no disponible ($status). Reactivando polling.');
            _startPolling();
          }
        }
      });

      _ordersChannel = channel;
    } catch (e) {
      debugPrint('Realtime subscription failed: $e');
      // Si la suscripción ni siquiera pudo intentarse, nos aseguramos de
      // que el polling de respaldo siga activo.
      if (_pollTimer == null || !_pollTimer!.isActive) {
        _startPolling();
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    try {
      if (_ordersChannel != null) {
        _ordersChannel.unsubscribe();
      }
    } catch (_) {}
    super.dispose();
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
      final matchesSearch = order.orderNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.tableOrCustomer
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedFilterStatus == 'Todos' ||
          order.status.toLowerCase() == _selectedFilterStatus.toLowerCase();

      final matchesService = _selectedFilterService == 'Todos' ||
          order.serviceType.toLowerCase() ==
              _selectedFilterService.toLowerCase();

      return matchesSearch && matchesStatus && matchesService;
    }).toList();
  }

  List<RestaurantOrder> get paginatedOrders {
    final list = filteredOrders;
    final start = (_currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    return list.sublist(start,
        (start + pageSize) > list.length ? list.length : (start + pageSize));
  }

  int get totalPages =>
      (filteredOrders.length / pageSize).ceil().clamp(1, 999999);

  // Condicionales basadas estrictamente en las propiedades de tus modelos
  int get activeOrdersCount => _orders
      .where((o) => o.status == 'pendiente' || o.status == 'preparando')
      .length;
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
      final itemsMap = nuevaOrden.items
          .map((i) => {
                'product_name': i.productName,
                'product_id': i.productId,
                'quantity': i.quantity,
                'unit_price': i.unitPrice,
                'total': i.total,
              })
          .toList();

      await _repository.crearOrden(nuevaOrden, itemsMap);
      await cargarOrdenes(); // Re-sincroniza el listado activo
    });
  }

  Future<bool> cambiarEstadoOrden(String id, String nuevoEstado) async {
    bool exito = false;
    await ejecutarOperacion(() async {
      // Mapear estados desde la UI (es: 'preparando', 'pagada')
      // al valor que espera la base de datos (en inglés: 'preparing', 'paid').
      final estadoDb = _mapEstadoUiToDb(nuevoEstado);
      debugPrint(
          'ORDENES_PROVIDER: cambiarEstadoOrden(id=$id, nuevoEstado=$nuevoEstado) -> estadoDb=$estadoDb');
      await _repository.actualizarEstado(id, estadoDb);
      await cargarOrdenes();

      // Mantiene la actualización reactiva del modal si el usuario lo tiene abierto
      if (_selectedOrderForModal?.id == id) {
        final idx = _orders.indexWhere((o) => o.id == id);
        if (idx != -1) {
          _selectedOrderForModal = _orders[idx];
        }
      }
      exito = true;
    });
    return exito;
  }

  String _mapEstadoUiToDb(String estado) {
    final e = estado.toLowerCase();
    switch (e) {
      case 'preparando':
        return 'preparing';
      case 'lista':
        return 'ready';
      case 'entregada':
        return 'delivered';
      case 'pagada':
        return 'paid';
      case 'cancelada':
        return 'cancelled';
      case 'pendiente':
        return 'pending';
      default:
        // Si ya se pasó un estado en inglés, lo devolvemos tal cual si es válido
        if (['pending', 'preparing', 'ready', 'delivered', 'paid', 'cancelled']
            .contains(e)) {
          return e;
        }
        // Fallback seguro
        return 'pending';
    }
  }
}