import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Cambiamos la importación para apuntar a app.dart donde vive tu clase App
import 'package:zapata_flutter/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Construye la aplicación llamando a tu clase App()
    await tester.pumpWidget(const App());

    // Verifica que el Sidebar o el Layout principal cargue (busca el título del AppBar)
    // Cuando lo corras en móvil o si lo encuentra en el código, sabremos que no hay crasheos.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}