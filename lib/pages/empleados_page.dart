import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/form_widgets.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  String search = '';
  int currentPage = 1;
  final pageSize = 12;

  void _openEditor({Map<String, dynamic>? empleado}) {
    final idController = TextEditingController(
      text: empleado?['id'] ?? 'E-${DateTime.now().millisecondsSinceEpoch}',
    );
    final nameController = TextEditingController(text: empleado?['name'] ?? '');
    final emailController =
        TextEditingController(text: empleado?['email'] ?? '');
    final roleController =
        TextEditingController(text: empleado?['role'] ?? 'Empleado');
    bool activo = empleado?['active'] ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: Text(
            empleado == null ? 'Nuevo Empleado' : 'Editar Empleado',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormFieldWidget(
                  label: 'ID',
                  hint: 'E-001',
                  controller: idController,
                ),
                FormFieldWidget(
                  label: 'Nombre',
                  hint: 'Juan Pérez',
                  controller: nameController,
                ),
                FormFieldWidget(
                  label: 'Correo',
                  hint: 'juan@email.com',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                FormFieldWidget(
                  label: 'Rol',
                  hint: 'Empleado',
                  controller: roleController,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.md),
                  child: SwitchListTile(
                    value: activo,
                    onChanged: (v) => setSt(() => activo = v),
                    title: const Text('Activo'),
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final app = context.read<AppState>();
                final data = {
                  'id': idController.text,
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'role': roleController.text.trim(),
                  'active': activo,
                };
                if (empleado == null) {
                  app.addEmpleado(data);
                } else {
                  app.updateEmpleado(empleado['id'], data);
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final empleados = app.empleados.where((e) {
      if (search.isEmpty) return true;
      final q = search.toLowerCase();
      return [e['name'], e['email'], e['role']]
          .whereType<String>()
          .any((v) => v.toLowerCase().contains(q));
    }).toList();

    final totalPages = (empleados.length / pageSize).ceil().clamp(1, 999999);
    final start = (currentPage - 1) * pageSize;
    final paginated = empleados.skip(start).take(pageSize).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Empleados')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.lg),
        child: Column(
          children: [
            CustomSearchBar(
              hint: 'Buscar empleados por nombre o correo...',
              onChanged: (value) => setState(() {
                search = value;
                currentPage = 1;
              }),
            ),
            const SizedBox(height: AppTheme.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${empleados.length} empleado(s)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppTheme.md),
            Expanded(
              child: paginated.isEmpty
                  ? EmptyState(
                      message: 'No hay empleados que coincidan con tu búsqueda',
                      actionLabel: 'Agregar Empleado',
                      onAction: _openEditor,
                    )
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.md),
                      itemBuilder: (_, index) {
                        final empleado = paginated[index];
                        final activo = empleado['active'] ?? true;
                        return AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.person,
                                    color: AppTheme.secondaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      empleado['name'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      '${empleado['role']} · ${empleado['email']}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.md,
                                  vertical: AppTheme.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: (activo
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: Text(
                                  activo ? 'Activo' : 'Inactivo',
                                  style: TextStyle(
                                    color: activo
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.md),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _openEditor(empleado: empleado),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    app.removeEmpleado(empleado['id']),
                              ),
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
                onNext: () => setState(() => currentPage++),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Empleado'),
      ),
    );
  }
}
