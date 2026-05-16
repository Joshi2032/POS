import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class OrdenesPage extends StatelessWidget {
  const OrdenesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes')),
      drawer: const AppSidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (context, i) => Card(
            child: ListTile(
              title: Text('ORD-10${i + 1}'),
              subtitle: const Text('Mesa A1 · 2 items'),
              trailing: Text('\$${(100 + i * 50)}'),
            ),
          ),
        ),
      ),
    );
  }
}
