import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import '../models/restaurant_order.dart';

class PrinterService {
  // Asegúrate de cambiar esto a la IP Fija que configuraste en tu módem
  static const String printerIp = '192.168.100.28'; 
  static const int printerPort = 9100;

  static Future<bool> imprimirTicketCaja(RestaurantOrder orden) async {
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final PosPrintResult res = await printer.connect(printerIp, port: printerPort);

      if (res == PosPrintResult.success) {
        _armarDisenoTicket(printer, orden);
        printer.disconnect();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static void _armarDisenoTicket(NetworkPrinter printer, RestaurantOrder orden) {
    printer.reset();

    // Encabezado
    printer.text('ZAPATA RESTAURANTE',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ));
    printer.text('La Piedad, Michoacan', styles: const PosStyles(align: PosAlign.center));
    printer.hr();

    // Datos de Orden
    printer.text('Orden: ${orden.orderNumber}');
    printer.text('Fecha: ${DateTime.now().toString().substring(0, 16)}');
    printer.text('Tipo: ${orden.tableOrCustomer.replaceAll('Á', 'A').replaceAll('á', 'a')}', 
        styles: const PosStyles(bold: true));
    
    printer.hr();

    // Tabla de productos
    printer.row([
      PosColumn(text: 'Cant', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Descripcion', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Total', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    for (var item in orden.items) {
      // Limpieza de acentos para evitar bloqueo de la impresora
      String nombreLimpio = item.productName
          .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u')
          .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U');
          
      printer.row([
        PosColumn(text: '${item.quantity}', width: 2),
        PosColumn(text: nombreLimpio, width: 7),
        PosColumn(text: '\$${item.total.toStringAsFixed(2)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    printer.hr();

    // Totales
    printer.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true, width: PosTextSize.size2, height: PosTextSize.size2)),
      PosColumn(text: '\$${orden.totalAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(bold: true, align: PosAlign.right, width: PosTextSize.size2, height: PosTextSize.size2)),
    ]);

    printer.feed(3); // Espacio para el corte
    printer.cut();   // Corte automático
  }
}