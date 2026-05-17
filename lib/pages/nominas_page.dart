import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/app_widgets.dart'; // Importamos tus componentes AppCard y SectionHeader
import '../widgets/layout_widgets.dart'; // Importamos tu componente EmptyState

class NominasPage extends StatefulWidget {
  const NominasPage({super.key});

  @override
  State<NominasPage> createState() => _NominasPageState();
}

class _NominasPageState extends State<NominasPage> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  String search = '';
  String selectedType = 'Todos';
  int currentPage = 1;
  final pageSize = 10;
  final tipos = ['Todos', 'Salario', 'Adelanto', 'Bono', 'Deducción'];

  void _openEditor({Map<String, dynamic>? nomina}) {
    final idController = TextEditingController(
        text: nomina?['id'] ?? 'NOM-${DateTime.now().millisecondsSinceEpoch}');
    final fechaController = TextEditingController(
        text: nomina?['fecha'] ??
            DateTime.now().toIso8601String().split('T').first);
    final empleadoController =
        TextEditingController(text: nomina?['empleado'] ?? '');
    final montoController =
        TextEditingController(text: nomina?['monto']?.toString() ?? '0');
    final notasController = TextEditingController(text: nomina?['notas'] ?? '');
    String tipo = nomina?['tipo'] ?? 'Salario';
    String periodo = nomina?['periodo'] ?? 'Quincenal';
    String metodo = nomina?['metodo'] ?? 'Transferencia';

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
                  dropdownColor: Theme.of(context)
                      .cardColor, // Selector flotante adaptativo al tema
                  initialValue:
                      tipo, // Corrección sintáctica para Flutter 3.33+
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
              onPressed: () {
                final app = context.read<AppState>();
                final data = {
                  'id': idController.text,
                  'fecha': fechaController.text,
                  'empleado': empleadoController.text.trim(),
                  'tipo': tipo,
                  'periodo': periodo,
                  'monto': double.tryParse(montoController.text) ?? 0.0,
                  'metodo': metodo,
                  'notas': notasController.text,
                };
                if (nomina == null) {
                  app.addNomina(data);
                } else {
                  app.updateNomina(nomina['id'], data);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final nominas = app.nominas.where((n) {
      final matchSearch = search.isEmpty ||
          [n['empleado'], n['tipo'], n['metodo']]
              .whereType<String>()
              .any((v) => v.toLowerCase().contains(search.toLowerCase()));
      final matchType = selectedType == 'Todos' || n['tipo'] == selectedType;
      return matchSearch && matchType;
    }).toList();

    final totalPages = (nominas.length / pageSize).ceil().clamp(1, 999999);
    final start = (currentPage - 1) * pageSize;
    final paginated = nominas.skip(start).take(pageSize).toList();

    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Permite heredar el fondo del MainLayout
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encabezado Oficial unificado (Reemplaza el antiguo AppBar y FloatingActionButton)
            SectionHeader(
              title: '💼 Nóminas y Pagos',
              subtitle: '${nominas.length} registros de transacciones',
              actionLabel: 'Agregar Pago',
              onAction: () => _openEditor(),
            ),
            const SizedBox(height: 24),

            // 2. Buscador adaptativo global
            TextField(
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar pago por empleado, tipo o método...',
              ),
              onChanged: (value) => setState(() {
                search = value;
                currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // 3. Chips de filtrado horizontal adaptativos (Reemplazan a los FilterChips planos)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tipos.length,
                itemBuilder: (context, idx) {
                  final t = tipos[idx];
                  final isSelected = selectedType == t;
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
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      onSelected: (selected) => setState(() {
                        selectedType = t;
                        currentPage = 1;
                      }),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 4. Tarjeta de Resumen Mensual (Pintada con tu AppCard adaptativo)
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total pagado este mes',
                        style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money.format(app
                            .totalNominasEstesMes), // Preserva tu modelo exacto
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Listado de Pagos estructurado dentro de un AppCard contenedor
            Expanded(
              child: paginated.isEmpty
                  ? EmptyState(
                      message:
                          'No hay registros de nómina que coincidan con la búsqueda.',
                      icon: Icons.payments_outlined,
                      actionLabel: 'Limpiar Filtros',
                      onAction: () => setState(() {
                        search = '';
                        selectedType = 'Todos';
                        currentPage = 1;
                      }),
                    )
                  : AppCard(
                      padding: EdgeInsets.zero,
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
                              title: Text(
                                nomina['empleado'] ?? '',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${nomina['tipo']} · ${nomina['periodo']} · ${nomina['fecha']}',
                                  style: TextStyle(color: mutedTextColor),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _money.format(nomina['monto'] ?? 0.0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.blueGrey, size: 20),
                                    tooltip: 'Editar',
                                    onPressed: () =>
                                        _openEditor(nomina: nomina),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent, size: 20),
                                    tooltip: 'Eliminar',
                                    onPressed: () =>
                                        app.removeNomina(nomina['id']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),

            // 6. Paginador adaptativo inferior
            if (totalPages > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: currentPage > 1
                        ? () => setState(() => currentPage--)
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: const Text('Anterior'),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Página $currentPage de $totalPages',
                    style: TextStyle(
                        color: primaryTextColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: currentPage < totalPages
                        ? () => setState(() => currentPage++)
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: const Text('Siguiente'),
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
