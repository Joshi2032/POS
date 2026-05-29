import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/empleado.dart';
import '../providers/empleados_provider.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/search_bar.dart';

class EmpleadosPage extends StatelessWidget {
  const EmpleadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EmpleadosView();
  }
}

class _EmpleadosView extends StatefulWidget {
  const _EmpleadosView();

  @override
  State<_EmpleadosView> createState() => _EmpleadosViewState();
}

class _EmpleadosViewState extends State<_EmpleadosView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _formPosition = 'Mesero';
  bool _formActive = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _salaryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _abrirFormularioModal(EmpleadosProvider provider, {Empleado? empleado}) {
    if (empleado != null) {
      _firstNameCtrl.text = empleado.firstName;
      _lastNameCtrl.text = empleado.lastName;
      _salaryCtrl.text = empleado.salary?.toString() ?? '';
      _notesCtrl.text = empleado.notes ?? '';
      _formPosition = empleado.position;
      _formActive = empleado.active;
    } else {
      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _salaryCtrl.clear();
      _notesCtrl.clear();
      _formPosition = 'Mesero';
      _formActive = true;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(empleado != null ? 'Editar Empleado' : 'Nuevo Empleado',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre(s)', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(labelText: 'Apellido(s)', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).cardColor,
                        value: _formPosition,
                        decoration: const InputDecoration(labelText: 'Puesto / Puesto', border: OutlineInputBorder()),
                        items: provider.roles
                            .where((r) => r != 'Todos')
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setModalState(() => _formPosition = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _salaryCtrl,
                        decoration: const InputDecoration(labelText: 'Salario Mensual (\$)', border: OutlineInputBorder(), prefixText: '\$'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(labelText: 'Notas / Observaciones', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estatus Activo'),
                          Switch(
                            value: _formActive,
                            activeColor: Colors.green,
                            onChanged: (v) => setModalState(() => _formActive = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final nuevo = Empleado(
                        id: empleado?.id ?? '',
                        profileId: empleado?.profileId,
                        firstName: _firstNameCtrl.text,
                        lastName: _lastNameCtrl.text,
                        position: _formPosition,
                        salary: double.tryParse(_salaryCtrl.text),
                        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
                        active: _formActive,
                      );

                      bool exito;
                      if (empleado != null) {
                        exito = await provider.actualizarEmpleado(empleado.id, nuevo);
                      } else {
                        exito = await provider.agregarEmpleado(nuevo);
                      }

                      if (exito) {
                        if (context.mounted) Navigator.pop(context);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.errorMessage ?? 'Error al guardar en Supabase'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(empleado != null ? 'Guardar' : 'Agregar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmpleadosProvider>();
    final filtrados = provider.empleadosFiltrados;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '👥 Personal y Empleados',
              subtitle: '${filtrados.length} empleados en catálogo',
              actionLabel: 'Nuevo Empleado',
              onAction: () => _abrirFormularioModal(provider),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomSearchBar(
                    hint: 'Buscar empleado por nombre...',
                    onChanged: provider.setSearchTerm,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    value: provider.selectedRol,
                    items: provider.roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => provider.setSelectedRol(v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyState(
                      message: 'No se encontraron colaboradores con este filtro.',
                      icon: Icons.person_off_outlined,
                      actionLabel: 'Restablecer',
                      onAction: () {
                        provider.setSearchTerm('');
                        provider.setSelectedRol('Todos');
                      },
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (context, idx) {
                        final emp = filtrados[idx];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(emp.position,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (emp.active ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(emp.active ? 'Activo' : 'Inactivo',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emp.active ? Colors.green : Colors.red)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('${emp.firstName} ${emp.lastName}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (emp.salary != null)
                                Text('Salario: \$${emp.salary!.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                              if (emp.notes != null && emp.notes!.isNotEmpty)
                                Text('Nota: ${emp.notes}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                    onPressed: () => _abrirFormularioModal(provider, empleado: emp),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    onPressed: () => provider.eliminarEmpleado(emp.id),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}