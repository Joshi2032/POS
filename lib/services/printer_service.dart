import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import '../models/restaurant_order.dart';

class PrinterService {
  
  static Future<bool> imprimirTicketCaja(RestaurantOrder orden) async {
    try {
      final profile = await CapabilityProfile.load();
      // El Generador convierte tus comandos de diseño a lenguaje de la impresora
      final generator = Generator(PaperSize.mm80, profile);
      
      // Armamos los bytes manteniendo tu diseño original
      List<int> bytes = _armarDisenoTicket(generator, orden);

      var printerManager = PrinterManager.instance;

      // Conectamos por USB. En Windows, si dejas VendorId y ProductId vacíos, 
      // suele apuntar a la primera impresora térmica USB disponible.
      await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: 'POS8810UE',
        )
      );

      // Enviamos el ticket a imprimir
      bool success = await printerManager.send(type: PrinterType.usb, bytes: bytes);
      
      // Nos desconectamos para no bloquear el puerto USB para futuras impresiones
      await printerManager.disconnect(type: PrinterType.usb);
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Se cambia NetworkPrinter por Generator, y devuelve un List<int>
  static List<int> _armarDisenoTicket(Generator generator, RestaurantOrder orden) {
    List<int> bytes = [];

    bytes += generator.reset();

    // Encabezado
    bytes += generator.text('ZAPATA RESTAURANTE',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ));
    bytes += generator.text('La Piedad, Michoacan', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Datos de Orden
    bytes += generator.text('Orden: ${orden.orderNumber}');
    bytes += generator.text('Fecha: ${DateTime.now().toString().substring(0, 16)}');
    bytes += generator.text('Tipo: ${orden.tableOrCustomer.replaceAll('Á', 'A').replaceAll('á', 'a')}', 
        styles: const PosStyles(bold: true));
    
    bytes += generator.hr();

    // Tabla de productos
    bytes += generator.row([
      PosColumn(text: 'Cant', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Descripcion', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Total', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    for (var item in orden.items) {
      // Limpieza de acentos para evitar bloqueo de la impresora
      String nombreLimpio = item.productName
          .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u')
          .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U');
          
      bytes += generator.row([
        PosColumn(text: '${item.quantity}', width: 2),
        PosColumn(text: nombreLimpio, width: 7),
        PosColumn(text: '\$${item.total.toStringAsFixed(2)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Totales
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true, width: PosTextSize.size2, height: PosTextSize.size2)),
      PosColumn(text: '\$${orden.totalAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(bold: true, align: PosAlign.right, width: PosTextSize.size2, height: PosTextSize.size2)),
    ]);

    bytes += generator.feed(3); // Espacio para el corte
    bytes += generator.cut();   // Corte automático
    
    return bytes;
  }
}