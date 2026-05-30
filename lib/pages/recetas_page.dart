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
  void _mostrarDialogoFormulario(RecipeProvider provider, {Recipe? receta}) {
    // FIX: Quitamos el guion bajo para evitar el lint
    final formKey = GlobalKey<FormState>(); 
    final nombreCtrl = TextEditingController(text: receta?.name ?? '');
    final rindeCtrl = TextEditingController(text: receta?.yieldPortions.toString() ?? '1');
    final tiempoCtrl = TextEditingController(text: receta?.prepMinutes.toString() ?? '0');
    final descCtrl = TextEditingController(text: receta?.description ?? '');

    // Lista temporal de insumos para este formulario
    List<RecipeSupply> insumosTemporales = receta != null ? List.from(receta.supplies) : [];

    showDialog(
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final nuevaReceta = Recipe(
                        id: receta?.id ?? '',
                        name: nombreCtrl.text,
                        yieldPortions: double.tryParse(rindeCtrl.text) ?? 1.0,
                        prepMinutes: int.tryParse(tiempoCtrl.text) ?? 0,
                        description: descCtrl.text,
                        supplies: insumosTemporales, 
                      );

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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage ?? 'Error'), backgroundColor: Colors.red)
                          );
                        }
                      }
                    }
                  },
                  child: Text(receta != null ? 'Guardar Cambios' : 'Crear Receta'),
                )
              ],
            );
          }
        );
      },
    );
  }

  void _mostrarSelectorDeInsumo(BuildContext parentContext, RecipeProvider provider, Function(RecipeSupply) onAdd) {
    if (provider.inventarioDisponible.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('No hay materia prima registrada.'), backgroundColor: Colors.orange)
      );
      return;
    }

    String? selectedInsumoId = provider.inventarioDisponible.first['id'].toString();
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSub) {
            final insumoMap = provider.inventarioDisponible.firstWhere((i) => i['id'].toString() == selectedInsumoId);
            final currentUnit = insumoMap['unit'] ?? 'ud';

            return AlertDialog(
              title: const Text('Añadir Ingrediente', style: TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FIX: Se usa initialValue en lugar de value por actualización de Flutter
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
                    onChanged: (val) => setStateSub(() => selectedInsumoId = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cantidad a descontar', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(currentUnit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        unit: currentUnit,
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
                                        Text('${s.quantity} ${s.unit} de ${s.supplyName}'),
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
                                          onPressed: () => provider.deleteRecipe(r.id),
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
}