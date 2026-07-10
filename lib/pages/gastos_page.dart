import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gastos_provider.dart';
import '../utils/formatters.dart';
import '../utils/ui_utils.dart';
import '../models/gasto.dart';

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
    'Todos', 'Renta', 'Servicios', 'Insumos',
    'Mantenimiento', 'Publicidad', 'Impuestos', 'General',
  ];
  final List<String> formCategories = [
    'General', 'Insumos', 'Servicios', 'Renta',
    'Mantenimiento', 'Publicidad', 'Impuestos',
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
        method: g.method ?? 'Efectivo',
        amount: g.amount,
        notes: g.notes ?? '',
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
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    if (formState.concept.trim().isEmpty ||
        formState.date.trim().isEmpty ||
        formState.amount <= 0) {
      setState(() => modalError = 'Completa fecha, concepto y monto válido.');
      return;
    }
    if (editingId != null) {
      final idAActualizar = editingId!;
      UiUtils.showConfirmDialog(
          context, 'Actualizar Gasto',
          '¿Actualizar el gasto ${formState.concept}?', () async {
        final exito = await provider.actualizarGasto(idAActualizar, formState);
        if (!mounted) return;
        if (exito) {
          UiUtils.showToast(context, 'Gasto actualizado', color: Colors.green);
          cerrarModal();
        } else {
          UiUtils.showToast(
            context,
            provider.errorMessage ?? 'No se pudo actualizar el gasto.',
            color: Colors.red,
          );
        }
      });
    } else {
      UiUtils.showConfirmDialog(
          context, 'Registrar Gasto',
          '¿Registrar gasto ${formState.concept}?', () async {
        final exito = await provider.crearGasto(formState);
        if (!mounted) return;
        if (exito) {
          UiUtils.showToast(context, 'Gasto registrado', color: Colors.green);
          cerrarModal();
        } else {
          UiUtils.showToast(
            context,
            provider.errorMessage ?? 'No se pudo registrar el gasto.',
            color: Colors.red,
          );
        }
      });
    }
  }

  void eliminarGastoConfirmado(GastosProvider provider, Gasto g) {
    final id = g.id;
    if (id == null) {
      UiUtils.showToast(
        context,
        'Este gasto no tiene un identificador válido.',
        color: Colors.red,
      );
      return;
    }
    UiUtils.showConfirmDialog(
        context, 'Eliminar Gasto', '¿Eliminar gasto ${g.concept}?', () async {
      final exito = await provider.eliminarGasto(id);
      if (!mounted) return;
      if (exito) {
        UiUtils.showToast(context, 'Gasto eliminado', color: Colors.orange);
      } else {
        UiUtils.showToast(
          context,
          provider.errorMessage ?? 'No se pudo eliminar el gasto.',
          color: Colors.red,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastosProvider>();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final hPad = w < 480 ? 16.0 : 20.0;
                final isCompact = w < 600;
                final isWide = w >= 900;

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── HEADER ──────────────────────────────────────
                          if (isCompact) ...[
                            _HeaderTitle(
                              filteredCount: provider.filteredGastos.length,
                              totalCount: provider.totalGastosLength,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _BotonRegistrar(onTap: abrirModal),
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _HeaderTitle(
                                    filteredCount:
                                        provider.filteredGastos.length,
                                    totalCount: provider.totalGastosLength,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _BotonRegistrar(onTap: abrirModal),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          // ── BUSCADOR ─────────────────────────────────────
                          TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar gasto, método o categoría...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: provider.onSearch,
                          ),

                          const SizedBox(height: 20),

                          // ── STAT CARDS ───────────────────────────────────
                          // IntrinsicHeight evita el ratio fijo que rompe en móvil
                          isWide
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Gastos este mes',
                                          value: Formatters.money(
                                              provider.totalThisMonth),
                                          icon: '↘',
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Total acumulado',
                                          value: Formatters.money(
                                              provider.totalAccumulated),
                                          icon: '\$',
                                          color: Colors.blueGrey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    _StatCard(
                                      label: 'Gastos este mes',
                                      value: Formatters.money(
                                          provider.totalThisMonth),
                                      icon: '↘',
                                      color: Colors.red.shade900,
                                    ),
                                    const SizedBox(height: 12),
                                    _StatCard(
                                      label: 'Total acumulado',
                                      value: Formatters.money(
                                          provider.totalAccumulated),
                                      icon: '\$',
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ],
                                ),

                          const SizedBox(height: 20),

                          // ── CHIPS DE CATEGORÍA ───────────────────────────
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categorias.map((cat) {
                              final isActive =
                                  provider.selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isActive,
                                onSelected: (_) =>
                                    provider.seleccionarCategoria(cat),
                                selectedColor: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(50),
                                labelStyle: TextStyle(
                                  color: isActive
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade700,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // ── TABLA / CARDS ────────────────────────────────
                          if (provider.paginatedGastos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text('Sin gastos registrados',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          else if (isCompact)
                            // En móvil: lista de cards en lugar de DataTable
                            Column(
                              children: provider.paginatedGastos.map((g) {
                                return _GastoCard(
                                  gasto: g,
                                  onEditar: () => abrirEditar(g),
                                  onEliminar: () =>
                                      eliminarGastoConfirmado(provider, g),
                                );
                              }).toList(),
                            )
                          else
                            // En tablet/escritorio: DataTable con scroll horizontal
                           Card(
  clipBehavior: Clip.antiAlias,
  margin: EdgeInsets.zero,
  child: LayoutBuilder(
    builder: (context, tableConstraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: tableConstraints.maxWidth,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
            ),
            horizontalMargin: 20,
            columnSpacing: 32,
            columns: const [
              DataColumn(
                label: Text(
                  'Fecha',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Concepto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Categoría',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Método',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Monto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Acciones',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: provider.paginatedGastos.map((g) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(g.date),
                  ),
                  DataCell(
                    Text(
                      g.concept,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(g.category),
                  ),
                  DataCell(
                    Text(g.method ?? 'N/A'),
                  ),
                  DataCell(
                    Text(
                      Formatters.money(g.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            abrirEditar(g);
                          },
                          child: const Text('Editar'),
                        ),
                        TextButton(
                          onPressed: () {
                            eliminarGastoConfirmado(
                              provider,
                              g,
                            );
                          },
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    },
  ),
),

                          const SizedBox(height: 14),

                          // ── PAGINACIÓN ───────────────────────────────────
                          if (provider.totalPages > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios,
                                      size: 16),
                                  onPressed: provider.currentPage == 1
                                      ? null
                                      : () => provider.changePage(
                                          provider.currentPage - 1),
                                ),
                                Text(
                                  'Página ${provider.currentPage} de ${provider.totalPages}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onPressed: provider.currentPage ==
                                          provider.totalPages
                                      ? null
                                      : () => provider.changePage(
                                          provider.currentPage + 1),
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
            ),
          ),

          // ── MODAL ────────────────────────────────────────────────────────
          if (showModal) ...[
            GestureDetector(
              onTap: cerrarModal,
              child: Container(color: Colors.black54),
            ),
            _GastoModal(
              editingId: editingId,
              formKey: _formKey,
              formState: formState,
              modalError: modalError,
              formCategories: formCategories,
              formMethods: formMethods,
              isSaving: provider.isLoading,
              onCerrar: cerrarModal,
              onGuardar: provider.isLoading
                  ? null
                  : () => guardarGasto(context.read<GastosProvider>()),
              onCategoryChanged: (val) =>
                  setState(() => formState.category = val ?? 'General'),
              onMethodChanged: (val) =>
                  setState(() => formState.method = val ?? 'Efectivo'),
              onFormChanged: (field, val) {
                setState(() {
                  if (field == 'date') formState.date = val;
                  if (field == 'concept') formState.concept = val;
                  if (field == 'amount') {
                    formState.amount = double.tryParse(val) ?? 0.0;
                  }
                  if (field == 'notes') formState.notes = val;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle(
      {required this.filteredCount, required this.totalCount});
  final int filteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💸 ', style: TextStyle(fontSize: 24)),
            Flexible(
              child: Text(
                'Gastos y Egresos',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Text(
          '$filteredCount de $totalCount gastos',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}

class _BotonRegistrar extends StatelessWidget {
  const _BotonRegistrar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: const Text('+ Registrar Gasto',
          style: TextStyle(fontWeight: FontWeight.bold)),
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
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Text(icon,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
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
                    child: Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
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

// Card de gasto para vista móvil (reemplaza la fila del DataTable)
class _GastoCard extends StatelessWidget {
  const _GastoCard({
    required this.gasto,
    required this.onEditar,
    required this.onEliminar,
  });
  final Gasto gasto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Concepto + monto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    gasto.concept,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.money(gasto.amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Fecha · Categoría · Método
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _InfoChip(Icons.calendar_today, gasto.date),
                _InfoChip(Icons.label_outline, gasto.category),
                _InfoChip(
                    Icons.payment, gasto.method ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 8),
            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onEditar,
                  child: const Text('Editar'),
                ),
                TextButton(
                  onPressed: onEliminar,
                  child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// ── MODAL ────────────────────────────────────────────────────────────────────

class _GastoModal extends StatelessWidget {
  const _GastoModal({
    required this.editingId,
    required this.formKey,
    required this.formState,
    required this.modalError,
    required this.formCategories,
    required this.formMethods,
    required this.onCerrar,
    required this.onGuardar,
    required this.onCategoryChanged,
    required this.onMethodChanged,
    required this.onFormChanged,
    this.isSaving = false,
  });

  final String? editingId;
  final GlobalKey<FormState> formKey;
  final GastoForm formState;
  final String modalError;
  final List<String> formCategories;
  final List<String> formMethods;
  final bool isSaving;
  final VoidCallback onCerrar;
  final VoidCallback? onGuardar;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onMethodChanged;
  final void Function(String field, String val) onFormChanged;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isWide = w > 600;
    final isVeryNarrow = w < 400;

    return Center(
      child: Card(
        margin: EdgeInsets.all(isWide ? 20 : 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: isWide ? 500 : w - 24,
          constraints: BoxConstraints(maxHeight: h * 0.90),
          padding: EdgeInsets.all(isWide ? 24 : 18),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        editingId != null
                            ? 'Editar Gasto'
                            : 'Registrar Gasto',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                        onPressed: onCerrar,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (modalError.isNotEmpty) ...[
                    Text(modalError,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                  ],

                  // Fecha + Concepto
                  if (isVeryNarrow) ...[
                    _Field(
                      label: 'Fecha (YYYY-MM-DD)',
                      initialValue: formState.date,
                      onChanged: (v) => onFormChanged('date', v),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Requerido'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Concepto',
                      hint: 'Concepto del gasto',
                      initialValue: formState.concept,
                      onChanged: (v) => onFormChanged('concept', v),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Requerido'
                              : null,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'Fecha (YYYY-MM-DD)',
                            initialValue: formState.date,
                            onChanged: (v) => onFormChanged('date', v),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label: 'Concepto',
                            hint: 'Concepto del gasto',
                            initialValue: formState.concept,
                            onChanged: (v) =>
                                onFormChanged('concept', v),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Categoría + Método
                  if (isVeryNarrow) ...[
                    _Dropdown(
                      label: 'Categoría',
                      value: formState.category,
                      items: formCategories,
                      onChanged: onCategoryChanged,
                    ),
                    const SizedBox(height: 12),
                    _Dropdown(
                      label: 'Método',
                      value: formState.method,
                      items: formMethods,
                      onChanged: onMethodChanged,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _Dropdown(
                            label: 'Categoría',
                            value: formState.category,
                            items: formCategories,
                            onChanged: onCategoryChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Dropdown(
                            label: 'Método',
                            value: formState.method,
                            items: formMethods,
                            onChanged: onMethodChanged,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Monto
                  TextFormField(
                    initialValue: formState.amount == 0.0
                        ? ''
                        : '${formState.amount}',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Monto',
                        hintText: '0.00',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        v == null ||
                                double.tryParse(v) == null ||
                                double.parse(v) <= 0
                            ? 'Monto no válido'
                            : null,
                    onChanged: (v) => onFormChanged('amount', v),
                  ),

                  const SizedBox(height: 14),

                  // Notas
                  TextFormField(
                    initialValue: formState.notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Notas',
                        border: OutlineInputBorder()),
                    onChanged: (v) => onFormChanged('notes', v),
                  ),

                  const SizedBox(height: 22),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                          onPressed: onCerrar,
                          child: const Text('Cancelar')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
                        onPressed: onGuardar,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Guardar Gasto'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.validator,
  });
  final String label;
  final String initialValue;
  final String? hint;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder()),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      items: items
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: onChanged,
    );
  }
}