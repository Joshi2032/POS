import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reportes_provider.dart';
import '../utils/formatters.dart';

// ==========================================
// COMPONENTE PRINCIPAL DE INTERFAZ (UI)
// ==========================================
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
    
    // Conectamos la UI a nuestro Provider
    final provider = context.watch<ReportesProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO Y SELECTOR DE PERIODO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📈 ', style: TextStyle(fontSize: 26)),
                          Text('Reportes y Analíticas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('Visualiza el rendimiento de ventas y flujos financieros', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  DropdownButton<String>(
                    value: provider.selectedPeriodo,
                    underline: Container(),
                    icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                    items: provider.periodos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) {
                      if (val != null) provider.cambiarPeriodo(val);
                    },
                  )
                ],
              ),
              const SizedBox(height: 25),

              // MÉTRICAS PRINCIPALES
              GridView.count(
                crossAxisCount: isDesktop ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 2.8 : 4.0,
                children: [
                  _buildStatCard('Total de Ventas', Formatters.money(provider.totalIngresos), Icons.attach_money, Colors.green.shade900),
                  _buildStatCard('Transacciones', '${provider.totalTransacciones}', Icons.receipt_long, Colors.blueGrey.shade800),
                  _buildStatCard('Ticket Promedio', Formatters.money(provider.ticketPromedio), Icons.analytics, Colors.indigo.shade900),
                ],
              ),
              const SizedBox(height: 25),

              // DISTRIBUCIÓN DE MÉTODOS DE PAGO
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distribución por Métodos de Pago', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildPaymentTypeIndicator('Efectivo', Formatters.money(provider.ingresosEfectivo), provider.porcentajeEfectivo, Colors.orange)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPaymentTypeIndicator('Tarjeta / Transf.', Formatters.money(provider.ingresosTarjeta), provider.porcentajeTarjeta, Colors.blue)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // BÚSQUEDA
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar transacción por concepto o ID...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: provider.onSearch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // FILTROS DE CATEGORÍA
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.categoriasFiltro.map((cat) {
                  final isActive = provider.selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isActive,
                    onSelected: (_) => provider.cambiarCategoria(cat),
                    selectedColor: Theme.of(context).primaryColor.withAlpha(40),
                    labelStyle: TextStyle(
                        color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade700,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // TABLA DE DATOS
              Text('${provider.filteredVentas.length} transacción(es) registrada(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Concepto', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: provider.paginatedVentas.map((v) {
                        return DataRow(cells: [
                          DataCell(Text(v.id, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                          DataCell(Text(v.date)),
                          DataCell(Text(v.concept)),
                          DataCell(Text(v.category)),
                          DataCell(Text(v.paymentMethod)),
                          DataCell(Text(Formatters.money(v.amount), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),

              if (provider.paginatedVentas.isEmpty)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(32),
                  child: const Text('No hay transacciones registradas para este filtro.', style: TextStyle(color: Colors.grey)),
                ),
              const SizedBox(height: 15),

              // PAGINACIÓN
              if (provider.totalPages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: provider.currentPage == 1 ? null : () => provider.changePage(provider.currentPage - 1),
                    ),
                    Text('Página ${provider.currentPage} de ${provider.totalPages}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: provider.currentPage == provider.totalPages ? null : () => provider.changePage(provider.currentPage + 1),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  // Helpers visuales
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeIndicator(String label, String value, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage, // El cálculo ahora se hace en el cerebro, aquí solo pintamos
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }
}