import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reportes_provider.dart';
import '../utils/formatters.dart';

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportesView();
  }
}

class _ReportesView extends StatelessWidget {
  const _ReportesView();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      body: SafeArea(
        child: Consumer<ReportesProvider>(builder: (context, provider, child) {
          return SingleChildScrollView(
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
                            const Text('📈 ', style: TextStyle(fontSize: 26)),
                            Text('Reportes y Analíticas',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Text(
                            'Visualiza el rendimiento de ventas y flujos financieros',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: provider.selectedPeriodo,
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                      items: provider.periodos
                          .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) provider.cambiarPeriodo(val);
                      },
                    )
                  ],
                ),
                const SizedBox(height: 25),

                // RECUADROS SUPERIORES REPARADOS
                GridView.count(
                  crossAxisCount: isDesktop ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 2.8 : 4.0,
                  children: [
                    _buildStatCard(
                        'Total de Ventas',
                        Formatters.money(provider.totalIngresos),
                        Icons.attach_money,
                        Colors.green.shade900),
                    _buildStatCard(
                        'Transacciones',
                        '${provider.totalTransacciones}',
                        Icons.receipt_long,
                        Colors.blueGrey.shade800),
                    _buildStatCard(
                        'Ticket Promedio',
                        Formatters.money(provider.ticketPromedio),
                        Icons.analytics,
                        Colors.indigo.shade900),
                  ],
                ),
                const SizedBox(height: 25),

                // BARRAS DE PROGRESO DE PAGOS REPARADAS
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Distribución por Métodos de Pago',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildPaymentTypeIndicator(
                                    'Efectivo',
                                    Formatters.money(provider.ingresosEfectivo),
                                    provider.porcentajeEfectivo,
                                    Colors.orange)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildPaymentTypeIndicator(
                                    'Tarjeta / Transf.',
                                    Formatters.money(provider.ingresosTarjeta),
                                    provider.porcentajeTarjeta,
                                    Colors.blue)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                        child: TextField(
                      decoration: InputDecoration(
                          hintText: 'Buscar transacción por concepto o ID...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onChanged: provider.onSearch,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.categoriasFiltro.map((cat) {
                    final isActive = provider.selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isActive,
                      onSelected: (_) => provider.cambiarCategoria(cat),
                      selectedColor:
                          Theme.of(context).primaryColor.withAlpha(40),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // TABLA DE RENDIMIENTO DE PRODUCTOS
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rendimiento de Productos',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                            'Datos correspondientes a: ${provider.selectedPeriodo.toLowerCase()}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        provider.productosRendimiento.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                      'No hay datos disponibles para este período'),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest),
                                  columns: const [
                                    DataColumn(
                                        label: Text('Producto',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Categoría',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Unidades',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    DataColumn(
                                        label: Text('Monto Total',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                  ],
                                  rows: provider.productosRendimiento
                                      .map((p) => DataRow(cells: [
                                            DataCell(Text(p.nombre,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500))),
                                            DataCell(Chip(
                                                label: Text(p.categoria,
                                                    style: const TextStyle(
                                                        fontSize: 10)),
                                                padding: EdgeInsets.zero)),
                                            DataCell(Text(
                                                p.unidadesVendidas.toString(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            DataCell(Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                  Formatters.money(
                                                      p.montoTotal),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green)),
                                            )),
                                          ]))
                                      .toList(),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // TABLA DE TRANSACCIONES
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: double.infinity,
                    child: provider.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(30),
                            child: Center(child: CircularProgressIndicator()))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest),
                              columns: const [
                                DataColumn(
                                    label: Text('ID',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Fecha',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Concepto',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Cat.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Pago',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Monto',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: provider.paginatedVentas
                                  .map((v) => DataRow(cells: [
                                        DataCell(Text(v.id,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey))),
                                        DataCell(Text(v.date)),
                                        DataCell(Text(v.concept)),
                                        DataCell(Chip(
                                            label: Text(v.category,
                                                style: const TextStyle(
                                                    fontSize: 10)),
                                            padding: EdgeInsets.zero)),
                                        DataCell(Text(v.paymentMethod)),
                                        DataCell(Container(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                              Formatters.money(v.amount),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green)),
                                        )),
                                      ]))
                                  .toList(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                if (provider.totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: provider.currentPage > 1
                              ? () =>
                                  provider.changePage(provider.currentPage - 1)
                              : null),
                      Text(
                          'Página ${provider.currentPage} de ${provider.totalPages}'),
                      IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: provider.currentPage < provider.totalPages
                              ? () =>
                                  provider.changePage(provider.currentPage + 1)
                              : null),
                    ],
                  )
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatCard(String l, String v, IconData i, Color c) => Card(
      color: c,
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(children: [
            Icon(i, color: Colors.white38, size: 36),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l, style: const TextStyle(color: Colors.white70)),
              Text(v,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold))
            ])
          ])));

  Widget _buildPaymentTypeIndicator(String l, String v, double p, Color c) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: p.isNaN ? 0.0 : p, color: c)
      ]);
}
