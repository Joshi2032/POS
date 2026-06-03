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
    final idController = TextEditingController(
        text: nomina?.id ?? 'NOM-${DateTime.now().millisecondsSinceEpoch}');
    final fechaController = TextEditingController(
        text:
            nomina?.fecha ?? DateTime.now().toIso8601String().split('T').first);
    final empleadoController =
        TextEditingController(text: nomina?.empleado ?? '');
    final montoController =
        TextEditingController(text: nomina?.monto.toString() ?? '0');
    final notasController = TextEditingController(text: nomina?.notas ?? '');
    String tipo = nomina?.tipo ?? 'Salario';
    String periodo = nomina?.periodo ?? 'Quincenal';
    String metodo = nomina?.metodo ?? 'Transferencia';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(nomina == null ? 'Agregar Pago' : 'Editar Pago',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                        labelText: 'ID', border: OutlineInputBorder()),
                    readOnly: true),
                const SizedBox(height: 12),
                TextField(
                    controller: fechaController,
                    decoration: const InputDecoration(
                        labelText: 'Fecha', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: empleadoController,
                    decoration: const InputDecoration(
                        labelText: 'Empleado', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Theme.of(context).cardColor,
                  initialValue: tipo,
                  items: ['Salario', 'Adelanto', 'Bono', 'Deducción']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => tipo = value ?? 'Salario'),
                  decoration: const InputDecoration(
                      labelText: 'Tipo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Theme.of(context).cardColor,
                  initialValue: periodo,
                  items: ['Semanal', 'Quincenal', 'Mensual']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => periodo = value ?? 'Quincenal'),
                  decoration: const InputDecoration(
                      labelText: 'Período', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: montoController,
                    decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixText: '\$ ',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Theme.of(context).cardColor,
                  initialValue: metodo,
                  items: ['Transferencia', 'Efectivo', 'Depósito']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => metodo = value ?? 'Transferencia'),
                  decoration: const InputDecoration(
                      labelText: 'Método', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: notasController,
                    decoration: const InputDecoration(
                        labelText: 'Notas', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white),
              onPressed: () {
                final nuevaNomina = NominaPago(
                  id: idController.text,
                  fecha: fechaController.text,
                  empleadoNombre: empleadoController.text, // <--- AQUÍ ESTÁ LA CORRECCIÓN
                  tipo: tipo,
                  periodo: periodo,
                  monto: double.tryParse(montoController.text) ?? 0.0,
                  metodo: metodo,
                  notas: notasController.text,
                );

                if (nomina == null) {
                  provider.agregarNomina(nuevaNomina);
                } else {
                  provider.actualizarNomina(
                      nomina.id, nuevaNomina); // Usamos .id
                }
                Navigator.pop(context);
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '💼 Nóminas y Pagos',
              subtitle:
                  '${provider.nominasFiltradas.length} registros de transacciones',
              actionLabel: 'Agregar Pago',
              onAction: () => _openEditor(provider),
            ),
            const SizedBox(height: 24),
            TextField(
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar pago por empleado, tipo o método...'),
              onChanged: provider.setSearch,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.tipos.length,
                itemBuilder: (context, idx) {
                  final t = provider.tipos[idx];
                  final isSelected = provider.selectedType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: isSelected,
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : primaryTextColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor)),
                      onSelected: (selected) => provider.setType(t),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total pagado este mes',
                            style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          _money.format(provider.totalMensual),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor),
                        ),
                      ],
                    ),
                    Icon(Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).primaryColor, size: 28),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: paginated.isEmpty
                  ? EmptyState(
                      message:
                          'No hay registros de nómina que coincidan con la búsqueda.',
                      icon: Icons.payments_outlined,
                      actionLabel: 'Limpiar Filtros',
                      onAction: () {
                        provider.setSearch('');
                        provider.setType('Todos');
                      },
                    )
                  : AppCard(
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ListView.separated(
                            itemCount: paginated.length,
                            separatorBuilder: (_, __) => Divider(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.5),
                              height: 1,
                            ),
                            itemBuilder: (_, index) {
                              final nomina = paginated[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text(nomina.empleado,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                      '${nomina.tipo} · ${nomina.periodo} · ${nomina.fecha}',
                                      style: TextStyle(color: mutedTextColor)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_money.format(nomina.monto),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: Colors.green)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.blueGrey, size: 20),
                                      tooltip: 'Editar',
                                      onPressed: () =>
                                          _openEditor(provider, nomina: nomina),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent, size: 20),
                                      tooltip: 'Eliminar',
                                      onPressed: () =>
                                          provider.eliminarNomina(nomina.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
            if (provider.totalPages > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: provider.currentPage > 1
                        ? () => provider.changePage(provider.currentPage - 1)
                        : null,
                    style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: Theme.of(context).dividerColor)),
                    child: const Text('Anterior'),
                  ),
                  const SizedBox(width: 16),
                  Text(
                      'Página ${provider.currentPage} de ${provider.totalPages}',
                      style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  // En la lógica de paginación (abajo en el build):
                  OutlinedButton(
                    onPressed: provider.currentPage > 1
                        ? () => provider.changePage(provider.currentPage - 1)
                        : null,
                    child: const Text('Anterior'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}