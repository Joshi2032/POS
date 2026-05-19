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
    final Map<OrderStatus, String> labels = {
      'pendiente': 'Pendiente',
      'preparando': 'En Cocina',
      'lista': 'Lista para Entrega',
      'entregada': 'Entregada',
      'cancelada': 'Cancelada'
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 950;
    final provider = context.watch<OrdenesProvider>();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('📋 ', style: TextStyle(fontSize: 26)),
                              Text('Módulo de Órdenes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Text(
                              'Monitoreo en tiempo real de comandas y despachos',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          _buildTopStatusIndicator('Activas',
                              '${provider.activeOrdersCount}', Colors.blue),
                          const SizedBox(width: 12),
                          _buildTopStatusIndicator('Listas',
                              '${provider.readyOrdersCount}', Colors.green),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(
                            flex: isDesktop ? 4 : 0,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText:
                                    'Buscar por ID de orden o cliente/mesa...',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                              ),
                              onChanged: provider.onSearchChange,
                            ),
                          ),
                          if (!isDesktop) const Divider(),
                          if (isDesktop)
                            const VerticalDivider(width: 24, thickness: 1),
                          Expanded(
                            flex: isDesktop ? 2 : 0,
                            child: DropdownButtonFormField<String>(
                              initialValue: provider.selectedFilterStatus,
                              decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: InputBorder.none),
                              items: [
                                'Todos',
                                'Pendiente',
                                'Preparando',
                                'Lista',
                                'Entregada',
                                'Cancelada'
                              ]
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) =>
                                  provider.onStatusFilterChange(val ?? 'Todos'),
                            ),
                          ),
                          if (isDesktop)
                            const VerticalDivider(width: 24, thickness: 1),
                          Expanded(
                            flex: isDesktop ? 2 : 0,
                            child: DropdownButtonFormField<String>(
                              initialValue: provider.selectedFilterService,
                              decoration: const InputDecoration(
                                  labelText: 'Servicio',
                                  border: InputBorder.none),
                              items: ['Todos', 'Comedor', 'Llevar', 'Domicilio']
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) => provider
                                  .onServiceFilterChange(val ?? 'Todos'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                          '${provider.filteredOrders.length} orden(es) encontrada(s)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (provider.filteredOrders.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      child: const Column(
                        children: [
                          Text('🍳', style: TextStyle(fontSize: 54)),
                          SizedBox(height: 12),
                          Text(
                              'No hay órdenes activas que coincidan con los filtros.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 1.4 : 1.9,
                    ),
                    itemCount: provider.paginatedOrders.length,
                    itemBuilder: (context, index) {
                      final order = provider.paginatedOrders[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => provider.abrirDetalleModal(order),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(order.id,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.grey)),
                                    Text('🕒 ${order.time}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(order.tableOrCustomer,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _getStatusColor(order.status),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(_getStatusLabel(order.status),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(_getServiceLabel(order.serviceType),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.blueGrey)),
                                const Divider(),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: order.items.length > 2
                                        ? 2
                                        : order.items.length,
                                    itemBuilder: (ctx, idx) {
                                      final item = order.items[idx];
                                      return Text(
                                          '${item.quantity}x ${item.productName}',
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis);
                                    },
                                  ),
                                ),
                                if (order.items.length > 2)
                                  Text(
                                      '+ ${order.items.length - 2} productos más...',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Total: ${Formatters.money(order.totalAmount)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 14, color: Colors.grey),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  if (provider.totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: provider.currentPage == 1
                              ? null
                              : () =>
                                  provider.goToPage(provider.currentPage - 1),
                        ),
                        Text(
                            'Página ${provider.currentPage} de ${provider.totalPages}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: provider.currentPage == provider.totalPages
                              ? null
                              : () =>
                                  provider.goToPage(provider.currentPage + 1),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),
          if (provider.showModal && provider.selectedOrderForModal != null) ...[
            GestureDetector(
              onTap: provider.cerrarModal,
              child: Container(color: Colors.black54),
            ),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isDesktop ? 500 : double.infinity,
                margin: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Detalle de Comanda: ${provider.selectedOrderForModal!.id}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: provider.cerrarModal),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                            'Cliente/Mesa: ${provider.selectedOrderForModal!.tableOrCustomer}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(
                            'Tipo de Servicio: ${_getServiceLabel(provider.selectedOrderForModal!.serviceType)}',
                            style: const TextStyle(color: Colors.blueGrey)),
                        Text(
                            'Hora de Registro: ${provider.selectedOrderForModal!.time} hrs'),
                        if (provider.selectedOrderForModal!.notes != null &&
                            provider
                                .selectedOrderForModal!.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange)),
                            child: Text(
                                '⚠️ Notas: ${provider.selectedOrderForModal!.notes}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          )
                        ],
                        const SizedBox(height: 16),
                        const Text('Productos Solicitados:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount:
                                provider.selectedOrderForModal!.items.length,
                            itemBuilder: (ctx, index) {
                              final item =
                                  provider.selectedOrderForModal!.items[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${item.quantity}x ${item.productName}',
                                        style: const TextStyle(fontSize: 14)),
                                    Text(Formatters.money(item.total),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Importe Total:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                                Formatters.money(provider
                                    .selectedOrderForModal!.totalAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Flujo de Estados de Cocina:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (provider.selectedOrderForModal!.status ==
                                'pendiente')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white),
                                icon: const Icon(Icons.soup_kitchen),
                                label: const Text('Cocinar'),
                                onPressed: () {
                                  if (provider.cambiarEstadoOrden(
                                      provider.selectedOrderForModal!.id,
                                      'preparando')) {
                                    UiUtils.showToast(
                                        context, 'Orden movida a cocina',
                                        color: Colors.blue);
                                  }
                                },
                              ),
                            if (provider.selectedOrderForModal!.status ==
                                'preparando')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white),
                                icon: const Icon(Icons.check),
                                label: const Text('Listo'),
                                onPressed: () {
                                  if (provider.cambiarEstadoOrden(
                                      provider.selectedOrderForModal!.id,
                                      'lista')) {
                                    UiUtils.showToast(
                                        context, 'Orden marcada como lista',
                                        color: Colors.green);
                                  }
                                },
                              ),
                            if (provider.selectedOrderForModal!.status ==
                                'lista')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white),
                                icon: const Icon(Icons.delivery_dining),
                                label: const Text('Entregar'),
                                onPressed: () {
                                  if (provider.cambiarEstadoOrden(
                                      provider.selectedOrderForModal!.id,
                                      'entregada')) {
                                    UiUtils.showToast(
                                        context, 'Orden despachada',
                                        color: Colors.grey);
                                  }
                                },
                              ),
                            if (provider.selectedOrderForModal!.status !=
                                    'entregada' &&
                                provider.selectedOrderForModal!.status !=
                                    'cancelada')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    foregroundColor: Colors.red),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancelar Orden'),
                                onPressed: () {
                                  if (provider.cambiarEstadoOrden(
                                      provider.selectedOrderForModal!.id,
                                      'cancelada')) {
                                    UiUtils.showToast(
                                        context, 'Orden cancelada',
                                        color: Colors.red);
                                  }
                                },
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTopStatusIndicator(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5)),
      child: Row(
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
