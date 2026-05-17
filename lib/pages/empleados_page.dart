import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/search_bar.dart';

class Empleado {
  final String nombre;
  final String rol;
  final String telefono;
  final bool activo;

  Empleado({
    required this.nombre,
    required this.rol,
    required this.telefono,
    this.activo = true,
  });
}

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final List<Empleado> _empleados = [
    Empleado(nombre: 'Carlos Mendoza', rol: 'Mesero', telefono: '3521234567'),
    Empleado(nombre: 'Ana Rodríguez', rol: 'Cocinero', telefono: '3527654321'),
    Empleado(nombre: 'Juan Pérez', rol: 'Administrador', telefono: '3529876543'),
    Empleado(nombre: 'Sofia Gómez', rol: 'Cajero', telefono: '3524567890', activo: false),
  ];

  String _searchTerm = '';
  String _selectedRol = 'Todos';

  final List<String> _roles = ['Todos', 'Administrador', 'Cocinero', 'Mesero', 'Cajero'];

  List<Empleado> get _empleadosFiltrados {
    return _empleados.where((e) {
      final matchesSearch = e.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          e.telefono.contains(_searchTerm);
      final matchesRol = _selectedRol == 'Todos' || e.rol == _selectedRol;
      return matchesSearch && matchesRol;
    }).toList();
  }

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  String _formRol = 'Mesero';
  bool _formActivo = true;

  void _abrirFormularioModal({Empleado? empleado, int? index}) {
    if (empleado != null) {
      _nombreCtrl.text = empleado.nombre;
      _telefonoCtrl.text = empleado.telefono;
      _formRol = empleado.rol;
      _formActivo = empleado.activo;
    } else {
      _nombreCtrl.clear();
      _telefonoCtrl.clear();
      _formRol = 'Mesero';
      _formActivo = true;
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
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).cardColor,
                        value: _formRol,
                        decoration: const InputDecoration(labelText: 'Puesto / Rol', border: OutlineInputBorder()),
                        items: _roles.where((r) => r != 'Todos').map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (v) => setModalState(() => _formRol = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefonoCtrl,
                        decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
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
                            onChanged: (v) => setModalState(() => _formActivo = v),
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final nuevo = Empleado(
                        nombre: _nombreCtrl.text,
                        rol: _formRol,
                        telefono: _telefonoCtrl.text,
                        activo: _formActivo,
                      );
                      setState(() {
                        if (index != null) {
                          _empleados[index] = nuevo;
                        } else {
                          _empleados.add(nuevo);
                        }
                      });
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
    final filtrados = _empleadosFiltrados;

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
              onAction: () => _abrirFormularioModal(),
            ),
            const SizedBox(height: 24),
            
            // Barra de filtrado completamente adaptada al modo oscuro
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomSearchBar(
                    hint: 'Buscar empleado por nombre...',
                    onChanged: (v) => setState(() => _searchTerm = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    value: _selectedRol,
                    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setState(() => _selectedRol = v!),
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
                      onAction: () => setState(() { _searchTerm = ''; _selectedRol = 'Todos'; }),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(emp.rol, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (emp.activo ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(emp.activo ? 'Activo' : 'Inactivo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emp.activo ? Colors.green : Colors.red)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(emp.nombre, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Tel: ${emp.telefono}', style: Theme.of(context).textTheme.bodySmall),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                    onPressed: () => _abrirFormularioModal(empleado: emp, index: _empleados.indexOf(emp)),
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