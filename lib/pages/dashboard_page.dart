import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/app_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

  LineChartData _buildLineChartData(
      BuildContext context, DashboardProvider provider) {
    final primaryColor = Theme.of(context).primaryColor;
    final errorColor = Theme.of(context).colorScheme.error;
    final textStyle = TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6));

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
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
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 &&
                  value.toInt() < provider.currentLabels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(provider.currentLabels[value.toInt()],
                      style: textStyle),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) => Text(
                '\$${(value / 1000).toStringAsFixed(0)}k',
                style: textStyle),
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

  BarChartData _buildBarChartData(
      BuildContext context, DashboardProvider provider) {
    final barColor = Theme.of(context).primaryColor;
    final textStyle = TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6));

    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
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
            reservedSize: 50,
            getTitlesWidget: (value, meta) => Text(
                '\$${(value / 1000).toStringAsFixed(0)}k',
                style: textStyle),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: provider.currentUtilidad.asMap().entries.map((e) {
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
                toY: e.value,
                color: barColor,
                width: 14,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4), topRight: Radius.circular(4)))
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                    title: 'Dashboard',
                    subtitle: 'Resumen operativo del sistema'),
                const SizedBox(height: 24),
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
                      childAspectRatio: 1.58,
                      children: [
                        _buildMetricCard(context,
                            title: 'Ventas Hoy',
                            value: '\$12,700.00',
                            change: '+12.5%',
                            icon: Icons.attach_money,
                            isPositive: true),
                        _buildMetricCard(context,
                            title: 'Órdenes Activas',
                            value: '4',
                            change: 'En cocina',
                            icon: Icons.restaurant,
                            isPositive: true),
                        _buildMetricCard(context,
                            title: 'Ingreso Semanal',
                            value: '\$161,600.00',
                            change: '+8.2%',
                            icon: Icons.trending_up,
                            isPositive: true),
                        _buildMetricCard(context,
                            title: 'Utilidad Semanal',
                            value: '\$107,800.00',
                            change: '+15.3%',
                            icon: Icons.account_balance_wallet,
                            isPositive: true),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Theme.of(context).dividerColor)),
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
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text('Flujo Financiero',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
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
                                            child: BarChart(_buildBarChartData(
                                                context, provider)))
                                      ]))),
                            ],
                          )
                        : Column(
                            children: [
                              AppCard(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('Flujo Financiero',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                        height: 260,
                                        child: LineChart(_buildLineChartData(
                                            context, provider)))
                                  ])),
                              const SizedBox(height: 16),
                              AppCard(
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
                                        child: BarChart(_buildBarChartData(
                                            context, provider)))
                                  ])),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 32),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rendimiento de Productos',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      _buildThemeTable(context, [
                        'Producto',
                        'Categoría',
                        'Unidades Vendidas',
                        'Monto Total'
                      ], [
                        ['Arrachera 300g', 'Parrilla', '142', '\$40,470.00'],
                        ['Cerveza Artesanal', 'Bebidas', '320', '\$27,200.00'],
                        ['T-Bone 500g', 'Parrilla', '45', '\$20,250.00']
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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

  Widget _buildThemeTable(
      BuildContext context, List<String> columns, List<List<String>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
        rows: rows
            .map((row) => DataRow(
                cells: row
                    .map((cell) => DataCell(Text(cell,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface))))
                    .toList()))
            .toList(),
      ),
    );
  }
}
