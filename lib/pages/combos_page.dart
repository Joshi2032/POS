import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/combo_item.dart';
import '../providers/combos_provider.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';

class CombosPage extends StatelessWidget {
  const CombosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CombosView();
  }
}

class _CombosView extends StatefulWidget {
  const _CombosView();

  @override
  State<_CombosView> createState() => _CombosViewState();
}

class _CombosViewState extends State<_CombosView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  

  void _abrirFormularioModal(CombosProvider provider, {ComboItem? combo}) {
    if (combo != null) {
      _nombreCtrl.text = combo.title;
      _descripcionCtrl.text = combo.subtitle;
      _precioCtrl.text = combo.price.toString();
    } else {
      _nombreCtrl.clear();
      _descripcionCtrl.clear();
      _precioCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final modalTextColor = isDark ? Colors.white : Colors.black87;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(combo != null ? 'Editar Combo' : 'Nuevo Combo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: modalTextColor)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        style: TextStyle(color: modalTextColor),
                        decoration: const InputDecoration(
                            labelText: 'Nombre del Combo',
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 3,
                        style: TextStyle(color: modalTextColor),
                        decoration: const InputDecoration(
                            labelText: 'Descripción / Productos incluidos',
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _precioCtrl,
                        style: TextStyle(color: modalTextColor),
                        decoration: const InputDecoration(
                            labelText: 'Precio Especial',
                            prefixText: '\$',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
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
                      final nuevo = ComboItem(
                        id: combo?.id ??
                            'CMB-${DateTime.now().millisecondsSinceEpoch}',
                        title: _nombreCtrl.text,
                        subtitle: _descripcionCtrl.text,
                        tags: [],
                        price: double.tryParse(_precioCtrl.text) ?? 0,
                        oldPrice: double.tryParse(_precioCtrl.text) ?? 0,
                        ahorro: '',
                      );

                      if (combo != null) {
                        provider.actualizarCombo(combo.id, nuevo);
                      } else {
                        provider.agregarCombo(nuevo);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child:
                      Text(combo != null ? 'Guardar Cambios' : 'Crear Combo'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _solicitarBorrado(CombosProvider provider, ComboItem combo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar combo'),
        content: Text('Se eliminará "${combo.title}". ¿Estás seguro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              provider.eliminarCombo(combo.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CombosProvider>();
    final filtrados = provider.combosFiltrados;

    // DETECTAMOS SI EL MODO OSCURO ESTÁ ACTIVO
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // DECLARACIÓN DE VARIABLES PARA COLORES ADAPTATIVOS
    final searchFillColor = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white60 : Colors.grey[700];
    final hintColor = isDark ? Colors.white38 : Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '🍱 Combos y Paquetes',
              subtitle: '${filtrados.length} combos registrados',
              actionLabel: 'Crear Combo',
              onAction: () => _abrirFormularioModal(provider),
            ),
            const SizedBox(height: 24),
            TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: hintColor),
                hintText: 'Buscar combo por nombre o contenido...',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: searchFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: provider.setSearchTerm,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyState(
                      message: 'No hay combos que coincidan con tu búsqueda.',
                      icon: Icons.local_mall_outlined,
                      actionLabel: 'Limpiar Búsqueda',
                      onAction: () => provider.setSearchTerm(''),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (context, idx) {
                        final combo = filtrados[idx];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      combo.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  combo.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: textSubColor,
                                        height: 1.4,
                                      ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('\$${combo.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: isDark
                                            ? const Color(0xFF82B1FF)
                                            : Colors.blueAccent,
                                        fontWeight: FontWeight.w900,
                                      )),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.blueGrey),
                                        onPressed: () => _abrirFormularioModal(
                                            provider,
                                            combo: combo),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20, color: Colors.redAccent),
                                        onPressed: () =>
                                            _solicitarBorrado(provider, combo),
                                      ),
                                    ],
                                  )
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
