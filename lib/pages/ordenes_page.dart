import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_order.dart';
import '../providers/ordenes_provider.dart';
import '../utils/formatters.dart';
import '../utils/ui_utils.dart';

class OrdenesPage extends StatelessWidget {
  const OrdenesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OrdenesView();
  }
}

class _OrdenesView extends StatelessWidget {
  const _OrdenesView();

  String _getStatusLabel(OrderStatus status) {
    const labels = {
      'pendiente': 'Pendiente',
      'preparando': 'En Cocina',
      'lista': 'Lista para Entrega',
      'entregada': 'Entregada',
      'cancelada': 'Cancelada',
    };
    return labels[status] ?? status;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.blue;
      case 'lista':
        return Colors.green;
      case 'entregada':
        return Colors.grey;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _getServiceLabel(ServiceType type) {
    if (type == 'comedor') return '🍽️ Comedor';
    if (type == 'llevar') return '🛍️ Para Llevar';
    return '🛵 Domicilio';
  }

  // Columnas del grid según ancho
  int _gridColumns(double w) {
    if (w < 500) return 1;
    if (w < 900) return 2;
    return 3;
  }

  // childAspectRatio según columnas
  double _gridRatio(int cols) {
    if (cols == 1) return 2.0;
    if (cols == 2) return 1.5;
    return 1.4;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdenesProvider>();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final hPad = w < 480 ? 16.0 : 20.0;
                final isCompact = w < 600;
                final cols = _gridColumns(w);

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── HEADER ─────────────────────────────────────
                          if (isCompact) ...[
                            _HeaderTitle(context: context),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatusBadge(
                                  title: 'Activas',
                                  count: '${provider.activeOrdersCount}',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 10),
                                _StatusBadge(
                                  title: 'Listas',
                                  count: '${provider.readyOrdersCount}',
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: _HeaderTitle(context: context)),
                                const SizedBox(width: 16),
                                _StatusBadge(
                                  title: 'Activas',
                                  count: '${provider.activeOrdersCount}',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 10),
                                _StatusBadge(
                                  title: 'Listas',
                                  count: '${provider.readyOrdersCount}',
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          // ── FILTROS ────────────────────────────────────
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: isCompact
                                  ? Column(
                                      children: [
                                        _SearchField(provider: provider),
                                        const Divider(height: 16),
                                        _FilterDropdown(
                                          label: 'Estado',
                                          value:
                                              provider.selectedFilterStatus,
                                          items: const [
                                            'Todos',
                                            'Pendiente',
                                            'Preparando',
                                            'Lista',
                                            'Entregada',
                                            'Cancelada',
                                          ],
                                          onChanged: (v) => provider
                                              .onStatusFilterChange(
                                                  v ?? 'Todos'),
                                        ),
                                        const SizedBox(height: 8),
                                        _FilterDropdown(
                                          label: 'Servicio',
                                          value: provider
                                              .selectedFilterService,
                                          items: const [
                                            'Todos',
                                            'Comedor',
                                            'Llevar',
                                            'Domicilio',
                                          ],
                                          onChanged: (v) => provider
                                              .onServiceFilterChange(
                                                  v ?? 'Todos'),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: _SearchField(
                                              provider: provider),
                                        ),
                                        const VerticalDivider(
                                            width: 24, thickness: 1),
                                        Expanded(
                                          flex: 2,
                                          child: _FilterDropdown(
                                            label: 'Estado',
                                            value: provider
                                                .selectedFilterStatus,
                                            items: const [
                                              'Todos',
                                              'Pendiente',
                                              'Preparando',
                                              'Lista',
                                              'Entregada',
                                              'Cancelada',
                                            ],
                                            onChanged: (v) => provider
                                                .onStatusFilterChange(
                                                    v ?? 'Todos'),
                                          ),
                                        ),
                                        const VerticalDivider(
                                            width: 24, thickness: 1),
                                        Expanded(
                                          flex: 2,
                                          child: _FilterDropdown(
                                            label: 'Servicio',
                                            value: provider
                                                .selectedFilterService,
                                            items: const [
                                              'Todos',
                                              'Comedor',
                                              'Llevar',
                                              'Domicilio',
                                            ],
                                            onChanged: (v) => provider
                                                .onServiceFilterChange(
                                                    v ?? 'Todos'),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── CONTADOR ───────────────────────────────────
                          Text(
                            '${provider.filteredOrders.length} orden(es) encontrada(s)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 12),

                          // ── EMPTY STATE ────────────────────────────────
                          if (provider.filteredOrders.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Text('🍳',
                                        style: TextStyle(fontSize: 54)),
                                    SizedBox(height: 12),
                                    Text(
                                      'No hay órdenes activas que coincidan con los filtros.',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 15),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── GRID DE ÓRDENES ────────────────────────────
                          if (provider.paginatedOrders.isNotEmpty)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: _gridRatio(cols),
                              ),
                              itemCount: provider.paginatedOrders.length,
                              itemBuilder: (context, index) {
                                final order =
                                    provider.paginatedOrders[index];
                                return _OrderCard(
                                  order: order,
                                  statusLabel:
                                      _getStatusLabel(order.status),
                                  statusColor:
                                      _getStatusColor(order.status),
                                  serviceLabel:
                                      _getServiceLabel(order.serviceType),
                                  onTap: () =>
                                      provider.abrirDetalleModal(order),
                                );
                              },
                            ),

                          const SizedBox(height: 20),

                          // ── PAGINACIÓN ─────────────────────────────────
                          if (provider.totalPages > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: provider.currentPage == 1
                                      ? null
                                      : () => provider.goToPage(
                                          provider.currentPage - 1),
                                ),
                                Text(
                                  'Página ${provider.currentPage} de ${provider.totalPages}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: provider.currentPage ==
                                          provider.totalPages
                                      ? null
                                      : () => provider.goToPage(
                                          provider.currentPage + 1),
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── MODAL DETALLE ────────────────────────────────────────────────
          if (provider.showModal &&
              provider.selectedOrderForModal != null) ...[
            GestureDetector(
              onTap: provider.cerrarModal,
              child: Container(color: Colors.black54),
            ),
            _DetalleModal(
              provider: provider,
              getStatusLabel: _getStatusLabel,
              getServiceLabel: _getServiceLabel,
            ),
          ],
        ],
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📋 ', style: TextStyle(fontSize: 24)),
            Flexible(
              child: Text(
                'Módulo de Órdenes',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const Text(
          'Monitoreo en tiempo real de comandas y despachos',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.title,
    required this.count,
    required this.color,
  });
  final String title;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$title: ',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(count,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.provider});
  final OrdenesProvider provider;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Buscar por ID de orden o cliente/mesa...',
        prefixIcon: Icon(Icons.search),
        border: InputBorder.none,
      ),
      onChanged: provider.onSearchChange,
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration:
          InputDecoration(labelText: label, border: InputBorder.none),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.statusLabel,
    required this.statusColor,
    required this.serviceLabel,
    required this.onTap,
  });

  final RestaurantOrder order;
  final String statusLabel;
  final Color statusColor;
  final String serviceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número de orden + hora
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber.isNotEmpty
                          ? order.orderNumber
                          : order.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('🕒 ${order.time}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              // Cliente/mesa + badge de estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.tableOrCustomer,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(serviceLabel,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.blueGrey)),
              const Divider(height: 12),
              // Productos (máximo 2)
              Expanded(
                child: ListView.builder(
                  itemCount:
                      order.items.length > 2 ? 2 : order.items.length,
                  itemBuilder: (ctx, idx) {
                    final item = order.items[idx];
                    return Text(
                      '${item.quantity}x ${item.productName}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              if (order.items.length > 2)
                Text(
                  '+ ${order.items.length - 2} productos más...',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              const SizedBox(height: 4),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${Formatters.money(order.totalAmount)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── MODAL DETALLE ────────────────────────────────────────────────────────────

class _DetalleModal extends StatelessWidget {
  const _DetalleModal({
    required this.provider,
    required this.getStatusLabel,
    required this.getServiceLabel,
  });

  final OrdenesProvider provider;
  final String Function(OrderStatus) getStatusLabel;
  final String Function(ServiceType) getServiceLabel;

  @override
  Widget build(BuildContext context) {
    final order = provider.selectedOrderForModal!;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isWide = w > 600;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isWide ? 500 : w - 32,
        constraints: BoxConstraints(maxHeight: h * 0.88),
        margin: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isWide ? 24 : 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Comanda: ${order.orderNumber.isNotEmpty ? order.orderNumber : order.id}',
                          style: TextStyle(
                              fontSize: isWide ? 18 : 16,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: provider.cerrarModal,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    'Cliente/Mesa: ${order.tableOrCustomer}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Tipo de Servicio: ${getServiceLabel(order.serviceType)}',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  Text('Hora de Registro: ${order.time} hrs'),

                  // Notas
                  if (order.notes != null &&
                      order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text('⚠️ Notas: ${order.notes}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Text('Productos Solicitados:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),

                  // Lista de productos (sin Flexible — dentro de SingleChildScrollView)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (ctx, index) {
                      final item = order.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.productName}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              Formatters.money(item.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Importe Total:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        Formatters.money(order.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.green),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text('Flujo de Estados de Cocina:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey)),
                  const SizedBox(height: 10),

                  // Botones de estado
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (order.status == 'pendiente')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.soup_kitchen, size: 16),
                          label: const Text('Cocinar'),
                          onPressed: () {
                            provider.cambiarEstadoOrden(
                                order.id, 'preparando');
                            UiUtils.showToast(
                                context, 'Orden movida a cocina',
                                color: Colors.blue);
                          },
                        ),
                      if (order.status == 'preparando')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Listo'),
                          onPressed: () {
                            provider.cambiarEstadoOrden(
                                order.id, 'lista');
                            UiUtils.showToast(
                                context, 'Orden marcada como lista',
                                color: Colors.green);
                          },
                        ),
                      if (order.status == 'lista')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.delivery_dining,
                              size: 16),
                          label: const Text('Entregar'),
                          onPressed: () {
                            provider.cambiarEstadoOrden(
                                order.id, 'entregada');
                            UiUtils.showToast(context, 'Orden despachada',
                                color: Colors.grey);
                          },
                        ),
                      if (order.status != 'entregada' &&
                          order.status != 'cancelada')
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red),
                          icon: const Icon(Icons.cancel_outlined,
                              size: 16),
                          label: const Text('Cancelar Orden'),
                          onPressed: () {
                            provider.cambiarEstadoOrden(
                                order.id, 'cancelada');
                            UiUtils.showToast(context, 'Orden cancelada',
                                color: Colors.red);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}