import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class RecetasPage extends StatefulWidget {
  const RecetasPage({super.key});

  @override
  State<RecetasPage> createState() => _RecetasPageState();
}

class _RecetasPageState extends State<RecetasPage> {
  String search = '';
  int currentPage = 1;
  final pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final recetas = app.recetas.where((r) {
      if (search.isEmpty) return true;
      final q = search.toLowerCase();
      return [r['name'], r['category'], r['description']]
          .whereType<String>()
          .any((v) => v.toLowerCase().contains(q));
    }).toList();

    final totalPages = (recetas.length / pageSize).ceil().clamp(1, 999999);
    final start = (currentPage - 1) * pageSize;
    final paginated = recetas.skip(start).take(pageSize).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recetas')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Buscar receta...'),
              onChanged: (value) => setState(() {
                search = value;
                currentPage = 1;
              }),
            ),
            const SizedBox(height: 12),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('${recetas.length} receta(s)',
                    style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            Expanded(
              child: paginated.isEmpty
                  ? const Center(
                      child:
                          Text('No hay recetas que coincidan con tu búsqueda.'))
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final receta = paginated[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(receta['name'] ?? '',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                Text(
                                    '${receta['category']} · ${receta['yieldPortions']} porciones · ${receta['prepMinutes']} min',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 8),
                                Text(receta['description'] ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: currentPage > 1
                          ? () => setState(() => currentPage--)
                          : null,
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 12),
                    Text('Página $currentPage de $totalPages'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: currentPage < totalPages
                          ? () => setState(() => currentPage++)
                          : null,
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
