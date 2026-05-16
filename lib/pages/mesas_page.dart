import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/form_widgets.dart';

class MesasPage extends StatefulWidget {
  const MesasPage({super.key});

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  String search = '';
  int currentPage = 1;
  final pageSize = 12;

  void _openEditor({Map<String, dynamic>? mesa}) {
    final idController = TextEditingController(
        text: mesa?['id'] ?? 'M-${DateTime.now().millisecondsSinceEpoch}');
    final nameController = TextEditingController(text: mesa?['name'] ?? '');
    final capacidadController =
        TextEditingController(text: mesa?['capacidad']?.toString() ?? '4');
    final areaController = TextEditingController(text: mesa?['area'] ?? 'Sala');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(mesa == null ? 'Nueva Mesa' : 'Editar Mesa',
            style: Theme.of(context).textTheme.headlineMedium),
        content: SingleChildScrollView(
          child: Column(
            children: [
              FormFieldWidget(
                  label: 'ID', hint: 'M-001', controller: idController),
              FormFieldWidget(
                  label: 'Nombre', hint: 'Mesa 1', controller: nameController),
              FormFieldWidget(
                  label: 'Capacidad',
                  hint: '4',
                  controller: capacidadController,
                  keyboardType: TextInputType.number),
              FormFieldWidget(
                  label: 'Área', hint: 'Sala', controller: areaController),
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
                'name': nameController.text.trim(),
                'capacidad': int.tryParse(capacidadController.text) ?? 4,
                'area': areaController.text.trim(),
                'estado': mesa?['estado'] ?? 'Libre'
              };
              if (mesa == null) {
                app.addMesa(data);
              } else {
                app.updateMesa(mesa['id'], data);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final mesas = app.mesas.where((m) {
      if (search.isEmpty) return true;
      final q = search.toLowerCase();
      return [m['name'], m['area'], m['estado']]
          .whereType<String>()
          .any((v) => v.toLowerCase().contains(q));
    }).toList();

    final totalPages = (mesas.length / pageSize).ceil().clamp(1, 999999);
    final start = (currentPage - 1) * pageSize;
    final paginated = mesas.skip(start).take(pageSize).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mesas')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.lg),
        child: Column(
          children: [
            CustomSearchBar(
                hint: 'Buscar mesas por nombre o área...',
                onChanged: (value) => setState(() {
                      search = value;
                      currentPage = 1;
                    })),
            const SizedBox(height: AppTheme.lg),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('${mesas.length} mesa(s)',
                    style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: AppTheme.md),
            Expanded(
              child: paginated.isEmpty
                  ? EmptyState(
                      message: 'No hay mesas que coincidan con tu búsqueda',
                      actionLabel: 'Agregar Mesa',
                      onAction: _openEditor)
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.md),
                      itemBuilder: (_, index) {
                        final mesa = paginated[index];
                        final estado = mesa['estado'] ?? 'Libre';
                        final statusColor = estado == 'Libre'
                            ? AppTheme.successColor
                            : estado == 'Ocupada'
                                ? AppTheme.warningColor
                                : AppTheme.errorColor;
                        return AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd)),
                                child: Center(
                                    child: Icon(Icons.table_restaurant,
                                        color: statusColor, size: 24)),
                              ),
                              const SizedBox(width: AppTheme.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mesa['name'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    Text(
                                        '${mesa['capacidad']} personas · ${mesa['area']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.md,
                                    vertical: AppTheme.sm),
                                decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd)),
                                child: Text(estado,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: AppTheme.md),
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openEditor(mesa: mesa)),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => app.removeMesa(mesa['id'])),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (totalPages > 1)
              PaginationWidget(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPrevious: () => setState(() => currentPage--),
                  onNext: () => setState(() => currentPage++)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _openEditor,
          icon: const Icon(Icons.add),
          label: const Text('Nueva Mesa')),
    );
  }
}
