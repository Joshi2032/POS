import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/categorias_provider.dart';

class CategoriasPage extends StatelessWidget {
  const CategoriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoriasView();
  }
}

class _CategoriasView extends StatelessWidget {
  const _CategoriasView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoriasProvider>();
    final categorias = provider.categorias;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva categoría',
            onPressed: () => _mostrarDialogoCategoria(context, null),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.hasError
              ? Center(
                  child: Text(
                      provider.errorMessage ?? 'Error al cargar categorías'))
              : categorias.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No hay categorías registradas.'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Crear categoría'),
                            onPressed: () =>
                                _mostrarDialogoCategoria(context, null),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final categoria = categorias[index];
                        return ListTile(
                          title: Text(categoria['name']?.toString() ?? ''),
                          subtitle: Text(categoria['active'] == true
                              ? 'Activa'
                              : 'Inactiva'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
  icon: Icon(
    categoria['active'] == true
        ? Icons.visibility
        : Icons.visibility_off,
    color: categoria['active'] == true
        ? Colors.green
        : Colors.orange,
  ),
  tooltip: categoria['active'] == true
      ? 'Desactivar'
      : 'Activar',
  onPressed: provider.isLoading
      ? null
      : () async {
          final id = categoria['id']?.toString();
          if (id == null) return;

          final exito = await provider.toggleCategoria(
            id,
            !(categoria['active'] == true),
          );

          if (!exito && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.errorMessage ??
                      'No se pudo actualizar la categoría.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Editar categoría',
                                onPressed: () => _mostrarDialogoCategoria(
                                    context, categoria),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Eliminar categoría',
                                onPressed: () =>
                                    _confirmDelete(context, categoria),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(),
                      itemCount: categorias.length,
                    ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Map<String, dynamic> categoria) async {
    final provider = context.read<CategoriasProvider>();
    final nombre = categoria['name']?.toString() ?? 'categoría';
    final id = categoria['id']?.toString();
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar categoría'),
          content: Text(
              '¿Eliminar la categoría "$nombre"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await provider.deleteCategoria(id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Categoría "$nombre" eliminada'
            : provider.errorMessage ?? 'No se pudo eliminar la categoría'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _mostrarDialogoCategoria(
      BuildContext context, Map<String, dynamic>? categoria) async {
    final provider = context.read<CategoriasProvider>();
    final nombreCtrl =
        TextEditingController(text: categoria?['name']?.toString() ?? '');
    final isEditing = categoria != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar categoría' : 'Nueva categoría'),
          content: TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();
                if (nombre.isEmpty) return;

                bool success;
                if (isEditing) {
                  final id = categoria['id']?.toString();
                  if (id == null) return;
                  success = await provider.updateCategoria(id, nombre);
                } else {
                  success = await provider.addCategoria(nombre);
                }

                if (!dialogContext.mounted) return;
                if (success) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Categoría "$nombre" ${isEditing ? 'actualizada' : 'creada'}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ??
                          'Error al guardar categoría'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    nombreCtrl.dispose();
  }
}
