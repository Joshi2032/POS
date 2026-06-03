import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/app_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<DashboardProvider>().cargarMetricasGlobales();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _DashboardView();
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  List<FlSpot> _getSpots(List<double> data) {
    return data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }

  // ─── HELPERS DE ESCALA ────────────────────────────────────────────────────

  /// Formatea un valor al label más legible según su magnitud.
  String _formatAxisValue(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
    if (abs >= 100) return '\$${value.toStringAsFixed(0)}';
    if (abs >= 10) return '\$${value.toStringAsFixed(1)}';
    return '\$${value.toStringAsFixed(2)}';
  }

  /// Calcula el intervalo "bonito" más cercano para ~5 ticks en el rango dado.
  double _niceInterval(double range) {
    if (range <= 0) return 1;
    final raw = range / 5;
    // Potencia de 10 inmediatamente inferior al raw
    double mag = 1;
    while (mag * 10 <= raw) {
      mag *= 10;
    }
    // Candidatos bonitos: 1×, 2×, 5× la magnitud
    for (final factor in [1.0, 2.0, 5.0, 10.0]) {
      final candidate = factor * mag;
      if (candidate >= raw) return candidate;
    }
    return mag * 10;
  }

  /// Devuelve {minY, maxY, interval} con suelo y techo "bonitos".
  Map<String, double> _yScale(List<double> values,
      {bool allowNegative = false}) {
    if (values.isEmpty || values.every((v) => v == 0)) {
      return {'min': 0, 'max': 10, 'interval': 2};
    }

    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);

    // Margen del 15% en cada extremo según el signo del dato
    double rawMin;
    double rawMax;

    if (allowNegative) {
      rawMin = dataMin < 0 ? dataMin * 1.15 : 0;
      rawMax = dataMax > 0 ? dataMax * 1.15 : (dataMin < 0 ? 0 : 10);
    } else {
      rawMin = 0;
      rawMax = dataMax > 0 ? dataMax * 1.15 : 10;
    }

    // Garantizamos que el rango nunca sea cero
    if (rawMax == rawMin) rawMax = rawMin + 10;

    final double range = rawMax - rawMin;
    final double interval = _niceInterval(range);

    // Redondeamos al múltiplo de interval hacia afuera en cada extremo
    final double niceMin = (allowNegative && rawMin < 0)
        ? (rawMin / interval).floor() * interval
        : 0;
    final double niceMax = (rawMax / interval).ceil() * interval;

    if (niceMax <= niceMin) {
      return {'min': niceMin, 'max': niceMin + interval, 'interval': interval};
    }

    return {
      'min': niceMin,
      'max': niceMax,
      'interval': interval,
    };
  }

  // ─── GRÁFICA DE LÍNEAS ───────────────────────────────────────────────────

  LineChartData _buildLineChartData(
      BuildContext context, DashboardProvider provider) {
    final primaryColor = Theme.of(context).primaryColor;
    final errorColor = Theme.of(context).colorScheme.error;
    final textStyle = TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6));

    final double maxTicks = provider.currentLabels.isNotEmpty
        ? (provider.currentLabels.length - 1).toDouble()
        : 0.0;

    // Escala basada en los valores REALES de ingresos y gastos combinados
    final allValues = [...provider.currentIngresos, ...provider.currentGastos];
    final scale = _yScale(allValues);
    final double minY = scale['min']!;
    final double maxY = scale['max']!;
    final double interval = scale['interval']!;

    return LineChartData(
      minX: 0,
      maxX: maxTicks,
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final int index = value.toInt();
              if (index >= 0 && index < provider.currentLabels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(provider.currentLabels[index], style: textStyle),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 62,
            interval: interval,
            getTitlesWidget: (value, meta) {
              // Omitimos el label del techo si queda solapado
              if (value > meta.max - interval * 0.3) return const SizedBox();
              return Text(_formatAxisValue(value), style: textStyle);
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _getSpots(provider.currentIngresos),
          isCurved: true,
          color: primaryColor,
          barWidth: 3,
          dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                      radius: 4,
                      color: Theme.of(context).cardColor,
                      strokeWidth: 2,
                      strokeColor: primaryColor)),
          belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [
                primaryColor.withValues(alpha: 0.25),
                primaryColor.withValues(alpha: 0.01)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        ),
        LineChartBarData(
          spots: _getSpots(provider.currentGastos),
          isCurved: true,
          color: errorColor,
          barWidth: 3,
          dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                      radius: 4,
                      color: Theme.of(context).cardColor,
                      strokeWidth: 2,
                      strokeColor: errorColor)),
          belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [
                errorColor.withValues(alpha: 0.2),
                errorColor.withValues(alpha: 0.01)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        ),
      ],
    );
  }

  // ─── GRÁFICA DE BARRAS ───────────────────────────────────────────────────

  BarChartData _buildBarChartData(
      BuildContext context, DashboardProvider provider) {
    final barColor = Theme.of(context).primaryColor;
    final negativeColor = Theme.of(context).colorScheme.error;
    final textStyle = TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6));

    // La utilidad SÍ puede ser negativa, por eso allowNegative: true
    final scale = _yScale(provider.currentUtilidad, allowNegative: true);
    final double minY = scale['min']!;
    final double maxY = scale['max']!;
    final double interval = scale['interval']!;

    return BarChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            strokeWidth: 1,
            dashArray: [4, 4]),
      ),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 &&
                  value.toInt() < provider.currentLabels.length) {
                return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(provider.currentLabels[value.toInt()],
                        style: textStyle));
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 62,
            interval: interval,
            getTitlesWidget: (value, meta) {
              if (value > meta.max - interval * 0.3) return const SizedBox();
              return Text(_formatAxisValue(value), style: textStyle);
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: provider.currentUtilidad.asMap().entries.map((e) {
        final isNegative = e.value < 0;
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value,
              // Barras rojas si la utilidad es negativa
              color: isNegative ? negativeColor : barColor,
              width: 14,
              borderRadius: isNegative
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4))
                  : const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4)),
            )
          ],
        );
      }).toList(),
    );
  }

  // ─── BUILD PRINCIPAL ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (provider.isLoading && provider.currentLabels.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<DashboardProvider>().cargarMetricasGlobales(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: SectionHeader(
                            title: 'Dashboard',
                            subtitle: 'Resumen operativo del sistema'),
                      ),
                      IconButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => context
                                .read<DashboardProvider>()
                                .cargarMetricasGlobales(),
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        tooltip: 'Actualizar datos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Tarjetas métricas ────────────────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 700
                          ? 4
                          : constraints.maxWidth > 480
                              ? 2
                              : 1;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.45,
                        children: [
                          _buildMetricCard(context,
                              title: 'Ventas Hoy',
                              value:
                                  '\$${provider.ventasHoy.toStringAsFixed(2)}',
                              change: '+12.5%',
                              icon: Icons.attach_money,
                              isPositive: true),
                          _buildMetricCard(context,
                              title: 'Órdenes Activas',
                              value: '${provider.ordenesActivas}',
                              change: 'En cocina',
                              icon: Icons.restaurant,
                              isPositive: true),
                          _buildMetricCard(context,
                              title: 'Ingreso ${provider.labelFiltro}',
                              value:
                                  '\$${provider.ingresoFiltroTotal.toStringAsFixed(2)}',
                              change: '+8.2%',
                              icon: Icons.trending_up,
                              isPositive: true),
                          _buildMetricCard(context,
                              title: 'Utilidad ${provider.labelFiltro}',
                              value:
                                  '\$${provider.utilidadFiltroTotal.toStringAsFixed(2)}',
                              change: '+15.3%',
                              icon: Icons.account_balance_wallet,
                              isPositive: provider.utilidadFiltroTotal >= 0),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Selector de filtro ───────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).dividerColor)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.filterType,
                          dropdownColor: Theme.of(context).cardColor,
                          items: const [
                            DropdownMenuItem(
                                value: 'semana', child: Text('Esta Semana')),
                            DropdownMenuItem(
                                value: 'mes', child: Text('Este Mes')),
                            DropdownMenuItem(
                                value: 'año', child: Text('Este Año')),
                          ],
                          onChanged: (v) => provider.setFilterType(v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Gráficas ─────────────────────────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final lineW = isWide
                          ? constraints.maxWidth * 0.58
                          : constraints.maxWidth;
                      final barW = isWide
                          ? constraints.maxWidth * 0.38
                          : constraints.maxWidth;

                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: lineW,
                                    child: AppCard(
                                        key: ValueKey(
                                            'line_${provider.filterType}'),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildChartLegend(context),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                  height: 300,
                                                  child: LineChart(
                                                      _buildLineChartData(
                                                          context, provider)))
                                            ]))),
                                const SizedBox(width: 16),
                                SizedBox(
                                    width: barW,
                                    child: AppCard(
                                        key: ValueKey(
                                            'bar_${provider.filterType}'),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Utilidad neta',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                  height: 300,
                                                  child: BarChart(
                                                      _buildBarChartData(
                                                          context, provider)))
                                            ]))),
                              ],
                            )
                          : Column(
                              children: [
                                AppCard(
                                    key: ValueKey(
                                        'line_mobile_${provider.filterType}'),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildChartLegend(context),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                              height: 260,
                                              child: LineChart(
                                                  _buildLineChartData(
                                                      context, provider)))
                                        ])),
                                const SizedBox(height: 16),
                                AppCard(
                                    key: ValueKey(
                                        'bar_mobile_${provider.filterType}'),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Utilidad neta',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                              height: 260,
                                              child: BarChart(
                                                  _buildBarChartData(
                                                      context, provider)))
                                        ])),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Tabla de productos ───────────────────────────────────
                  _buildPremiumProductTable(context, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── LEYENDA DE LA GRÁFICA DE LÍNEAS ────────────────────────────────────

  Widget _buildChartLegend(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final error = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        Expanded(
          child: Text('Flujo Financiero',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        _legendDot(color: primary, label: 'Ingresos', context: context),
        const SizedBox(width: 16),
        _legendDot(color: error, label: 'Gastos', context: context),
      ],
    );
  }

  Widget _legendDot(
      {required Color color,
      required String label,
      required BuildContext context}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7))),
      ],
    );
  }

  // ─── TARJETA DE MÉTRICA ──────────────────────────────────────────────────

  Widget _buildMetricCard(BuildContext context,
      {required String title,
      required String value,
      required String change,
      required IconData icon,
      required bool isPositive}) {
    final trendColor =
        isPositive ? Colors.green : Theme.of(context).colorScheme.error;
    return AppCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6)))),
              const SizedBox(width: 8),
              Icon(icon, color: Theme.of(context).primaryColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 3,
            runSpacing: 1,
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: trendColor, size: 12),
              Text(change,
                  style: TextStyle(
                      color: trendColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text('vs anterior',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TABLA DE PRODUCTOS ──────────────────────────────────────────────────

  Widget _buildPremiumProductTable(
      BuildContext context, DashboardProvider provider) {
    final theme = Theme.of(context);
    final textStyleHeader = TextStyle(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        fontSize: 14);
    final textStyleRow =
        TextStyle(color: theme.colorScheme.onSurface, fontSize: 13);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rendimiento de Productos',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        'Datos correspondientes a: ${provider.labelFiltro.toLowerCase()}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ],
                ),
                Icon(Icons.assessment_outlined,
                    color: theme.primaryColor.withValues(alpha: 0.7)),
              ],
            ),
          ),
          Container(
            color: theme.primaryColor.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Expanded(
                    flex: 3, child: Text('Producto', style: textStyleHeader)),
                Expanded(
                    flex: 2, child: Text('Categoría', style: textStyleHeader)),
                Expanded(
                    flex: 2,
                    child: Text('Unidades',
                        style: textStyleHeader, textAlign: TextAlign.center)),
                Expanded(
                    flex: 2,
                    child: Text('Monto Total',
                        style: textStyleHeader, textAlign: TextAlign.right)),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12)),
            child: provider.currentProductos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Sin ventas en el período seleccionado',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                            fontSize: 13),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: provider.currentProductos
                          .asMap()
                          .entries
                          .map((entry) {
                        final int index = entry.key;
                        final prod = entry.value;
                        final rowColor = index % 2 == 0
                            ? Colors.transparent
                            : theme.primaryColor.withValues(alpha: 0.015);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                              color: rowColor,
                              border: Border(
                                  bottom: BorderSide(
                                      color: theme.dividerColor
                                          .withValues(alpha: 0.2),
                                      width: 0.5))),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text(prod.nombre,
                                      style: textStyleRow.copyWith(
                                          fontWeight: FontWeight.w600))),
                              Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(prod.categoria,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  )),
                              Expanded(
                                  flex: 2,
                                  child: Text('${prod.unidadesVendidas}',
                                      style: textStyleRow.copyWith(
                                          fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  flex: 2,
                                  child: Text(
                                      '\$${prod.montoTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                      textAlign: TextAlign.right)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
