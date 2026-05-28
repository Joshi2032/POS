import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/empleado.dart';
import '../providers/empleados_provider.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/search_bar.dart';

final _telefonoCtrl = TextEditingController();

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
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  String _formRol = 'Mesero';
  bool _formActivo = true;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _abrirFormularioModal(EmpleadosProvider provider, {Empleado? empleado}) {
    if (empleado != null) {
      _nombreCtrl.text = empleado.nombre;
      _correoCtrl.text = empleado.correo;
      _formRol = empleado.rol;
      _formActivo = empleado.activo;
    } else {
      _nombreCtrl.clear();
      _correoCtrl.clear();
      _formRol = 'Mesero';
      _formActivo = true;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(
                  empleado != null ? 'Editar Empleado' : 'Nuevo Empleado',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).cardColor,
                        initialValue: _formRol,
                        decoration: const InputDecoration(
                            labelText: 'Puesto / Rol',
                            border: OutlineInputBorder()),
                        items: provider.roles
                            .where((r) => r != 'Todos')
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setModalState(() => _formRol = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _correoCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estatus Activo'),
                          Switch(
                            value: _formActivo,
                            activeThumbColor: Colors.green,
                            onChanged: (v) =>
                                setModalState(() => _formActivo = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final nuevo = Empleado(
                        id: empleado?.id ?? '', // Asegúrate de manejar el ID
                        nombre: _nombreCtrl.text,
                        rol: _formRol,
                        correo:
                            _correoCtrl.text, // Asegúrate de incluir el correo
                        activo: _formActivo,
                      );

                      if (empleado != null) {
                        provider.actualizarEmpleado(
                            empleado.id, nuevo); // Usa el nombre correcto
                      } else {
                        provider
                            .agregarEmpleado(nuevo); // Usa el nombre correcto
                      }
                      Navigator.pop(context);
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
              subtitle: '${filtrados.length} empleados activos en el turno',
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
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14),
                    decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    initialValue: provider.selectedRol,
                    items: provider.roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => provider.setSelectedRol(v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyState(
                      message:
                          'No se encontraron colaboradores con este filtro.',
                      icon: Icons.person_off_outlined,
                      actionLabel: 'Restablecer',
                      onAction: () {
                        provider.setSearchTerm('');
                        provider.setSelectedRol('Todos');
                      },
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        childAspectRatio: 1.3,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(emp.rol,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .primaryColor)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (emp.activo
                                              ? Colors.green
                                              : Colors.red)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                        emp.activo ? 'Activo' : 'Inactivo',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: emp.activo
                                                ? Colors.green
                                                : Colors.red)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(emp.nombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Email: ${emp.correo}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20, color: Colors.blueGrey),
                                    onPressed: () => _abrirFormularioModal(
                                        provider,
                                        empleado: emp),
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
