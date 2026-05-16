import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/sidebar.dart';

// ─── Paleta dark "La Brasa" ───────────────────────────────────────────────────
class _C {
  static const bg       = Color(0xFF1A1A1A);
  static const card     = Color(0xFF242424);
  static const cardBdr  = Color(0xFF2E2E2E);
  static const orange   = Color(0xFFFF7A00);
  static const red      = Color(0xFFFF3C00);
  static const green    = Color(0xFF2FFF7A);
  static const blue     = Color(0xFF2A7AFF);
  static const amber    = Color(0xFFFFB347);
  static const txt      = Color(0xFFEEEEEE);
  static const txtMuted = Color(0xFF888888);
  static const divider  = Color(0xFF2E2E2E);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  // ── filtro ────────────────────────────────────────────────────────────────
  String _filter = 'todos';

  // ── datos ─────────────────────────────────────────────────────────────────
  final _weekLabels    = ['mar','mié','jue','vie','sab','dom','lun'];
  final _weekIngresos  = <double>[12000,15000,9000,18000,21000,24000,7000];
  final _weekGastos    = <double>[6000,8000,7000,9000,11000,12000,5000];

  final _monthLabels   = ['Sem 1','Sem 2','Sem 3','Sem 4'];
  final _monthIngresos = <double>[52000,48000,61000,57000];
  final _monthGastos   = <double>[26000,22000,31000,27000];

  final _yearLabels    = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  final _yearIngresos  = <double>[210000,220000,205000,230000,240000,250000,260000,255000,245000,235000,225000,215000];
  final _yearGastos    = <double>[110000,115000,108000,120000,125000,130000,135000,132000,128000,124000,120000,118000];

  final _utilidad = <double>[12000,15000,9000,18000,21000,24000,7000];

  List<String>  get _labels   => _filter=='mes' ? _monthLabels  : _filter=='año' ? _yearLabels  : _weekLabels;
  List<double>  get _ingresos => _filter=='mes' ? _monthIngresos: _filter=='año' ? _yearIngresos: _weekIngresos;
  List<double>  get _gastos   => _filter=='mes' ? _monthGastos  : _filter=='año' ? _yearGastos  : _weekGastos;

  final _topProducts = [
    {'name':'Producto A','sold':120},
    {'name':'Producto B','sold':110},
    {'name':'Producto C','sold':100},
  ];
  final _bottomProducts = [
    {'name':'Producto X','sold':5},
    {'name':'Producto Y','sold':8},
    {'name':'Producto Z','sold':10},
  ];
  final _orders = [
    {'id':'ORD-001','mesa':'A3','mesero':'Carlos M.','items':3,'total':975,'estado':'Preparando'},
    {'id':'ORD-002','mesa':'B2','mesero':'Ana R.',   'items':3,'total':845,'estado':'Pendiente'},
    {'id':'ORD-003','mesa':'A1','mesero':'Carlos M.','items':2,'total':710,'estado':'Listo'},
  ];

  // ── helpers ───────────────────────────────────────────────────────────────
  String _fmtDate(DateTime d) {
    const wd = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    const mo = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${wd[d.weekday-1]}, ${d.day} de ${mo[d.month-1]} de ${d.year}';
  }

  Color _estadoColor(String e) => e=='Preparando' ? _C.blue : e=='Pendiente' ? _C.amber : _C.green;

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: _appBar(),
        drawer: const AppSidebar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _metrics(),
            const SizedBox(height: 20),
            _charts(),
            const SizedBox(height: 20),
            _productTables(),
            const SizedBox(height: 20),
            _ordersCard(),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _C.card,
    foregroundColor: _C.txt,
    elevation: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(22),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Resumen del día — ${_fmtDate(DateTime.now())}',
              style: const TextStyle(color: _C.txtMuted, fontSize: 12)),
        ),
      ),
    ),
    title: const Row(children: [
      Text('🔥', style: TextStyle(fontSize: 20)),
      SizedBox(width: 8),
      Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: _C.txt)),
    ]),
  );

  // ── Métricas ──────────────────────────────────────────────────────────────
  Widget _metrics() {
    final items = [
      {'icon':'💲','label':'Ventas Hoy',      'value':'\$12,700.00','change':'+12.5%'},
      {'icon':'🛒','label':'Órdenes Activas', 'value':'4',          'change':'+5 total'},
      {'icon':'📈','label':'Ingreso Semanal', 'value':'\$161,600.00','change':'+8.2%'},
      {'icon':'🔥','label':'Utilidad Semanal','value':'\$107,800.00','change':'+15.3%'},
    ];
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 700 ? 4 : c.maxWidth > 400 ? 2 : 1;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: cols == 4 ? 2.0 : 2.2,
        children: items.map((m) => _DarkMetricCard(
          icon: m['icon']!, label: m['label']!,
          value: m['value']!, change: m['change']!,
        )).toList(),
      );
    });
  }

  // ── Charts row ────────────────────────────────────────────────────────────
  Widget _charts() => LayoutBuilder(builder: (ctx, c) {
    final isWide = c.maxWidth > 700;
    final line = _lineCard();
    final bar  = _barCard();
    return isWide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: line),
            const SizedBox(width: 16),
            Expanded(child: bar),
          ])
        : Column(children: [line, const SizedBox(height: 16), bar]);
  });

  // ── Line chart ────────────────────────────────────────────────────────────
  Widget _lineCard() {
    final showI = _filter != 'Gastos';
    final showG = _filter != 'Ingresos';
    final labels = _labels; final ing = _ingresos; final gas = _gastos;
    final s1 = List.generate(ing.length, (i) => FlSpot(i.toDouble(), ing[i]));
    final s2 = List.generate(gas.length, (i) => FlSpot(i.toDouble(), gas[i]));

    return _DarkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Expanded(
          child: Text('Ingresos vs Gastos — Última semana',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _C.txt))),
        _FilterDropdown(value: _filter, onChanged: (v) => setState(() => _filter = v)),
      ]),
      const SizedBox(height: 16),
      SizedBox(height: 230, child: LineChart(LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFF2E2E2E), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 52,
            getTitlesWidget: (v, _) => Text('\$${(v/1000).toStringAsFixed(0)}k',
                style: const TextStyle(color: _C.txtMuted, fontSize: 9)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 20,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= labels.length) return const SizedBox();
              return Text(labels[i], style: const TextStyle(color: _C.txtMuted, fontSize: 9));
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2E2E2E),
            getTooltipItems: (spots) => spots.map((s) {
              final lbl = s.barIndex == 0 ? 'Ingresos' : 'Gastos';
              final col = s.barIndex == 0 ? _C.orange : _C.red;
              return LineTooltipItem('$lbl\n\$${s.y.toStringAsFixed(0)}',
                  TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold));
            }).toList(),
          ),
        ),
        lineBarsData: [
          if (showI) _lineBar(s1, _C.orange),
          if (showG) _lineBar(s2, _C.red),
        ],
      ))),
      const SizedBox(height: 10),
      Row(children: [
        if (showI) ...[_dot(_C.orange), const SizedBox(width:4),
          const Text('Ingresos', style: TextStyle(color: _C.txt, fontSize:11)), const SizedBox(width:14)],
        if (showG) ...[_dot(_C.red),    const SizedBox(width:4),
          const Text('Gastos',   style: TextStyle(color: _C.txt, fontSize:11))],
      ]),
    ]));
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots, isCurved: true, color: color, barWidth: 2.5,
    dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
        FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: color)),
    belowBarData: BarAreaData(show: true, gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.35), color.withOpacity(0.03)])),
  );

  // ── Bar chart ─────────────────────────────────────────────────────────────
  Widget _barCard() => _DarkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Utilidad Diaria',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _C.txt)),
    const SizedBox(height: 16),
    SizedBox(height: 230, child: BarChart(BarChartData(
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFF2E2E2E), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 20,
          getTitlesWidget: (v, _) {
            final days = ['mar','mié','jue','vie','sab','dom','lun'];
            final i = v.toInt();
            if (i < 0 || i >= days.length) return const SizedBox();
            return Text(days[i], style: const TextStyle(color: _C.txtMuted, fontSize: 9));
          },
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 52,
          getTitlesWidget: (v, _) => Text('\$${(v/1000).toStringAsFixed(0)}k',
              style: const TextStyle(color: _C.txtMuted, fontSize: 9)),
        )),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF2E2E2E),  
          getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
            '\$${rod.toY.toStringAsFixed(0)}',
            const TextStyle(color: _C.green, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ),
      barGroups: List.generate(_utilidad.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: _utilidad[i], color: _C.green, width: 20,
            borderRadius: BorderRadius.circular(4)),
      ])),
    ))),
    const SizedBox(height: 10),
    Row(children: [_dot(_C.green), const SizedBox(width:4),
      const Text('Utilidad', style: TextStyle(color: _C.txt, fontSize:11))]),
  ]));

  // ── Product tables ────────────────────────────────────────────────────────
  Widget _productTables() => LayoutBuilder(builder: (ctx, c) {
    final isWide = c.maxWidth > 600;
    final top    = _productTable('Más Vendidos',   _topProducts);
    final bottom = _productTable('Menos Vendidos', _bottomProducts);
    return isWide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: top), const SizedBox(width: 16), Expanded(child: bottom)])
        : Column(children: [top, const SizedBox(height: 16), bottom]);
  });

  Widget _productTable(String title, List<Map<String,dynamic>> rows) {
    // máximo para la barra de progreso
    final maxSold = rows.map((r) => (r['sold'] as int)).reduce((a,b) => a>b?a:b).toDouble();

    return _DarkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.txt)),
      const SizedBox(height: 10),
      // cabecera
      const Row(children: [
        Expanded(flex:3, child: Text('Producto', style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(flex:1, child: Text('Vendidos', style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(flex:3, child: Text('Gráfica',  style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
      const Divider(color: _C.divider, height: 14),
      ...rows.map((r) {
        final pct = (r['sold'] as int) / maxSold;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(flex:3, child: Text(r['name'], style: const TextStyle(color: _C.txt, fontSize: 12))),
            Expanded(flex:1, child: Text('${r['sold']}', style: const TextStyle(color: _C.txt, fontSize: 12))),
            Expanded(flex:3, child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 10,
                backgroundColor: const Color(0xFF2E2E2E),
                valueColor: const AlwaysStoppedAnimation(_C.orange),
              ),
            )),
          ]),
        );
      }),
    ]));
  }

  // ── Orders ────────────────────────────────────────────────────────────────
  Widget _ordersCard() => _DarkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Órdenes Recientes',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.txt)),
    const SizedBox(height: 12),
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 38,
        dataRowMaxHeight: 38,
        headingRowColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
        dataRowColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _C.cardBdr : Colors.transparent),
        dividerThickness: 0.5,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Orden',  style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Mesa',   style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Mesero', style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Items',  style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600)), numeric: true),
          DataColumn(label: Text('Total',  style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600)), numeric: true),
          DataColumn(label: Text('Estado', style: TextStyle(color: _C.txtMuted, fontSize: 11, fontWeight: FontWeight.w600))),
        ],
        rows: _orders.map((o) => DataRow(cells: [
          DataCell(Text(o['id'].toString(),
              style: const TextStyle(color: _C.orange, fontWeight: FontWeight.bold, fontSize: 12))),
          DataCell(Text(o['mesa'].toString(), style: const TextStyle(color: _C.txt, fontSize: 12))),
          DataCell(Text(o['mesero'].toString(), style: const TextStyle(color: _C.txt, fontSize: 12))),
          DataCell(Text(o['items'].toString(), style: const TextStyle(color: _C.txt, fontSize: 12))),
          DataCell(Text('\$${o['total']}', style: const TextStyle(color: _C.txt, fontSize: 12, fontWeight: FontWeight.w600))),
          DataCell(_Badge(label: o['estado'].toString(), color: _estadoColor(o['estado'].toString()))),
        ])).toList(),
      ),
    ),
  ]));

  Widget _dot(Color c) => Container(width: 10, height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ─── Dark theme local ─────────────────────────────────────────────────────────
ThemeData _darkTheme() => ThemeData.dark().copyWith(
  scaffoldBackgroundColor: _C.bg,
  cardColor: _C.card,
  dividerColor: _C.divider,
);

// ─── Widgets reutilizables ────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.cardBdr),
    ),
    child: child,
  );
}

class _DarkMetricCard extends StatelessWidget {
  final String icon, label, value, change;
  const _DarkMetricCard({required this.icon, required this.label, required this.value, required this.change});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.cardBdr),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.txt)),
      const SizedBox(height: 2),
      Text(label,  style: const TextStyle(fontSize: 11, color: _C.txtMuted)),
      const SizedBox(height: 2),
      Row(children: [
        const Text('↑ ', style: TextStyle(color: _C.green, fontSize: 11)),
        Text(change, style: const TextStyle(color: _C.green, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _FilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _C.cardBdr),
    ),
    child: DropdownButton<String>(
      value: value,
      dropdownColor: const Color(0xFF2A2A2A),
      underline: const SizedBox(),
      style: const TextStyle(color: _C.txt, fontSize: 12),
      items: const [
        DropdownMenuItem(value:'todos',    child: Text('Todos')),
        DropdownMenuItem(value:'Ingresos', child: Text('Ingresos')),
        DropdownMenuItem(value:'Gastos',   child: Text('Gastos')),
        DropdownMenuItem(value:'mes',      child: Text('Mes')),
        DropdownMenuItem(value:'año',      child: Text('Año')),
      ],
      onChanged: (v) => onChanged(v ?? 'todos'),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() > 0.4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: dark ? Colors.black : Colors.white)),
    );
  }
}