import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class ProductosPage extends StatelessWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      drawer: const AppSidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          children: List.generate(
              8,
              (i) => Card(
                    child: Center(child: Text('Producto ${i + 1}')),
                  )),
        ),
      ),
    );
  }
}
