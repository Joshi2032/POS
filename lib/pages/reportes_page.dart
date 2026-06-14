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
    return Scaffold(
      body: SafeArea(
        child: Consumer<ReportesProvider>(
          builder: (context, provider, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final hPad = w < 480 ? 16.0 : 20.0;
                final isCompact = w < 600;
                final isWide = w >= 950;

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── HEADER ─────────────────────────────────────
                          if (isCompact) ...[
                            _HeaderTitle(),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _PeriodoPicker(provider: provider),
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _HeaderTitle()),
                                const SizedBox(width: 16),
                                _PeriodoPicker(provider: provider),
                              ],
                            ),
                          ],

                          const SizedBox(height: 22),

                          // ── STAT CARDS ──────────────────────────────────
                          if (isWide)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Total de Ventas',
                                      value: Formatters.money(
                                          provider.totalIngresos),
                                      icon: Icons.attach_money,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Transacciones',
                                      value:
                                          '${provider.totalTransacciones}',
                                      icon: Icons.receipt_long,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Ticket Promedio',
                                      value: Formatters.money(
                                          provider.ticketPromedio),
                                      icon: Icons.analytics,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                _StatCard(
                                  label: 'Total de Ventas',
                                  value: Formatters.money(
                                      provider.totalIngresos),
                                  icon: Icons.attach_money,
                                  color: Colors.green.shade900,
                                ),
                                const SizedBox(height: 12),
                                // En tablet (600-950) las otras dos en fila
                                if (isCompact) ...[
                                  _StatCard(
                                    label: 'Transacciones',
                                    value:
                                        '${provider.totalTransacciones}',
                                    icon: Icons.receipt_long,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatCard(
                                    label: 'Ticket Promedio',
                                    value: Formatters.money(
                                        provider.ticketPromedio),
                                    icon: Icons.analytics,
                                    color: Colors.indigo.shade900,
                                  ),
                                ] else ...[
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _StatCard(
                                            label: 'Transacciones',
                                            value:
                                                '${provider.totalTransacciones}',
                                            icon: Icons.receipt_long,
                                            color:
                                                Colors.blueGrey.shade800,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _StatCard(
                                            label: 'Ticket Promedio',
                                            value: Formatters.money(
                                                provider.ticketPromedio),
                                            icon: Icons.analytics,
                                            color: Colors.indigo.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                          const SizedBox(height: 22),

                          // ── MÉTODOS DE PAGO ─────────────────────────────
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Distribución por Métodos de Pago',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 14),
                                  // En móvil apilados, en tablet+ en fila
                                  if (isCompact)
                                    Column(
                                      children: [
                                        _PaymentIndicator(
                                          label: 'Efectivo',
                                          value: Formatters.money(
                                              provider.ingresosEfectivo),
                                          percent:
                                              provider.porcentajeEfectivo,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(height: 14),
                                        _PaymentIndicator(
                                          label: 'Tarjeta / Transf.',
                                          value: Formatters.money(
                                              provider.ingresosTarjeta),
                                          percent:
                                              provider.porcentajeTarjeta,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _PaymentIndicator(
                                            label: 'Efectivo',
                                            value: Formatters.money(
                                                provider.ingresosEfectivo),
                                            percent:
                                                provider.porcentajeEfectivo,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _PaymentIndicator(
                                            label: 'Tarjeta / Transf.',
                                            value: Formatters.money(
                                                provider.ingresosTarjeta),
                                            percent:
                                                provider.porcentajeTarjeta,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ── BUSCADOR ────────────────────────────────────
                          TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar transacción por concepto o ID...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: provider.onSearch,
                          ),

                          const SizedBox(height: 14),

                          // ── CHIPS ───────────────────────────────────────
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                provider.categoriasFiltro.map((cat) {
                              final isActive =
                                  provider.selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isActive,
                                onSelected: (_) =>
                                    provider.cambiarCategoria(cat),
                                selectedColor: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(40),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // ── TABLA PRODUCTOS ─────────────────────────────
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rendimiento de Productos',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Datos correspondientes a: ${provider.selectedPeriodo.toLowerCase()}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 14),
                                  if (provider
                                      .productosRendimiento.isEmpty)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                            'No hay datos disponibles para este período'),
                                      ),
                                    )
                                  else if (isCompact)
                                    // Móvil: cards en lugar de tabla
                                    Column(
                                      children: provider.productosRendimiento
                                          .map((p) => _ProductoCard(
                                              producto: p))
                                          .toList(),
                                    )
                                  else
                                    LayoutBuilder(
                                      builder: (ctx, cs) =>
                                          SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              minWidth: cs.maxWidth),
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                            columns: const [
                                              DataColumn(
                                                  label: Text('Producto',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold))),
                                              DataColumn(
                                                  label: Text('Categoría',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold))),
                                              DataColumn(
                                                  label: Text('Unidades',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold))),
                                              DataColumn(
                                                  label: Text('Monto Total',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold))),
                                            ],
                                            rows: provider
                                                .productosRendimiento
                                                .map((p) => DataRow(
                                                      cells: [
                                                        DataCell(Text(
                                                            p.nombre,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500))),
                                                        DataCell(Chip(
                                                            label: Text(
                                                                p.categoria,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        10)),
                                                            padding:
                                                                EdgeInsets
                                                                    .zero)),
                                                        DataCell(Text(
                                                            p.unidadesVendidas
                                                                .toString(),
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold))),
                                                        DataCell(
                                                          Container(
                                                            alignment:
                                                                Alignment
                                                                    .centerRight,
                                                            child: Text(
                                                              Formatters.money(
                                                                  p.montoTotal),
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .green),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── TABLA TRANSACCIONES ─────────────────────────
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: provider.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(30),
                                    child: Center(
                                        child:
                                            CircularProgressIndicator()),
                                  )
                                : isCompact
                                    // Móvil: lista de cards
                                    ? Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: provider.paginatedVentas
                                              .map((v) =>
                                                  _TransaccionCard(venta: v))
                                              .toList(),
                                        ),
                                      )
                                    // Tablet+: DataTable con scroll horizontal
                                    : LayoutBuilder(
                                        builder: (ctx, cs) =>
                                            SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                                minWidth: cs.maxWidth),
                                            child: DataTable(
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                              ),
                                              columns: const [
                                                DataColumn(
                                                    label: Text('ID',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                DataColumn(
                                                    label: Text('Fecha',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                DataColumn(
                                                    label: Text('Concepto',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                DataColumn(
                                                    label: Text('Cat.',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                DataColumn(
                                                    label: Text('Pago',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                DataColumn(
                                                    label: Text('Monto',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                              ],
                                              rows: provider.paginatedVentas
                                                  .map((v) => DataRow(
                                                        cells: [
                                                          DataCell(Text(
                                                              v.id,
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .grey))),
                                                          DataCell(Text(
                                                              v.date)),
                                                          DataCell(Text(
                                                              v.concept)),
                                                          DataCell(Chip(
                                                            label: Text(
                                                                v.category,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        10)),
                                                            padding:
                                                                EdgeInsets
                                                                    .zero,
                                                          )),
                                                          DataCell(Text(
                                                              v.paymentMethod)),
                                                          DataCell(
                                                            Container(
                                                              alignment:
                                                                  Alignment
                                                                      .centerRight,
                                                              child: Text(
                                                                Formatters.money(
                                                                    v.amount),
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .green),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                          ),

                          const SizedBox(height: 14),

                          // ── PAGINACIÓN ──────────────────────────────────
                          if (provider.totalPages > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: provider.currentPage > 1
                                      ? () => provider.changePage(
                                          provider.currentPage - 1)
                                      : null,
                                ),
                                Text(
                                  'Página ${provider.currentPage} de ${provider.totalPages}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: provider.currentPage <
                                          provider.totalPages
                                      ? () => provider.changePage(
                                          provider.currentPage + 1)
                                      : null,
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
            );
          },
        ),
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

class _HeaderTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📈 ', style: TextStyle(fontSize: 24)),
            Flexible(
              child: Text(
                'Reportes y Analíticas',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const Text(
          'Visualiza el rendimiento de ventas y flujos financieros',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}

class _PeriodoPicker extends StatelessWidget {
  const _PeriodoPicker({required this.provider});
  final ReportesProvider provider;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: provider.selectedPeriodo,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.arrow_drop_down_circle_outlined),
      items: provider.periodos
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: (val) {
        if (val != null) provider.cambiarPeriodo(val);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentIndicator extends StatelessWidget {
  const _PaymentIndicator({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });
  final String label;
  final String value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
            value: percent.isNaN ? 0.0 : percent, color: color),
      ],
    );
  }
}

// Card de producto para vista móvil
class _ProductoCard extends StatelessWidget {
  const _ProductoCard({required this.producto});
  final dynamic producto;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(producto.categoria,
                        style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${producto.unidadesVendidas} uds.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.money(producto.montoTotal),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Card de transacción para vista móvil
class _TransaccionCard extends StatelessWidget {
  const _TransaccionCard({required this.venta});
  final dynamic venta;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(venta.concept,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  Formatters.money(venta.amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _InfoItem(Icons.tag, venta.id,
                    color: Colors.grey),
                _InfoItem(Icons.calendar_today, venta.date),
                _InfoItem(Icons.payment, venta.paymentMethod),
                _InfoItem(Icons.label_outline, venta.category),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? Colors.grey),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: color ?? Colors.grey)),
      ],
    );
  }
}