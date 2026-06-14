import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nomina_pago.dart';
import '../providers/nominas_provider.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';

class NominasPage extends StatelessWidget {
  const NominasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NominasView();
  }
}

class _NominasView extends StatefulWidget {
  const _NominasView();

  @override
  State<_NominasView> createState() => _NominasViewState();
}

class _NominasViewState extends State<_NominasView> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  void _openEditor(NominasProvider provider, {NominaPago? nomina}) {
    final w = MediaQuery.of(context).size.width;

    final fechaCtrl = TextEditingController(
        text: nomina?.fecha ??
            DateTime.now().toIso8601String().split('T').first);
    final empleadoCtrl =
        TextEditingController(text: nomina?.empleado ?? '');
    final montoCtrl =
        TextEditingController(text: nomina?.monto.toString() ?? '0');
    final notasCtrl =
        TextEditingController(text: nomina?.notas ?? '');
    String tipo = nomina?.tipo ?? 'Salario';
    String periodo = nomina?.periodo ?? 'Quincenal';
    String metodo = nomina?.metodo ?? 'Transferencia';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: w < 480 ? 12 : 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: Text(
            nomina == null ? 'Agregar Pago' : 'Editar Pago',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: w < 480 ? double.infinity : 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fecha + Empleado
                  w < 400
                      ? Column(children: [
                          _DField(ctrl: fechaCtrl, label: 'Fecha'),
                          const SizedBox(height: 12),
                          _DField(ctrl: empleadoCtrl, label: 'Empleado'),
                        ])
                      : Row(children: [
                          Expanded(
                              child:
                                  _DField(ctrl: fechaCtrl, label: 'Fecha')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _DField(
                                  ctrl: empleadoCtrl, label: 'Empleado')),
                        ]),
                  const SizedBox(height: 12),
                  // Tipo + Período
                  w < 400
                      ? Column(children: [
                          _DDropdown(
                            label: 'Tipo',
                            value: tipo,
                            items: const [
                              'Salario', 'Adelanto', 'Bono', 'Deducción'
                            ],
                            onChanged: (v) => setDialogState(
                                () => tipo = v ?? 'Salario'),
                          ),
                          const SizedBox(height: 12),
                          _DDropdown(
                            label: 'Período',
                            value: periodo,
                            items: const [
                              'Semanal', 'Quincenal', 'Mensual'
                            ],
                            onChanged: (v) => setDialogState(
                                () => periodo = v ?? 'Quincenal'),
                          ),
                        ])
                      : Row(children: [
                          Expanded(
                            child: _DDropdown(
                              label: 'Tipo',
                              value: tipo,
                              items: const [
                                'Salario', 'Adelanto', 'Bono', 'Deducción'
                              ],
                              onChanged: (v) => setDialogState(
                                  () => tipo = v ?? 'Salario'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DDropdown(
                              label: 'Período',
                              value: periodo,
                              items: const [
                                'Semanal', 'Quincenal', 'Mensual'
                              ],
                              onChanged: (v) => setDialogState(
                                  () => periodo = v ?? 'Quincenal'),
                            ),
                          ),
                        ]),
                  const SizedBox(height: 12),
                  // Monto + Método
                  w < 400
                      ? Column(children: [
                          _DField(
                            ctrl: montoCtrl,
                            label: 'Monto',
                            prefixText: '\$ ',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _DDropdown(
                            label: 'Método',
                            value: metodo,
                            items: const [
                              'Transferencia', 'Efectivo', 'Depósito'
                            ],
                            onChanged: (v) => setDialogState(
                                () => metodo = v ?? 'Transferencia'),
                          ),
                        ])
                      : Row(children: [
                          Expanded(
                            child: _DField(
                              ctrl: montoCtrl,
                              label: 'Monto',
                              prefixText: '\$ ',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DDropdown(
                              label: 'Método',
                              value: metodo,
                              items: const [
                                'Transferencia', 'Efectivo', 'Depósito'
                              ],
                              onChanged: (v) => setDialogState(
                                  () => metodo = v ?? 'Transferencia'),
                            ),
                          ),
                        ]),
                  const SizedBox(height: 12),
                  _DField(ctrl: notasCtrl, label: 'Notas'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).primaryColor,
                  foregroundColor: Colors.white),
              onPressed: () {
                final nueva = NominaPago(
                  id: nomina?.id ?? '',
                  fecha: fechaCtrl.text,
                  empleadoNombre: empleadoCtrl.text,
                  tipo: tipo,
                  periodo: periodo,
                  monto: double.tryParse(montoCtrl.text) ?? 0.0,
                  metodo: metodo,
                  notas: notasCtrl.text,
                );
                if (nomina == null) {
                  provider.agregarNomina(nueva);
                } else {
                  provider.actualizarNomina(nomina.id, nueva);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NominasProvider>();
    final paginated = provider.paginatedNominas;
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final hPad = w < 480 ? 16.0 : 24.0;
            final isCompact = w < 600;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── HEADER ────────────────────────────────────
                      if (isCompact) ...[
                        SectionHeader(
                          title: '💼 Nóminas y Pagos',
                          subtitle:
                              '${provider.nominasFiltradas.length} registros',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Pago',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openEditor(provider),
                          ),
                        ),
                      ] else ...[
                        SectionHeader(
                          title: '💼 Nóminas y Pagos',
                          subtitle:
                              '${provider.nominasFiltradas.length} registros de transacciones',
                          actionLabel: 'Agregar Pago',
                          onAction: () => _openEditor(provider),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── BUSCADOR ──────────────────────────────────
                      TextField(
                        style: TextStyle(color: primaryTextColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText:
                              'Buscar pago por empleado, tipo o método...',
                        ),
                        onChanged: provider.setSearch,
                      ),

                      const SizedBox(height: 14),

                      // ── CHIPS DE TIPO ─────────────────────────────
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.tipos.length,
                          itemBuilder: (context, idx) {
                            final t = provider.tipos[idx];
                            final isSel = provider.selectedType == t;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(t,
                                    style: TextStyle(
                                        fontSize: isCompact ? 12 : 13)),
                                selected: isSel,
                                selectedColor:
                                    Theme.of(context).primaryColor,
                                labelStyle: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : primaryTextColor,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor:
                                    Theme.of(context).cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color:
                                          Theme.of(context).dividerColor),
                                ),
                                onSelected: (_) => provider.setType(t),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── CARD TOTAL MENSUAL ────────────────────────
                      AppCard(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total pagado este mes',
                                    style: TextStyle(
                                        color: mutedTextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _money.format(provider.totalMensual),
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── LISTA / EMPTY STATE ───────────────────────
                      if (paginated.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 32),
                          child: EmptyState(
                            message:
                                'No hay registros de nómina que coincidan con la búsqueda.',
                            icon: Icons.payments_outlined,
                            actionLabel: 'Limpiar Filtros',
                            onAction: () {
                              provider.setSearch('');
                              provider.setType('Todos');
                            },
                          ),
                        )
                      else
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: paginated.length,
                              separatorBuilder: (_, __) => Divider(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.5),
                                height: 1,
                              ),
                              itemBuilder: (_, index) {
                                final nomina = paginated[index];
                                return _NominaTile(
                                  nomina: nomina,
                                  money: _money,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  isCompact: isCompact,
                                  onEdit: () => _openEditor(provider,
                                      nomina: nomina),
                                  onDelete: () =>
                                      provider.eliminarNomina(nomina.id),
                                );
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ── PAGINACIÓN ────────────────────────────────
                      if (provider.totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: provider.currentPage > 1
                                    ? () => provider.changePage(
                                        provider.currentPage - 1)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .dividerColor)),
                                child: Text(isCompact
                                    ? '← Ant.'
                                    : 'Anterior'),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Pág. ${provider.currentPage}/${provider.totalPages}',
                                style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 14),
                              OutlinedButton(
                                onPressed: provider.currentPage <
                                        provider.totalPages
                                    ? () => provider.changePage(
                                        provider.currentPage + 1)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .dividerColor)),
                                child: Text(isCompact
                                    ? 'Sig. →'
                                    : 'Siguiente'),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

/// Tile de una nómina — layout diferente en móvil vs tablet+
class _NominaTile extends StatelessWidget {
  const _NominaTile({
    required this.nomina,
    required this.money,
    required this.primaryTextColor,
    required this.mutedTextColor,
    required this.isCompact,
    required this.onEdit,
    required this.onDelete,
  });

  final NominaPago nomina;
  final NumberFormat money;
  final Color primaryTextColor;
  final Color mutedTextColor;
  final bool isCompact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      // Móvil: columna con monto destacado y acciones al pie
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nomina.empleado,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  money.format(nomina.monto),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${nomina.tipo} · ${nomina.periodo} · ${nomina.fecha}',
              style: TextStyle(color: mutedTextColor, fontSize: 12),
            ),
            if (nomina.metodo.isNotEmpty)
              Text(
                nomina.metodo,
                style: TextStyle(color: mutedTextColor, fontSize: 11),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blueGrey, size: 18),
                  tooltip: 'Editar',
                  onPressed: onEdit,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 18),
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Tablet / escritorio: ListTile original
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(nomina.empleado,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: primaryTextColor)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${nomina.tipo} · ${nomina.periodo} · ${nomina.fecha}',
          style: TextStyle(color: mutedTextColor),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            money.format(nomina.monto),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.green),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.blueGrey, size: 20),
            tooltip: 'Editar',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// TextField reutilizable para el diálogo
class _DField extends StatelessWidget {
  const _DField({
    required this.ctrl,
    required this.label,
    this.prefixText,
    this.keyboardType,
  });
  final TextEditingController ctrl;
  final String label;
  final String? prefixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// DropdownButtonFormField reutilizable para el diálogo
class _DDropdown extends StatelessWidget {
  const _DDropdown({
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
      dropdownColor: Theme.of(context).cardColor,
      initialValue: value,
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
    );
  }
}