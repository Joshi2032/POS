import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../widgets/app_widgets.dart'; // <-- IMPORTANTE: Esto arregla el SectionHeader

class RecetasPage extends StatelessWidget {
  const RecetasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RecetasView();
  }
}

class _RecetasView extends StatefulWidget {
  const _RecetasView();
  @override
  State<_RecetasView> createState() => _RecetasViewState();
}

class _RecetasViewState extends State<_RecetasView> {
  Future<void> _mostrarDialogoFormulario(RecipeProvider provider, {Recipe? receta}) async {
    // FIX: Quitamos el guion bajo para evitar el lint
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: receta?.name ?? '');
    final rindeCtrl = TextEditingController(text: receta?.yieldPortions.toString() ?? '1');
    final tiempoCtrl = TextEditingController(text: receta?.prepMinutes.toString() ?? '0');
    final descCtrl = TextEditingController(text: receta?.description ?? '');

    // Lista temporal de insumos para este formulario
    List<RecipeSupply> insumosTemporales = receta != null ? List.from(receta.supplies) : [];
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(receta != null ? 'Editar Receta' : 'Nueva Receta', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width > 600 ? 500 : double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre de la receta', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: rindeCtrl,
                                decoration: const InputDecoration(labelText: 'Rinde (porciones)', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: tiempoCtrl,
                                decoration: const InputDecoration(labelText: 'Tiempo prep. (min)', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(labelText: 'Instrucciones / Notas', border: OutlineInputBorder()),
                          maxLines: 2,
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(),
                        ),
                        
                        const Text('Ingredientes (Insumos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),

                        ...insumosTemporales.asMap().entries.map((entry) {
                          final index = entry.key;
                          final insumo = entry.value;
                          return Card(
                            elevation: 0,
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                            child: ListTile(
                              dense: true,
                              title: Text(insumo.supplyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${insumo.quantity} ${insumo.unit}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setStateModal(() => insumosTemporales.removeAt(index));
                                },
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            _mostrarSelectorDeInsumo(context, provider, (nuevoInsumo) {
                              setStateModal(() => insumosTemporales.add(nuevoInsumo));
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Materia Prima'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      final nuevaReceta = Recipe(
                        id: receta?.id ?? '',
                        name: nombreCtrl.text,
                        yieldPortions: double.tryParse(rindeCtrl.text) ?? 1.0,
                        prepMinutes: int.tryParse(tiempoCtrl.text) ?? 0,
                        description: descCtrl.text,
                        supplies: insumosTemporales,
                      );

                      setStateModal(() => guardando = true);

                      bool exito;
                      if (receta != null) {
                        exito = await provider.updateRecipe(receta.id, nuevaReceta);
                      } else {
                        exito = await provider.addRecipe(nuevaReceta);
                      }

                      if (context.mounted) {
                        if (exito) {
                          Navigator.pop(context);
                        } else {
                          setStateModal(() => guardando = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage ?? 'Error'), backgroundColor: Colors.red)
                          );
                        }
                      }
                    }
                  },
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(receta != null ? 'Guardar Cambios' : 'Crear Receta'),
                )
              ],
            );
          }
        );
      },
    );

    nombreCtrl.dispose();
    rindeCtrl.dispose();
    tiempoCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _mostrarSelectorDeInsumo(BuildContext parentContext, RecipeProvider provider, Function(RecipeSupply) onAdd) async {
    if (provider.inventarioDisponible.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('No hay materia prima registrada.'), backgroundColor: Colors.orange)
      );
      return;
    }

    String? selectedInsumoId = provider.inventarioDisponible.first['id'].toString();
    final qtyCtrl = TextEditingController(text: '1');

    // 👇 1. Variables para controlar las opciones de unidad 👇
    final List<String> opcionesUnidades = ['kg', 'g', 'l', 'ml', 'pza'];
    String? unidadElegida; // Inicia en null para tomar la del inventario primero

    await showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSub) {
            final listaInsumos = provider.inventarioDisponible;

            if (listaInsumos.isEmpty) {
              return AlertDialog(
                title: const Text('Añadir Ingrediente', style: TextStyle(fontSize: 16)),
                content: const Text('Ya no hay materia prima disponible.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            if (!listaInsumos.any((i) => i['id'].toString() == selectedInsumoId)) {
              selectedInsumoId = listaInsumos.first['id'].toString();
              unidadElegida = null;
            }

            final insumoMap = listaInsumos.firstWhere(
              (i) => i['id'].toString() == selectedInsumoId,
              orElse: () => listaInsumos.first,
            );
            final currentUnit = insumoMap['unit'] ?? 'ud';

            // 👇 2. Aseguramos que la unidad del inventario no crashee el Dropdown si no está en la lista 👇
            List<String> dropDownItems = List.from(opcionesUnidades);
            if (!dropDownItems.contains(currentUnit)) {
              dropDownItems.add(currentUnit);
            }

            // Usamos la elegida por el usuario, o la por defecto
            final unidadAUsar = unidadElegida ?? currentUnit;

            return AlertDialog(
              title: const Text('Añadir Ingrediente', style: TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedInsumoId,
                    decoration: const InputDecoration(labelText: 'Materia Prima', border: OutlineInputBorder()),
                    items: provider.inventarioDisponible.map((inv) {
                      return DropdownMenuItem<String>(
                        value: inv['id'].toString(),
                        child: Text(inv['name']),
                      );
                    }).toList(),
                    onChanged: (val) => setStateSub(() {
                      selectedInsumoId = val;
                      unidadElegida = null; // Resetea la unidad a la de por defecto al cambiar de materia prima
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cantidad a descontar', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // 👇 3. Cambiamos el Text por el DropdownButtonFormField 👇
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: unidadAUsar,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: dropDownItems.map((u) {
                            return DropdownMenuItem(
                              value: u,
                              child: Text(u, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setStateSub(() => unidadElegida = val);
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final double qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                    if (qty > 0) {
                      onAdd(RecipeSupply(
                        supplyId: selectedInsumoId,
                        supplyName: insumoMap['name'],
                        quantity: qty,
                        // 👇 4. Aquí guardamos la unidad que seleccionaste 👇
                        unit: unidadAUsar,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Añadir a receta'),
                )
              ],
            );
          }
        );
      }
    );

    qtyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final recetas = provider.filtradas;

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No se pudieron cargar las recetas: '
                              '${provider.errorMessage}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SectionHeader(
                    title: '📖 Fichas Técnicas (Recetas)',
                    subtitle: '${recetas.length} recetas enlazadas a inventario',
                    actionLabel: 'Crear Receta',
                    onAction: () => _mostrarDialogoFormulario(provider),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar receta...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: provider.setSearchTerm,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: recetas.length,
                      itemBuilder: (context, index) {
                        final r = recetas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Rinde: ${r.yieldPortions} porciones | Prep: ${r.prepMinutes} mins'),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Materia Prima a descontar:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (r.supplies.isEmpty)
                                      const Text('No tiene ingredientes configurados.', style: TextStyle(fontStyle: FontStyle.italic)),
                                    ...r.supplies.map((s) => Row(
                                      children: [
                                        const Icon(Icons.fiber_manual_record, size: 10),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${s.quantity} ${s.unit} de ${s.supplyName}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          label: const Text('Editar', style: TextStyle(color: Colors.blue)),
                                          onPressed: () => _mostrarDialogoFormulario(provider, receta: r),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          onPressed: () => _confirmarEliminarReceta(provider, r),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }

  void _confirmarEliminarReceta(RecipeProvider provider, Recipe receta) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar receta'),
          content: Text(
            '¿Seguro que deseas eliminar "${receta.name}"? '
            'También se eliminarán sus ingredientes configurados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);

                final exito = await provider.deleteRecipe(receta.id);

                if (!exito) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            'No se pudo eliminar la receta.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}