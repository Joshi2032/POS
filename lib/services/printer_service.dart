import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

import '../models/restaurant_order.dart';

class PrinterService {
  // ---------------------------------------------------------------------
  // DATOS FISCALES DEL NEGOCIO
  // ---------------------------------------------------------------------
  static const String _nombreNegocio = 'ZAPATA COCINA DE BRASA';
  static const String _razonSocial = 'J. JESUS LEON PEREZ';
  static const String _rfc = 'RFC: LEPJ920408QA6';

  static const String _direccionFiscal =
      'RAMON LOPEZ NUM. 28 DEGOLLADO JALISCO\n'
      'DEGOLLADO JALISCO MEXICO CP 47980';

  static const String _sucursal =
      'SUCURSAL: CARRETERA FEDERAL 90 IRAPUATO-\n'
      'GUADALAJARA KM 84+880 PENJAMO GUANAJUATO\n'
      'PENJAMO GUANAJUATO CP 36910';

  // Papel 58mm normalmente soporta 32 caracteres por línea.
  static const int _anchoPapel = 32;

  // Cambia esto a false si tu impresora NO tiene cortador automático.
  static const bool _usarCorteAutomatico = true;

  // Tiempos máximos de espera para no dejar la app colgada si la impresora
  // está apagada o desconectada.
  static const Duration _timeoutConexion = Duration(seconds: 8);
  static const Duration _timeoutEnvio = Duration(seconds: 15);
  static const Duration _timeoutDesconexion = Duration(seconds: 5);

  // El perfil de capacidades no cambia entre impresiones: se carga una sola
  // vez y se reutiliza en cada ticket.
  static CapabilityProfile? _cachedProfile;

  static Future<CapabilityProfile> _obtenerProfile() async {
    return _cachedProfile ??= await CapabilityProfile.load();
  }

  // ---------------------------------------------------------------------
  // TICKET COMPLETO PARA CAJA
  // ---------------------------------------------------------------------
  static Future<bool> imprimirTicketCaja(RestaurantOrder orden) async {
    final printerManager = PrinterManager.instance;
    bool conectado = false;

    try {
      final profile = await _obtenerProfile();
      final generator = Generator(PaperSize.mm58, profile);

      final List<int> bytes = _armarDisenoTicket(generator, orden);

      if (bytes.isEmpty) {
        debugPrint('PRINTER_SERVICE: No se generaron bytes para imprimir.');
        return false;
      }

      // Se marca ANTES de esperar la respuesta: si connect() excede el
      // timeout pero la conexión nativa se establece un instante después,
      // igual queremos intentar desconectar en el finally para no dejar el
      // puerto USB reclamado.
      conectado = true;

      await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: 'POS-58',
        ),
      ).timeout(_timeoutConexion);

      // Nota: si send() excede _timeoutEnvio, se reporta como fallo aunque
      // los bytes ya se hayan transmitido físicamente (el plugin no expone
      // forma de confirmar el estado real de la impresora tras un timeout).
      // Se prefiere el falso negativo (avisar "revisa la impresora") sobre
      // dejar la app colgada indefinidamente.
      final bool success = await printerManager.send(
        type: PrinterType.usb,
        bytes: bytes,
      ).timeout(_timeoutEnvio);

      debugPrint('PRINTER_SERVICE: imprimirTicketCaja success=$success');
      return success;
    } catch (e) {
      debugPrint('PRINTER_SERVICE: Error de impresión: $e');
      return false;
    } finally {
      if (conectado) {
        try {
          await printerManager
              .disconnect(type: PrinterType.usb)
              .timeout(_timeoutDesconexion);
        } catch (e) {
          debugPrint('PRINTER_SERVICE: Error al desconectar impresora: $e');
        }
      }
    }
  }

  static List<int> _armarDisenoTicket(
    Generator generator,
    RestaurantOrder orden,
  ) {
    final List<int> bytes = [];

    final double totalReal = orden.calculatedTotal > 0
        ? orden.calculatedTotal
        : orden.totalAmount;

    bytes.addAll(generator.reset());

    // -------------------------------------------------------------------
    // 1. Encabezado fiscal
    // -------------------------------------------------------------------
    bytes.addAll(
      generator.text(
        _limpiarTexto(_nombreNegocio),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );

    bytes.addAll(
      generator.text(
        _limpiarTexto(_razonSocial),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(
      generator.text(
        _limpiarTexto(_rfc),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.text(''));

    for (final linea in _direccionFiscal.split('\n')) {
      bytes.addAll(
        generator.text(
          _limpiarTexto(linea),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }

    for (final linea in _sucursal.split('\n')) {
      bytes.addAll(
        generator.text(
          _limpiarTexto(linea),
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }

    bytes.addAll(generator.hr());

    // -------------------------------------------------------------------
    // 2. Datos de la orden
    // -------------------------------------------------------------------
    final String mesa = orden.tableOrCustomer.trim().isNotEmpty
        ? orden.tableOrCustomer
        : '-';

    final String mesero = (orden.waiterName ?? '').trim().isNotEmpty
        ? orden.waiterName!
        : '-';

    final String folio = orden.orderNumber.trim().isNotEmpty
        ? orden.orderNumber
        : orden.id;

    bytes.addAll(
      generator.text(
        _filaDosColumnas(
          'MESA: ${_limpiarTexto(mesa)}',
          'MESERO: ${_limpiarTexto(mesero)}',
        ),
      ),
    );

    bytes.addAll(
      generator.text(
        'FOLIO: ${_limpiarTexto(folio)}',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(
      generator.text(
        _formatearFecha(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    // Quitamos PERSONAS para que no choque con tu lógica actual.
    // Solo dejamos ORDEN centrada.
    bytes.addAll(
      generator.text(
        'ORDEN: ${_limpiarTexto(folio)}',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.hr());

    // -------------------------------------------------------------------
    // 3. Tabla de productos
    // -------------------------------------------------------------------
    const int anchoCant = 4;

    String filaProducto(String cant, String desc, String importe) {
      final int anchoImporte = importe.length > 7 ? importe.length : 7;
      final int anchoDesc = _anchoPapel - anchoCant - 1 - anchoImporte - 1;

      final String cantPad = _truncar(cant, anchoCant).padRight(anchoCant);
      final String descPad = _truncar(desc, anchoDesc).padRight(anchoDesc);
      final String importePad = _truncar(importe, anchoImporte).padLeft(anchoImporte);

      return '$cantPad $descPad $importePad';
    }

    bytes.addAll(
      generator.text(
        filaProducto('CANT', 'DESCRIPCION', 'IMPORTE'),
        styles: const PosStyles(bold: true),
      ),
    );

    if (orden.items.isEmpty) {
      bytes.addAll(
        generator.text(
          filaProducto('0', 'SIN PRODUCTOS', '\$0.00'),
        ),
      );
    } else {
      for (final item in orden.items) {
        final String nombreLimpio =
            _limpiarTexto(item.productName).toUpperCase();

        final String cantTexto = item.quantity.toString();
        final String importeTexto = '\$${item.total.toStringAsFixed(2)}';

        final int anchoImporte =
            importeTexto.length > 7 ? importeTexto.length : 7;

        final int anchoDescDisponible = (_anchoPapel - anchoCant - 1 - anchoImporte - 1)
            .clamp(1, _anchoPapel);

        if (nombreLimpio.length <= anchoDescDisponible) {
          bytes.addAll(
            generator.text(
              filaProducto(cantTexto, nombreLimpio, importeTexto),
            ),
          );
        } else {
          final String primeraParte =
              nombreLimpio.substring(0, anchoDescDisponible);

          bytes.addAll(
            generator.text(
              filaProducto(cantTexto, primeraParte, importeTexto),
            ),
          );

          // Líneas de continuación: se imprime el NOMBRE COMPLETO restante,
          // envolviendo en tantas líneas como haga falta, en vez de
          // truncarlo con "..." y perder el resto del texto (importante
          // para combos con nombres descriptivos largos).
          final String indentacion = ''.padRight(anchoCant + 1);
          String resto = nombreLimpio.substring(anchoDescDisponible).trim();

          while (resto.isNotEmpty) {
            final int tomar = resto.length > anchoDescDisponible
                ? anchoDescDisponible
                : resto.length;

            bytes.addAll(
              generator.text('$indentacion${resto.substring(0, tomar)}'),
            );

            resto = resto.substring(tomar).trim();
          }
        }
      }
    }

    bytes.addAll(generator.emptyLines(1));

    // -------------------------------------------------------------------
    // 4. Total
    // -------------------------------------------------------------------
    bytes.addAll(
      generator.text(
        _filaDosColumnas('TOTAL:', '\$${totalReal.toStringAsFixed(2)}'),
        styles: const PosStyles(bold: true),
      ),
    );

    bytes.addAll(
      generator.text(
        'SON: ${_montoEnLetras(totalReal)}',
        styles: const PosStyles(align: PosAlign.left),
      ),
    );

    bytes.addAll(generator.emptyLines(1));

    // -------------------------------------------------------------------
    // 5. Pie
    // -------------------------------------------------------------------
    bytes.addAll(
      generator.text(
        'GRACIAS POR SU PREFERENCIA',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(
      generator.text(
        'ESTE NO ES UN COMPROBANTE FISCAL',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );

    bytes.addAll(generator.hr());

    // -------------------------------------------------------------------
    // 6. Propina voluntaria
    // -------------------------------------------------------------------
    bytes.addAll(
      generator.text(
        'LA PROPINA NO INCLUIDA, DEPENDE DEL MESERO; USTED DECIDE',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.emptyLines(1));

    bytes.addAll(
      generator.text(
        'PROPINA VOLUNTARIA',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );

    bytes.addAll(
      generator.text(
        _filaDosColumnas(
          '10% BIEN:',
          '\$${(totalReal * 0.10).toStringAsFixed(2)}',
        ),
        styles: const PosStyles(bold: true),
      ),
    );

    bytes.addAll(
      generator.text(
        _filaDosColumnas(
          '15% MUY BIEN:',
          '\$${(totalReal * 0.15).toStringAsFixed(2)}',
        ),
        styles: const PosStyles(bold: true),
      ),
    );

    bytes.addAll(
      generator.text(
        _filaDosColumnas(
          '20% WOW!:',
          '\$${(totalReal * 0.20).toStringAsFixed(2)}',
        ),
        styles: const PosStyles(bold: true),
      ),
    );

    bytes.addAll(generator.feed(3));

    if (_usarCorteAutomatico) {
      bytes.addAll(generator.cut());
    }

    return bytes;
  }

  // ---------------------------------------------------------------------
  // HELPERS DE TEXTO
  // ---------------------------------------------------------------------
  static String _filaDosColumnas(String izquierda, String derecha) {
    // Truncamos cada lado individualmente al ancho del papel: si no, cuando
    // uno de los dos (típicamente el nombre del mesero) es más largo que
    // _anchoPapel por sí solo, la línea de abajo se pasaría del ancho físico
    // del papel y la impresora la cortaría/enrollaría de forma incorrecta.
    final String izq = _truncar(_limpiarTexto(izquierda), _anchoPapel);
    final String der = _truncar(_limpiarTexto(derecha), _anchoPapel);

    final int espacioDisponible = _anchoPapel - izq.length - der.length;

    if (espacioDisponible >= 1) {
      return izq + (' ' * espacioDisponible) + der;
    }

    final int relleno = _anchoPapel - der.length;
    final String espacios = relleno > 0 ? ' ' * relleno : '';

    return '$izq\n$espacios$der';
  }

  static String _truncar(String texto, int maxAncho) {
    if (maxAncho <= 0) return '';
    if (texto.length <= maxAncho) return texto;
    if (maxAncho == 1) return '.';

    return '${texto.substring(0, maxAncho - 1)}.';
  }

  static String _limpiarTexto(String texto) {
    return texto
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('¿', '')
        .replaceAll('¡', '')
        .replaceAll('°', '')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
  }

  // ---------------------------------------------------------------------
  // MONTO EN LETRAS
  // ---------------------------------------------------------------------
  static String _montoEnLetras(double monto) {
    final double montoSeguro = monto.isNaN || monto.isInfinite || monto < 0
        ? 0.0
        : monto;

    final int pesos = montoSeguro.floor();
    final int centavos = ((montoSeguro - pesos) * 100).round();

    if (pesos == 0) {
      return 'CERO PESOS ${centavos.toString().padLeft(2, '0')}/100 M.N.';
    }

    final String letras = _numeroALetras(pesos).toUpperCase();

    return '$letras PESOS ${centavos.toString().padLeft(2, '0')}/100 M.N.';
  }

  static String _numeroALetras(int n) {
    if (n == 0) return 'cero';

    const List<String> unidades = [
      '',
      'uno',
      'dos',
      'tres',
      'cuatro',
      'cinco',
      'seis',
      'siete',
      'ocho',
      'nueve',
    ];

    const List<String> especiales = [
      'diez',
      'once',
      'doce',
      'trece',
      'catorce',
      'quince',
      'dieciseis',
      'diecisiete',
      'dieciocho',
      'diecinueve',
    ];

    const List<String> decenas = [
      '',
      '',
      'veinte',
      'treinta',
      'cuarenta',
      'cincuenta',
      'sesenta',
      'setenta',
      'ochenta',
      'noventa',
    ];

    const List<String> centenas = [
      '',
      'ciento',
      'doscientos',
      'trescientos',
      'cuatrocientos',
      'quinientos',
      'seiscientos',
      'setecientos',
      'ochocientos',
      'novecientos',
    ];

    String convertirGrupo(int num) {
      if (num == 0) return '';
      if (num == 100) return 'cien';

      if (num < 10) {
        return unidades[num];
      }

      if (num < 20) {
        return especiales[num - 10];
      }

      if (num == 20) {
        return 'veinte';
      }

      if (num < 30) {
        return 'veinti${unidades[num - 20]}';
      }

      if (num < 100) {
        final int d = num ~/ 10;
        final int u = num % 10;

        return u == 0 ? decenas[d] : '${decenas[d]} y ${unidades[u]}';
      }

      final int c = num ~/ 100;
      final int resto = num % 100;

      return resto == 0
          ? centenas[c]
          : '${centenas[c]} ${convertirGrupo(resto)}';
    }

    if (n < 1000) {
      return convertirGrupo(n);
    }

    if (n < 1000000) {
      final int miles = n ~/ 1000;
      final int resto = n % 1000;

      final String prefijoMiles = miles == 1
          ? 'mil'
          : '${convertirGrupo(miles)} mil';

      return resto == 0
          ? prefijoMiles
          : '$prefijoMiles ${convertirGrupo(resto)}';
    }

    return n.toString();
  }

  // ---------------------------------------------------------------------
  // FECHA
  // ---------------------------------------------------------------------
  static String _formatearFecha(DateTime fecha) {
    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');
    final String anio = fecha.year.toString();

    int hora12 = fecha.hour % 12;
    if (hora12 == 0) hora12 = 12;

    final String minuto = fecha.minute.toString().padLeft(2, '0');
    final String segundo = fecha.second.toString().padLeft(2, '0');
    final String ampm = fecha.hour >= 12 ? 'PM' : 'AM';

    return '$dia/$mes/$anio '
        '${hora12.toString().padLeft(2, '0')}:$minuto:$segundo $ampm';
  }
}