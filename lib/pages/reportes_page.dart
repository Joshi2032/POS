import 'package:flutter/material.dart';

// ==========================================
// MODELOS DE DATOS (Mapeo de estructuras de reportes)
// ==========================================
class VentaReporte {
  final String id;
  final String date;
  final String concept;
  final String category;
  final double amount;
  final String paymentMethod;

  VentaReporte({
    required this.id,
    required this.date,
    required this.concept,
    required this.category,
    required this.amount,
    required this.paymentMethod,
  });
}

// ==========================================
// COMPONENTE PRINCIPAL (ReportesComponent)
// ==========================================
class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  final int pageSize = 10;
  final List<String> periodos = ['Hoy', 'Esta Semana', 'Este Mes', 'Histórico'];
  final List<String> categoriasFiltro = [
    'Todos',
    'Alimentos',
    'Bebidas',
    'Combos',
    'Otros'
  ];

  // Estados locales que simulan los Signals de Angular
  String selectedPeriodo = 'Este Mes';
  String selectedCategory = 'Todos';
  String searchTerm = '';
  int currentPage = 1;

  List<VentaReporte> historialVentas = [];

  @override
  void initState() {
    super.initState();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Semilla de datos simulando el histórico analítico del POS
    historialVentas = [
      VentaReporte(
          id: 'V-001',
          date: todayStr,
          concept: 'Paquete Familiar + Bebidas',
          category: 'Combos',
          amount: 450.00,
          paymentMethod: 'Tarjeta'),
      VentaReporte(
          id: 'V-002',
          date: todayStr,
          concept: 'Orden de Tacos de Asada (3)',
          category: 'Alimentos',
          amount: 105.00,
          paymentMethod: 'Efectivo'),
      VentaReporte(
          id: 'V-003',
          date: todayStr,
          concept: 'Mezcal Artesanal Copa',
          category: 'Bebidas',
          amount: 75.00,
          paymentMethod: 'Efectivo'),
      VentaReporte(
          id: 'V-004',
          date: todayStr,
          concept: 'Hamburguesa Zapata Especial',
          category: 'Alimentos',
          amount: 120.00,
          paymentMethod: 'Transferencia'),
      VentaReporte(
          id: 'V-005',
          date: todayStr,
          concept: 'Agua de Jamaica Litro',
          category: 'Bebidas',
          amount: 40.00,
          paymentMethod: 'Tarjeta'),
    ];
  }

  // LÓGICA COMPUTADA (computed) de Angular adaptada a getters de Dart
  List<VentaReporte> get filteredVentas {
    final query = searchTerm.trim().toLowerCase();
    final cat = selectedCategory;

    return historialVentas.where((v) {
      // Solucionado: Uso de .contains() en lugar de .includes() de JS
      final matchesSearch = query.isEmpty ||
          v.concept.toLowerCase().contains(query) ||
          v.id.toLowerCase().contains(query) ||
          v.paymentMethod.toLowerCase().contains(query);

      final matchesCategory = cat == 'Todos' || v.category == cat;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<VentaReporte> get paginatedVentas {
    final list = filteredVentas;
    final start = (currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    final end =
        (start + pageSize) > list.length ? list.length : (start + pageSize);
    return list.sublist(start, end);
  }

  int get totalPages => (filteredVentas.length / pageSize).ceil();

  // MÉTRICAS DE RENDIMIENTO ESTADÍSTICO (Reduce / Folds)
  double get totalIngresos =>
      filteredVentas.fold(0.0, (sum, v) => sum + v.amount);

  int get totalTransacciones => filteredVentas.length;

  double get ticketPromedio =>
      totalTransacciones > 0 ? totalIngresos / totalTransacciones : 0.0;

  double get ingresosEfectivo => filteredVentas
      .where((v) => v.paymentMethod == 'Efectivo')
      .fold(0.0, (sum, v) => sum + v.amount);

  double get ingresosTarjeta => filteredVentas
      .where((v) => v.paymentMethod == 'Tarjeta')
      .fold(0.0, (sum, v) => sum + v.amount);

  // MÉTODOS DE MANEJO DE EVENTOS (TS)
  void onSearch(String value) {
    setState(() {
      searchTerm = value;
      currentPage = 1;
    });
  }

  void cambiarPeriodo(String periodo) {
    setState(() {
      selectedPeriodo = periodo;
      currentPage = 1;
      // Aquí se dispararía habitualmente la consulta al service según el periodo
    });
  }

  void cambiarCategoria(String categoria) {
    setState(() {
      selectedCategory = categoria;
      currentPage = 1;
    });
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // ==========================================
  // DISPOSICIÓN DE LA INTERFAZ DE USUARIO (HTML)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isDesktop = screenWidth > 950;
            final isCompact = screenWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    spacing: 12,
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
                        value: selectedPeriodo,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                        items: periodos
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) cambiarPeriodo(val);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
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
                          _formatMoney(totalIngresos),
                          Icons.attach_money,
                          Colors.green.shade900),
                      _buildStatCard('Transacciones', '$totalTransacciones',
                          Icons.receipt_long, Colors.blueGrey.shade800),
                      _buildStatCard(
                          'Ticket Promedio',
                          _formatMoney(ticketPromedio),
                          Icons.analytics,
                          Colors.indigo.shade900),
                    ],
                  ),
                  const SizedBox(height: 25),
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
                          if (isCompact)
                            Column(
                              children: [
                                _buildPaymentTypeIndicator(
                                    'Efectivo',
                                    _formatMoney(ingresosEfectivo),
                                    Colors.orange),
                                const SizedBox(height: 16),
                                _buildPaymentTypeIndicator('Tarjeta / Transf.',
                                    _formatMoney(ingresosTarjeta), Colors.blue),
                              ],
                            )
                          else
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: (constraints.maxWidth - 56) / 2,
                                  child: _buildPaymentTypeIndicator(
                                      'Efectivo',
                                      _formatMoney(ingresosEfectivo),
                                      Colors.orange),
                                ),
                                SizedBox(
                                  width: (constraints.maxWidth - 56) / 2,
                                  child: _buildPaymentTypeIndicator(
                                      'Tarjeta / Transf.',
                                      _formatMoney(ingresosTarjeta),
                                      Colors.blue),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar transacción por concepto o ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: onSearch,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoriasFiltro.map((cat) {
                      final isActive = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isActive,
                        onSelected: (_) => cambiarCategoria(cat),
                        selectedColor:
                            Theme.of(context).primaryColor.withAlpha(40),
                        labelStyle: TextStyle(
                          color: isActive
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade700,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('${filteredVentas.length} transacción(es) registrada(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
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
                                label: Text('Categoría',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Método',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Monto',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: paginatedVentas.map((v) {
                            return DataRow(cells: [
                              DataCell(Text(v.id,
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold))),
                              DataCell(Text(v.date)),
                              DataCell(Text(v.concept)),
                              DataCell(Text(v.category)),
                              DataCell(Text(v.paymentMethod)),
                              DataCell(Text(_formatMoney(v.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  if (paginatedVentas.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(32),
                      child: const Text(
                          'No hay transacciones registradas para este filtro.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  const SizedBox(height: 15),
                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage == 1
                              ? null
                              : () => setState(() => currentPage--),
                        ),
                        Text('Página $currentPage de $totalPages',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage == totalPages
                              ? null
                              : () => setState(() => currentPage++),
                        ),
                      ],
                    )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper para construir tarjetas de KPIs principales
  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper para construir la barra distributiva analítica de pagos
  Widget _buildPaymentTypeIndicator(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: totalIngresos > 0
              ? (double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ??
                      0) /
                  totalIngresos
              : 0,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }
}
