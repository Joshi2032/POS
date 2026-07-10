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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _formPosition = 'Mesero';
  bool _formActive = true;
  bool _crearAcceso = true;
  bool _obscurePassword = true;

  List<String> _selectedAreas = [];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _salaryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirFormularioModal(
    EmpleadosProvider provider, {
    Empleado? empleado,
  }) async {
    await provider.cargarAreasDisponibles();

    if (empleado != null) {
      _selectedAreas = await provider.obtenerAreasEmpleado(empleado.id);
    } else {
      _selectedAreas = [];
    }

    if (!mounted) return;

    if (empleado != null) {
      _firstNameCtrl.text = empleado.firstName;
      _lastNameCtrl.text = empleado.lastName;
      _emailCtrl.text = empleado.email;
      _passwordCtrl.clear();
      _salaryCtrl.text = empleado.salary?.toString() ?? '';
      _notesCtrl.text = empleado.notes ?? '';
      _formPosition = empleado.position;
      _formActive = empleado.active;
      _crearAcceso = false;
    } else {
      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _salaryCtrl.clear();
      _notesCtrl.clear();
      _formPosition = 'Mesero';
      _formActive = true;
      _crearAcceso = true;
    }

    _obscurePassword = true;
    bool guardando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final anchoPantalla = MediaQuery.sizeOf(dialogContext).width;

            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: anchoPantalla < 480 ? 16 : 40,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                empleado != null ? 'Editar Empleado' : 'Nuevo Empleado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: anchoPantalla < 560 ? double.infinity : 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _firstNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre(s)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apellido(s)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'empleado@correo.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'El correo es obligatorio';
                            }

                            final emailValido = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email);

                            if (!emailValido) {
                              return 'Ingresa un correo válido';
                            }

                            return null;
                          },
                        ),

                        if (empleado == null) ...[
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Crear acceso para iniciar sesión',
                            ),
                            subtitle: const Text(
                              'Crea el usuario en Authentication con correo y contraseña.',
                            ),
                            value: _crearAcceso,
                            onChanged: (value) {
                              setModalState(() {
                                _crearAcceso = value;
                              });
                            },
                          ),
                          if (_crearAcceso) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña temporal',
                                hintText: 'Mínimo 6 caracteres',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (!_crearAcceso) return null;

                                final password = value?.trim() ?? '';

                                if (password.isEmpty) {
                                  return 'La contraseña es obligatoria';
                                }

                                if (password.length < 6) {
                                  return 'Mínimo 6 caracteres';
                                }

                                return null;
                              },
                            ),
                          ],
                        ],

                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          dropdownColor: Theme.of(context).cardColor,
                          initialValue: _formPosition,
                          decoration: const InputDecoration(
                            labelText: 'Puesto',
                            border: OutlineInputBorder(),
                          ),
                          items: provider.roles
                              .where((r) => r != 'Todos')
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() {
                                _formPosition = value;

                                if (_formPosition != 'Mesero') {
                                  _selectedAreas = [];
                                }
                              });
                            }
                          },
                        ),

                        if (_formPosition == 'Mesero') ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Áreas asignadas',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (provider.areasDisponibles.isEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No hay áreas registradas en mesas.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: provider.areasDisponibles.map((area) {
                                  final selected =
                                      _selectedAreas.contains(area);

                                  return FilterChip(
                                    label: Text(area),
                                    selected: selected,
                                    onSelected: (value) {
                                      setModalState(() {
                                        if (value) {
                                          _selectedAreas.add(area);
                                        } else {
                                          _selectedAreas.remove(area);
                                        }

                                        _selectedAreas = _selectedAreas
                                            .map((item) => item.trim())
                                            .where((item) => item.isNotEmpty)
                                            .toSet()
                                            .toList();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                        ],

                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _salaryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Salario Mensual (\$)',
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Notas / Observaciones',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estatus Activo'),
                            Switch(
                              value: _formActive,
                              activeThumbColor: Colors.green,
                              onChanged: (value) {
                                setModalState(() {
                                  _formActive = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          if (_formPosition == 'Mesero' &&
                              _selectedAreas.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selecciona al menos un área para el mesero.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final fechaHoy = DateTime.now()
                              .toIso8601String()
                              .split('T')[0];

                          final nuevo = Empleado(
                            id: empleado?.id ?? '',
                            profileId: empleado?.profileId,
                            firstName: _firstNameCtrl.text.trim(),
                            lastName: _lastNameCtrl.text.trim(),
                            email: _emailCtrl.text.trim().toLowerCase(),
                            position: _formPosition,
                            hireDate: empleado?.hireDate ?? fechaHoy,
                            salary:
                                double.tryParse(_salaryCtrl.text.trim()),
                            notes: _notesCtrl.text.trim().isNotEmpty
                                ? _notesCtrl.text.trim()
                                : null,
                            active: _formActive,
                          );

                          setModalState(() => guardando = true);

                          bool exito;

                          if (empleado != null) {
                            exito = await provider.actualizarEmpleado(
                              empleado.id,
                              nuevo,
                              areasAsignadas: _selectedAreas,
                            );
                          } else {
                            if (_crearAcceso) {
                              exito =
                                  await provider.agregarEmpleadoConAcceso(
                                nuevo,
                                password: _passwordCtrl.text.trim(),
                                areasAsignadas: _selectedAreas,
                              );
                            } else {
                              exito = await provider.agregarEmpleado(
                                nuevo,
                                areasAsignadas: _selectedAreas,
                              );
                            }
                          }

                          if (!context.mounted) return;

                          if (exito) {
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  empleado != null
                                      ? 'Empleado actualizado correctamente.'
                                      : _crearAcceso
                                          ? 'Empleado y acceso creados correctamente.'
                                          : 'Empleado creado correctamente.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            setModalState(() => guardando = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.errorMessage ??
                                      'Error al guardar en Supabase',
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 6),
                              ),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          empleado != null ? 'Guardar Cambios' : 'Añadir',
                        ),
                ),
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
                    hint: 'Buscar empleado por nombre.',
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
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    initialValue: provider.selectedRol,
                    items: provider.roles
                        .map(
                          (rol) => DropdownMenuItem(
                            value: rol,
                            child: Text(rol),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.setSelectedRol(value);
                      }
                    },
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
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) {
                        final emp = filtrados[index];

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
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      emp.position,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (emp.active
                                              ? Colors.green
                                              : Colors.red)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      emp.active ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: emp.active
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${emp.firstName} ${emp.lastName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                emp.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _abrirFormularioModal(
                                          provider,
                                          empleado: emp,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Editar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text(
                                              'Eliminar empleado',
                                            ),
                                            content: Text(
                                              '¿Eliminar a ${emp.firstName} ${emp.lastName}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(
                                                    context,
                                                    false,
                                                  );
                                                },
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(
                                                    context,
                                                    true,
                                                  );
                                                },
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red,
                                                ),
                                                child:
                                                    const Text('Eliminar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm != true) return;

                                      final ok = await provider
                                          .eliminarEmpleado(emp.id);

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok
                                                ? 'Empleado eliminado.'
                                                : provider.errorMessage ??
                                                    'Error al eliminar.',
                                          ),
                                          backgroundColor: ok
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
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