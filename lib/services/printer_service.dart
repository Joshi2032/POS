import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import '../models/restaurant_order.dart';

class PrinterService {

  // ---------------------------------------------------------------------
  // DATOS FISCALES DEL NEGOCIO (editar aquí si cambian)
  // ---------------------------------------------------------------------
  static const String _nombreNegocio = 'ZAPATA COCINA DE BRASA';
  static const String _razonSocial = 'J. JESUS LEON PEREZ';
  static const String _rfc = 'RFC: LEPJ920408QA6';
  static const String _direccionFiscal =
      'RAMON LOPEZ NUM. 28 DEGOLLADO JALISCO\nDE GOLLADO JALISCO MEXICO CP 47980';
  static const String _sucursal =
      'SUCURSAL: CARRETERA FEDERAL 90 IRAPUATO-\nGUADALAJARA KM 84+880 PENJAMO GUANAJUATO\nPENJAMO GUANAJUATO CP 36910';

  static Future<bool> imprimirTicketCaja(RestaurantOrder orden) async {
    try {
      final profile = await CapabilityProfile.load();
      // Usamos el perfil 58mm. Asegúrate que la impresora esté configurada físicamente para esto.
      final generator = Generator(PaperSize.mm58, profile);

      List<int> bytes = _armarDisenoTicket(generator, orden);

      var printerManager = PrinterManager.instance;

      await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: 'POS-58',
        )
      );

      bool success = await printerManager.send(type: PrinterType.usb, bytes: bytes);

      await printerManager.disconnect(type: PrinterType.usb);

      return success;
    } catch (e) {
      debugPrint("Error de impresión: $e");
      return false;
    }
  }

  /// Ancho útil del papel de 58mm con fuente normal (Font A, sin negritas
  /// extra-anchas). Es el número real de caracteres por línea que la
  /// impresora puede colocar; las columnas de Generator.row() se calculan
  /// como fracciones de 12, pero NO garantizan caracteres exactos, por eso
  /// para texto libre armamos las líneas nosotros mismos con este ancho.
  static const int _anchoPapel = 32;

  /// Junta dos textos en una sola línea: [izquierda] pegado al borde
  /// izquierdo y [derecha] pegado al borde derecho, rellenando con
  /// espacios en medio. Si no caben los dos en una línea, [derecha] se
  /// manda a una segunda línea ya truncada/recortada para no romper el
  /// diseño con saltos de línea inesperados.
  static String _filaDosColumnas(String izquierda, String derecha) {
    final espacioDisponible = _anchoPapel - izquierda.length - derecha.length;
    if (espacioDisponible >= 1) {
      return izquierda + ' ' * espacioDisponible + derecha;
    }
    // No caben en una sola línea: ponemos derecha alineada a la derecha
    // en su propia línea, debajo de izquierda, para que nunca se vea
    // partida a la mitad de una palabra.
    final relleno = _anchoPapel - derecha.length;
    final espacios = relleno > 0 ? ' ' * relleno : '';
    return '$izquierda\n$espacios$derecha';
  }

  /// Trunca un texto a un ancho máximo, agregando "." si se recorta,
  /// para que nunca se desborde ni se parta a la mitad de una palabra
  /// en columnas estrechas como la de cantidad o descripción.
  static String _truncar(String texto, int maxAncho) {
    if (texto.length <= maxAncho) return texto;
    if (maxAncho <= 1) return texto.substring(0, maxAncho);
    return '${texto.substring(0, maxAncho - 1)}.';
  }

  /// Quita acentos y caracteres especiales para máxima compatibilidad
  /// con impresoras térmicas que no soportan UTF-8 correctamente.
  static String _limpiarTexto(String texto) {
    return texto
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u')
        .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I')
        .replaceAll('Ó', 'O').replaceAll('Ú', 'U')
        .replaceAll('ñ', 'n').replaceAll('Ñ', 'N');
  }

  /// Convierte un monto a texto en letras (pesos mexicanos), igual que la
  /// línea "SON: ___" de los comprobantes.
  static String _montoEnLetras(double monto) {
    final pesos = monto.floor();
    final centavos = ((monto - pesos) * 100).round();

    if (pesos == 0) {
      return 'CERO PESOS ${centavos.toString().padLeft(2, '0')}/100 M.N.';
    }

    final letras = _numeroALetras(pesos).toUpperCase();
    return '$letras PESOS ${centavos.toString().padLeft(2, '0')}/100 M.N.';
  }

  static String _numeroALetras(int n) {
    if (n == 0) return 'cero';

    const unidades = ['', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve'];
    const especiales = ['diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciseis', 'diecisiete', 'dieciocho', 'diecinueve'];
    const decenas = ['', '', 'veinte', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta', 'ochenta', 'noventa'];
    const centenas = ['', 'ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos', 'seiscientos', 'setecientos', 'ochocientos', 'novecientos'];

    String convertirGrupo(int num) {
      if (num == 0) return '';
      if (num == 100) return 'cien';
      if (num < 10) return unidades[num];
      if (num < 20) return especiales[num - 10];
      if (num < 30 && num > 20) return 'veinti${unidades[num - 20]}';
      if (num < 100) {
        final d = num ~/ 10;
        final u = num % 10;
        return u == 0 ? decenas[d] : '${decenas[d]} y ${unidades[u]}';
      }
      final c = num ~/ 100;
      final resto = num % 100;
      return resto == 0 ? centenas[c] : '${centenas[c]} ${convertirGrupo(resto)}';
    }

    if (n < 1000) return convertirGrupo(n);

    if (n < 1000000) {
      final miles = n ~/ 1000;
      final resto = n % 1000;
      final prefijoMiles = miles == 1 ? 'mil' : '${convertirGrupo(miles)} mil';
      return resto == 0 ? prefijoMiles : '$prefijoMiles ${convertirGrupo(resto)}';
    }

    // Suficiente para tickets de restaurante; no se esperan montos > 999,999
    return n.toString();
  }

  static List<int> _armarDisenoTicket(Generator generator, RestaurantOrder orden) {
    List<int> bytes = [];

    bytes += generator.reset();

    // 1. Encabezado fiscal (Centrado)
    bytes += generator.text(_nombreNegocio,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ));
    bytes += generator.text(_razonSocial, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(_rfc, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('');
    for (var linea in _direccionFiscal.split('\n')) {
      bytes += generator.text(_limpiarTexto(linea), styles: const PosStyles(align: PosAlign.center));
    }
    for (var linea in _sucursal.split('\n')) {
      bytes += generator.text(_limpiarTexto(linea), styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.hr();

    // 2. Datos de la orden (Mesa / Mesero, Folio, Personas / Orden)
    // TODO: reemplazar 'MESERO_FIJO' y 'PERSONAS_FIJO' cuando se agreguen
    // los campos correspondientes (mesero, numero de personas) a RestaurantOrder.
    const String _meseroFijo = '-'; // <-- placeholder temporal
    const String _personasFijo = '-'; // <-- placeholder temporal

    final mesaTexto = 'MESA: ${_limpiarTexto(orden.tableOrCustomer)}';
    final meseroTexto = 'MESERO: $_meseroFijo';
    bytes += generator.text(_filaDosColumnas(mesaTexto, meseroTexto));

    bytes += generator.text('FOLIO: ${orden.orderNumber}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(_formatearFecha(DateTime.now()), styles: const PosStyles(align: PosAlign.center));

    final personasTexto = 'PERSONAS: $_personasFijo';
    final ordenTexto = 'ORDEN: ${orden.orderNumber}';
    bytes += generator.text(_filaDosColumnas(personasTexto, ordenTexto));

    bytes += generator.hr();

    // 3. Tabla de Productos
    // El ancho del importe se calcula dinámicamente (mínimo 7 caracteres,
    // más si el monto tiene 4+ dígitos) y la descripción ocupa lo que
    // sobra, de forma que la suma siempre dé exactamente 32 caracteres
    // sin desbordar el papel, sin importar qué tan grande sea el total.
    const int _anchoCant = 4;

    String _filaProducto(String cant, String desc, String importe) {
      final anchoImporte = importe.length > 7 ? importe.length : 7;
      final anchoDesc = _anchoPapel - _anchoCant - 1 - anchoImporte - 1;
      final cantPad = cant.padRight(_anchoCant);
      final descPad = _truncar(desc, anchoDesc).padRight(anchoDesc);
      final importePad = importe.padLeft(anchoImporte);
      return '$cantPad $descPad $importePad';
    }

    bytes += generator.text(
      _filaProducto('CANT', 'DESCRIPCION', 'IMPORTE'),
      styles: const PosStyles(bold: true),
    );

    for (var item in orden.items) {
      String nombreLimpio = _limpiarTexto(item.productName).toUpperCase();
      final cantTexto = '${item.quantity}';
      final importeTexto = '\$${item.total.toStringAsFixed(2)}';
      final anchoImporte = importeTexto.length > 7 ? importeTexto.length : 7;
      final anchoDescDisponible = _anchoPapel - _anchoCant - 1 - anchoImporte - 1;

      if (nombreLimpio.length <= anchoDescDisponible) {
        // Cabe todo en una sola línea: cantidad, descripción e importe juntos.
        bytes += generator.text(_filaProducto(cantTexto, nombreLimpio, importeTexto));
      } else {
        // No cabe: la cantidad y el importe se quedan en la primera línea
        // junto con lo que sí cabe del nombre; el resto del nombre pasa
        // a una segunda línea alineada bajo la columna de descripción,
        // sin repetir texto.
        final primeraParte = nombreLimpio.substring(0, anchoDescDisponible);
        final segundaParte = nombreLimpio.substring(anchoDescDisponible).trim();
        bytes += generator.text(_filaProducto(cantTexto, primeraParte, importeTexto));
        bytes += generator.text(
          ''.padRight(_anchoCant + 1) + _truncar(segundaParte, anchoDescDisponible),
        );
      }
    }

    bytes += generator.emptyLines(1);

    // 4. Total
    bytes += generator.text(
      _filaDosColumnas('TOTAL:', '\$${orden.totalAmount.toStringAsFixed(2)}'),
      styles: const PosStyles(bold: true),
    );

    // 5. Total en letras ("SON: ...")
    bytes += generator.text(
      'SON: ${_montoEnLetras(orden.totalAmount)}',
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.emptyLines(1);

    // 6. Pie de comprobante
    bytes += generator.text('GRACIAS POR SU PREFERENCIA', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('ESTE NO ES UN COMPROBANTE FISCAL', styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.hr();

    // 7. Propina voluntaria (en filas, igual que el ticket físico)
    bytes += generator.text(
      'LA PROPINA NO INCLUIDA, DEPENDE DEL MESERO; USTED DECIDE',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.emptyLines(1);
    bytes += generator.text('PROPINA VOLUNTARIA', styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.text(
      _filaDosColumnas('10% BIEN:', '\$${(orden.totalAmount * 0.10).toStringAsFixed(2)}'),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      _filaDosColumnas('15% MUY BIEN:', '\$${(orden.totalAmount * 0.15).toStringAsFixed(2)}'),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      _filaDosColumnas('20% WOW!:', '\$${(orden.totalAmount * 0.20).toStringAsFixed(2)}'),
      styles: const PosStyles(bold: true),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  static String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    int hora12 = fecha.hour % 12;
    if (hora12 == 0) hora12 = 12;
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final segundo = fecha.second.toString().padLeft(2, '0');
    final ampm = fecha.hour >= 12 ? 'PM' : 'AM';

    return '$dia/$mes/$anio ${hora12.toString().padLeft(2, '0')}:$minuto:$segundo $ampm';
  }
}