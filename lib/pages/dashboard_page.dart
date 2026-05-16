import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _filterType = 'semana';

  // Datos financieros replicados del modelo web original
  final List<String> weekLabels = ['mar', 'mié', 'jue', 'vie', 'sab', 'dom', 'lun'];
  final List<double> weekIngresos = [12000, 15000, 9000, 18000, 21000, 24000, 7000];
  final List<double> weekGastos = [6000, 8000, 7000, 9000, 11000, 12000, 5000];
  final List<double> weekUtilidad = [6000, 7000, 2000, 9000, 10000, 12000, 2000];

  final List<String> monthLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
  final List<double> monthIngresos = [52000, 48000, 61000, 57000];
  final List<double> monthGastos = [26000, 22000, 31000, 27000];
  final List<double> monthUtilidad = [26000, 26000, 30000, 30000];

  final List<String> yearLabels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  final List<double> yearIngresos = [210000, 220000, 205000, 230000, 240000, 250000, 260000, 255000, 245000, 235000, 225000, 215000];
  final List<double> yearGastos = [110000, 115000, 108000, 120000, 125000, 130000, 135000, 132000, 128000, 124000, 120000, 118000];
  final List<double> yearUtilidad = [100000, 105000, 97000, 110000, 115000, 120000, 125000, 123000, 117000, 111000, 105000, 97000];

  List<FlSpot> _getSpots(List<double> data) {
    return data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  LineChartData _buildLineChartData(BuildContext context) {
    List<double> currentIngresos;
    List<double> currentGastos;
    List<String> currentLabels;

    switch (_filterType) {
      case 'mes':
        currentIngresos = monthIngresos;
        currentGastos = monthGastos;
        currentLabels = monthLabels;
        break;
      case 'año':
        currentIngresos = yearIngresos;
        currentGastos = yearGastos;
        currentLabels = yearLabels;
        break;
      case 'semana':
      default:
        currentIngresos = weekIngresos;
        currentGastos = weekGastos;
        currentLabels = weekLabels;
        break;
    }

    final primaryColor = Theme.of(context).primaryColor;
    final errorColor = Theme.of(context).colorScheme.error;
    final textStyle = TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6));

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
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < currentLabels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(currentLabels[value.toInt()], style: textStyle),
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
              style: textStyle,
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _getSpots(currentIngresos),
          isCurved: true,
          color: primaryColor,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Theme.of(context).cardColor,
              strokeWidth: 2,
              strokeColor: primaryColor,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [primaryColor.withValues(alpha: 0.25), primaryColor.withValues(alpha: 0.01)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        LineChartBarData(
          spots: _getSpots(currentGastos),
          isCurved: true,
          color: errorColor,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Theme.of(context).cardColor,
              strokeWidth: 2,
              strokeColor: errorColor,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [errorColor.withValues(alpha: 0.2), errorColor.withValues(alpha: 0.01)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(BuildContext context) {
    List<double> currentUtilidad;
    List<String> currentLabels;

    switch (_filterType) {
      case 'mes':
        currentUtilidad = monthUtilidad;
        currentLabels = monthLabels;
        break;
      case 'año':
        currentUtilidad = yearUtilidad;
        currentLabels = yearLabels;
        break;
      case 'semana':
      default:
        currentUtilidad = weekUtilidad;
        currentLabels = weekLabels;
        break;
    }

    final barColor = Theme.of(context).primaryColor;
    final textStyle = TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6));

    return BarChartData(
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
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < currentLabels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(currentLabels[value.toInt()], style: textStyle),
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
              style: textStyle,
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: currentUtilidad.asMap().entries.map((e) {
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value,
              color: barColor,
              width: 14,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            )
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Dashboard',
              subtitle: 'Resumen operativo del sistema',
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Ventas Hoy',
                    value: '\$12,700.00',
                    change: '+12.5%',
                    icon: Icons.attach_money,
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Órdenes Activas',
                    value: '4',
                    change: 'En cocina',
                    icon: Icons.restaurant,
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Ingreso Semanal',
                    value: '\$161,600.00',
                    change: '+8.2%',
                    icon: Icons.trending_up,
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Utilidad Semanal',
                    value: '\$107,800.00',
                    change: '+15.3%',
                    icon: Icons.account_balance_wallet,
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterType,
                      dropdownColor: Theme.of(context).cardColor,
                      items: const [
                        DropdownMenuItem(value: 'semana', child: Text('Esta Semana')),
                        DropdownMenuItem(value: 'mes', child: Text('Este Mes')),
                        DropdownMenuItem(value: 'año', child: Text('Este Año')),
                      ],
                      onChanged: (v) => setState(() => _filterType = v!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flujo Financiero', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: LineChart(_buildLineChartData(context)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Utilidad neta', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: BarChart(_buildBarChartData(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rendimiento de Productos', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  _buildThemeTable(
                    context,
                    ['Producto', 'Categoría', 'Unidades Vendidas', 'Monto Total'],
                    [
                      ['Arrachera 300g', 'Parrilla', '142', '\$40,470.00'],
                      ['Cerveza Artesanal', 'Bebidas', '320', '\$27,200.00'],
                      ['T-Bone 500g', 'Parrilla', '45', '\$20,250.00'],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required bool isPositive,
  }) {
    final trendColor = isPositive ? Colors.green : Theme.of(context).colorScheme.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500, 
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                )
              ),
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.onSurface
            )
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: trendColor, size: 14),
              const SizedBox(width: 4),
              Text(change, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(
                'vs anterior', 
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), 
                  fontSize: 11
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTable(BuildContext context, List<String> columns, List<List<String>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
        rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))).toList())).toList(),
      ),
    );
  }
}