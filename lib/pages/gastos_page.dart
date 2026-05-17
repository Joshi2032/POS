import 'package:flutter/material.dart';

// ==========================================
// MODELOS DE DATOS (Mapeo exacto de gasto.model.ts)
// ==========================================
class Gasto {
  final String id;
  final String date;
  final String concept;
  final String category;
  final String method;
  final double amount;
  final String notes;

  Gasto({
    required this.id,
    required this.date,
    required this.concept,
    required this.category,
    required this.method,
    required this.amount,
    required this.notes,
  });

  Gasto copyWith({
    String? id,
    String? date,
    String? concept,
    String? category,
    String? method,
    double? amount,
    String? notes,
  }) {
    return Gasto(
      id: id ?? this.id,
      date: date ?? this.date,
      concept: concept ?? this.concept,
      category: category ?? this.category,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }
}

class GastoForm {
  String date;
  String concept;
  String category;
  String method;
  double amount;
  String notes;

  GastoForm({
    required this.date,
    required this.concept,
    required this.category,
    required this.method,
    required this.amount,
    required this.notes,
  });
}

// ==========================================
// COMPONENTE PRINCIPAL
// ==========================================
class GastosPage extends StatefulWidget {
  const GastosPage({super.key});

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final int pageSize = 10;
  final List<String> categorias = ['Todos', 'Renta', 'Servicios', 'Insumos', 'Mantenimiento', 'Publicidad', 'Impuestos', 'General'];
  final List<String> formCategories = ['General', 'Insumos', 'Servicios', 'Renta', 'Mantenimiento', 'Publicidad', 'Impuestos'];
  final List<String> formMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

  String searchTerm = '';
  String selectedCategory = 'Todos';
  int currentPage = 1;
  bool showModal = false;
  String? editingId;
  String modalError = ''; // Declarada explícitamente para solucionar el error de 'undefined name'

  List<Gasto> gastos = [];
  late GastoForm formState;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final todayStr = DateTime.now().toIso8601String().slice(0, 10);
    
    gastos = [
      Gasto(id: 'G-0001', date: todayStr, concept: 'Compra de carne y verdura', category: 'Insumos', method: 'Efectivo', amount: 2450.50, notes: 'Proveedor local central'),
      Gasto(id: 'G-0002', date: todayStr, concept: 'Pago de luz CFE', category: 'Servicios', method: 'Transferencia', amount: 4890.00, notes: 'Recibo Bimestral'),
      Gasto(id: 'G-0003', date: todayStr, concept: 'Renta del local comercial', category: 'Renta', method: 'Transferencia', amount: 12000.00, notes: 'Mes en curso'),
      Gasto(id: 'G-0004', date: todayStr, concept: 'Reparación de freidora', category: 'Mantenimiento', method: 'Tarjeta', amount: 850.00, notes: 'Cambio de termopar'),
    ];

    _resetForm();
  }

  void _resetForm() {
    formState = GastoForm(
      date: DateTime.now().toIso8601String().slice(0, 10),
      concept: '',
      category: 'General',
      method: 'Efectivo',
      amount: 0.0,
      notes: '',
    );
    modalError = '';
  }

  // LÓGICA COMPUTADA (Solucionado: reemplazado .includes por .contains)
  List<Gasto> get filteredGastos {
    final s = searchTerm.trim().toLowerCase();
    final category = selectedCategory;
    return gastos.where((g) {
      final matchesSearch = s.isEmpty ||
          g.concept.toLowerCase().contains(s) ||
          g.category.toLowerCase().contains(s) ||
          g.method.toLowerCase().contains(s);

      final matchesCategory = category == 'Todos' || g.category == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Gasto> get paginatedGastos {
    final list = filteredGastos;
    final start = (currentPage - 1) * pageSize;
    if (start >= list.length) return [];
    final end = (start + pageSize) > list.length ? list.length : (start + pageSize);
    return list.sublist(start, end);
  }

  double get totalThisMonth {
    final now = DateTime.now();
    return gastos.fold(0.0, (sum, g) {
      final d = DateTime.tryParse(g.date);
      if (d != null && d.month == now.month && d.year == now.year) {
        return sum + g.amount;
      }
      return sum;
    });
  }

  double get totalAccumulated => gastos.fold(0.0, (sum, g) => sum + g.amount);
  int get totalPages => (filteredGastos.length / pageSize).ceil();

  void onSearch(String value) {
    setState(() {
      searchTerm = value;
      currentPage = 1;
    });
  }

  void seleccionarCategoria(String categoria) {
    setState(() {
      selectedCategory = categoria;
      currentPage = 1;
    });
  }

  void abrirModal() {
    setState(() {
      editingId = null;
      _resetForm();
      showModal = true;
    });
  }

  void abrirEditar(Gasto g) {
    setState(() {
      editingId = g.id;
      modalError = '';
      formState = GastoForm(
        date: g.date,
        concept: g.concept,
        category: g.category,
        method: g.method,
        amount: g.amount,
        notes: g.notes,
      );
      showModal = true;
    });
  }

  void cerrarModal() {
    setState(() {
      showModal = false;
      editingId = null;
    });
  }

  void guardar() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final concept = formState.concept.trim();
    final date = formState.date.trim();
    final amount = formState.amount;

    if (concept.isEmpty || date.isEmpty || amount <= 0) {
      setState(() {
        modalError = 'Completa fecha, concepto y monto válido.';
      });
      return;
    }

    if (editingId != null) {
      _showConfirmDialog(
        'Actualizar Gasto',
        '¿Actualizar el gasto $concept?',
        () => _actualizarGasto(),
      );
    } else {
      _showConfirmDialog(
        'Registrar Gasto',
        '¿Registrar gasto $concept?',
        () => _crearGasto(),
      );
    }
  }

  void _crearGasto() {
    setState(() {
      final next = gastos.length + 1;
      final nuevoGasto = Gasto(
        id: 'G-${next.toString().padLeft(4, '0')}',
        date: formState.date,
        concept: formState.concept,
        category: formState.category,
        method: formState.method,
        amount: formState.amount,
        notes: formState.notes,
      );

      gastos.insert(0, nuevoGasto);
      _showToast('Gasto registrado', Colors.green);
      cerrarModal();
    });
  }

  void _actualizarGasto() {
    if (editingId == null) return;
    setState(() {
      final idx = gastos.indexWhere((x) => x.id == editingId);
      if (idx != -1) {
        gastos[idx] = gastos[idx].copyWith(
          date: formState.date,
          concept: formState.concept,
          category: formState.category,
          method: formState.method,
          amount: formState.amount,
          notes: formState.notes,
        );
        _showToast('Gasto actualizado', Colors.green);
        cerrarModal();
      }
    });
  }

  void eliminar(String id) {
    final g = gastos.firstWhere((x) => x.id == id);
    _showConfirmDialog(
      'Eliminar Gasto',
      '¿Eliminar gasto ${g.concept}?',
      () {
        setState(() {
          gastos.removeWhere((x) => x.id == id);
          _showToast('Gasto eliminado', Colors.orange);
        });
      },
    );
  }

  String formatMoney(double value) {
    return '\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  void _showConfirmDialog(String title, String body, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

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
                              const Text('💸 ', style: TextStyle(fontSize: 26)),
                              Text('Gastos y Egresos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text('${filteredGastos.length} de ${gastos.length} gastos registrados', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                        onPressed: abrirModal,
                        child: const Text('+ Registrar Gasto'),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar gasto, método o categoría...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: onSearch,
                  ),
                  const SizedBox(height: 25),

                  GridView.count(
                    crossAxisCount: isDesktop ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 3.5 : 4.0,
                    children: [
                      _buildStatCard('Gastos este mes', formatMoney(totalThisMonth), '↘', Colors.red.shade900),
                      _buildStatCard('Total acumulado', formatMoney(totalAccumulated), '\$', Colors.blueGrey.shade800),
                    ],
                  ),
                  const SizedBox(height: 25),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categorias.map((categoria) {
                      final isActive = selectedCategory == categoria;
                      return ChoiceChip(
                        label: Text(categoria),
                        selected: isActive,
                        onSelected: (_) => seleccionarCategoria(categoria),
                        selectedColor: Theme.of(context).primaryColor.withAlpha(50),
                        labelStyle: TextStyle(
                          color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade700,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                        columns: const [
                          DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Concepto', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: paginatedGastos.map((g) {
                          return DataRow(cells: [
                            DataCell(Text(g.date)),
                            DataCell(Text(g.concept, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(g.category)),
                            DataCell(Text(g.method)),
                            DataCell(Text(formatMoney(g.amount), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(onPressed: () => abrirEditar(g), child: const Text('Editar')),
                                TextButton(onPressed: () => eliminar(g.id), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),

                  if (paginatedGastos.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(32),
                      child: const Text('Sin gastos registrados', style: TextStyle(color: Colors.grey)),
                    ),
                  const SizedBox(height: 15),

                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          onPressed: currentPage == 1 ? null : () => setState(() => currentPage--),
                        ),
                        Text('Página $currentPage de $totalPages', style: const TextStyle(fontWeight: FontWeight.w500)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: currentPage == totalPages ? null : () => setState(() => currentPage++),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),

          if (showModal) ...[
            GestureDetector(
              onTap: cerrarModal,
              child: Container(color: Colors.black54),
            ),
            Center(
              child: Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(editingId != null ? 'Editar Gasto' : 'Registrar Gasto', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.close), onPressed: cerrarModal),
                            ],
                          ),
                          const Divider(),
                          if (modalError.isNotEmpty) ...[
                            Text(modalError, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                          ],
                          _buildFormFields(),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(onPressed: cerrarModal, child: const Text('Cancelar')),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                                onPressed: guardar,
                                child: const Text('Guardar Gasto'),
                              ),
                            ],
                          )
                        ],
                      ),
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

  Widget _buildStatCard(String label, String value, String icon, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(color: Colors.white38, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: formState.date,
                decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                onChanged: (val) => formState.date = val,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: formState.concept,
                // Solución al problema de placeholder: transferido a hintText
                decoration: const InputDecoration(labelText: 'Concepto', hintText: 'Concepto del gasto', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                onChanged: (val) => formState.concept = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                // Solución al warning de value: cambiado por initialValue
                initialValue: formState.category,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: formCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => formState.category = val ?? 'General'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                // Solución al warning de value: cambiado por initialValue
                initialValue: formState.method,
                decoration: const InputDecoration(labelText: 'Método', border: OutlineInputBorder()),
                items: formMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => formState.method = val ?? 'Efectivo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: formState.amount == 0.0 ? '' : '${formState.amount}',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Solución al problema de placeholder: transferido a hintText
          decoration: const InputDecoration(labelText: 'Monto', hintText: '0.00', border: OutlineInputBorder()),
          validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Monto no válido' : null,
          onChanged: (val) => formState.amount = double.tryParse(val) ?? 0.0,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: formState.notes,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
          onChanged: (val) => formState.notes = val,
        ),
      ],
    );
  }
}

extension StringSlice on String {
  String slice(int start, int end) => substring(start, end);
}