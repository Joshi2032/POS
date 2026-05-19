import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gastos_provider.dart';
import '../utils/formatters.dart';
import '../utils/ui_utils.dart';

class GastosPage extends StatelessWidget {
  const GastosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GastosView();
  }
}

class _GastosView extends StatefulWidget {
  const _GastosView();

  @override
  State<_GastosView> createState() => _GastosViewState();
}

class _GastosViewState extends State<_GastosView> {
  final List<String> categorias = [
    'Todos',
    'Renta',
    'Servicios',
    'Insumos',
    'Mantenimiento',
    'Publicidad',
    'Impuestos',
    'General'
  ];
  final List<String> formCategories = [
    'General',
    'Insumos',
    'Servicios',
    'Renta',
    'Mantenimiento',
    'Publicidad',
    'Impuestos'
  ];
  final List<String> formMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

  bool showModal = false;
  String? editingId;
  String modalError = '';

  late GastoForm formState;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _resetForm();
  }

  void _resetForm() {
    formState = GastoForm(
      date: DateTime.now().toIso8601String().substring(0, 10),
      concept: '',
      category: 'General',
      method: 'Efectivo',
      amount: 0.0,
      notes: '',
    );
    modalError = '';
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

  void guardarGasto(GastosProvider provider) {
    if (_formKey.currentState == null || !_formKey.currentState!.validate())
      return;

    if (formState.concept.trim().isEmpty ||
        formState.date.trim().isEmpty ||
        formState.amount <= 0) {
      setState(() => modalError = 'Completa fecha, concepto y monto válido.');
      return;
    }

    if (editingId != null) {
      UiUtils.showConfirmDialog(context, 'Actualizar Gasto',
          '¿Actualizar el gasto ${formState.concept}?', () {
        provider.actualizarGasto(editingId!, formState);
        UiUtils.showToast(context, 'Gasto actualizado', color: Colors.green);
        cerrarModal();
      });
    } else {
      UiUtils.showConfirmDialog(
          context, 'Registrar Gasto', '¿Registrar gasto ${formState.concept}?',
          () {
        provider.crearGasto(formState);
        UiUtils.showToast(context, 'Gasto registrado', color: Colors.green);
        cerrarModal();
      });
    }
  }

  void eliminarGastoConfirmado(GastosProvider provider, Gasto g) {
    UiUtils.showConfirmDialog(
        context, 'Eliminar Gasto', '¿Eliminar gasto ${g.concept}?', () {
      provider.eliminarGasto(g.id);
      UiUtils.showToast(context, 'Gasto eliminado', color: Colors.orange);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final provider = context.watch<GastosProvider>();

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
                              Text('Gastos y Egresos',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(
                              '${provider.filteredGastos.length} de ${provider.totalGastosLength} gastos',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: provider.onSearch,
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
                      _buildStatCard(
                          'Gastos este mes',
                          Formatters.money(provider.totalThisMonth),
                          '↘',
                          Colors.red.shade900),
                      _buildStatCard(
                          'Total acumulado',
                          Formatters.money(provider.totalAccumulated),
                          '\$',
                          Colors.blueGrey.shade800),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categorias.map((categoria) {
                      final isActive = provider.selectedCategory == categoria;
                      return ChoiceChip(
                        label: Text(categoria),
                        selected: isActive,
                        onSelected: (_) =>
                            provider.seleccionarCategoria(categoria),
                        selectedColor:
                            Theme.of(context).primaryColor.withAlpha(50),
                        labelStyle: TextStyle(
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade700,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
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
                            DataColumn(
                                label: Text('',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: provider.paginatedGastos.map((g) {
                            return DataRow(cells: [
                              DataCell(Text(g.date)),
                              DataCell(Text(g.concept,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                              DataCell(Text(g.category)),
                              DataCell(Text(g.method)),
                              DataCell(Text(Formatters.money(g.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                      onPressed: () => abrirEditar(g),
                                      child: const Text('Editar')),
                                  TextButton(
                                      onPressed: () =>
                                          eliminarGastoConfirmado(provider, g),
                                      child: const Text('Eliminar',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  if (provider.paginatedGastos.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(32),
                      child: const Text('Sin gastos registrados',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  const SizedBox(height: 15),
                  if (provider.totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          onPressed: provider.currentPage == 1
                              ? null
                              : () =>
                                  provider.changePage(provider.currentPage - 1),
                        ),
                        Text(
                            'Página ${provider.currentPage} de ${provider.totalPages}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: provider.currentPage == provider.totalPages
                              ? null
                              : () =>
                                  provider.changePage(provider.currentPage + 1),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: isDesktop ? 500 : double.infinity,
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
                              Text(
                                  editingId != null
                                      ? 'Editar Gasto'
                                      : 'Registrar Gasto',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: cerrarModal),
                            ],
                          ),
                          const Divider(),
                          if (modalError.isNotEmpty) ...[
                            Text(modalError,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                          ],
                          _buildFormFields(),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                  onPressed: cerrarModal,
                                  child: const Text('Cancelar')),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white),
                                onPressed: () => guardarGasto(provider),
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
            Text(icon,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
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
                decoration: const InputDecoration(
                    labelText: 'Fecha (YYYY-MM-DD)',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
                onChanged: (val) => formState.date = val,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: formState.concept,
                decoration: const InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Concepto del gasto',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
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
                initialValue: formState.category,
                decoration: const InputDecoration(
                    labelText: 'Categoría', border: OutlineInputBorder()),
                items: formCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => formState.category = val ?? 'General'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: formState.method,
                decoration: const InputDecoration(
                    labelText: 'Método', border: OutlineInputBorder()),
                items: formMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => formState.method = val ?? 'Efectivo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: formState.amount == 0.0 ? '' : '${formState.amount}',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Monto',
              hintText: '0.00',
              border: OutlineInputBorder()),
          validator: (v) =>
              v == null || double.tryParse(v) == null || double.parse(v) <= 0
                  ? 'Monto no válido'
                  : null,
          onChanged: (val) => formState.amount = double.tryParse(val) ?? 0.0,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: formState.notes,
          maxLines: 4,
          decoration: const InputDecoration(
              labelText: 'Notas', border: OutlineInputBorder()),
          onChanged: (val) => formState.notes = val,
        ),
      ],
    );
  }
}
