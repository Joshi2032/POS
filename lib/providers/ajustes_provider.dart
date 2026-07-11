import 'package:flutter/material.dart';
import '../models/restaurant_settings.dart';
import '../repositories/settings_repository.dart';

class AjustesProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  AjustesProvider(this._repository) {
    _cargar();
  }

  final nombreController = TextEditingController();
  final rfcController = TextEditingController();
  final direccionController = TextEditingController();
  final telefonoController = TextEditingController();
  final pinController = TextEditingController();

  bool alertaStock = true;
  bool resumenDiario = true;
  bool nuevasOrdenes = true;
  bool cierreAutomatico = true;
  bool showPin = false;
  bool isLoading = false;
  String? errorMessage;
  String saveStatus = 'idle'; // idle | saving | success | error

  Future<void> _cargar() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final settings = await _repository.obtener();
      nombreController.text = settings.nombreNegocio;
      rfcController.text = settings.rfc;
      direccionController.text = settings.direccion;
      telefonoController.text = settings.telefono;
      pinController.text = settings.pin;
      alertaStock = settings.alertaStock;
      resumenDiario = settings.resumenDiario;
      nuevasOrdenes = settings.nuevasOrdenes;
      cierreAutomatico = settings.cierreAutomatico;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Error cargando ajustes: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleAlertaStock(bool v) { alertaStock = v; notifyListeners(); }
  void toggleResumenDiario(bool v) { resumenDiario = v; notifyListeners(); }
  void toggleNuevasOrdenes(bool v) { nuevasOrdenes = v; notifyListeners(); }
  void toggleCierreAutomatico(bool v) { cierreAutomatico = v; notifyListeners(); }
  void toggleShowPin() { showPin = !showPin; notifyListeners(); }

  Future<void> guardarCambios() async {
    saveStatus = 'saving';
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.guardar(RestaurantSettings(
        nombreNegocio: nombreController.text.trim(),
        rfc: rfcController.text.trim(),
        direccion: direccionController.text.trim(),
        telefono: telefonoController.text.trim(),
        alertaStock: alertaStock,
        resumenDiario: resumenDiario,
        nuevasOrdenes: nuevasOrdenes,
        cierreAutomatico: cierreAutomatico,
        pin: pinController.text.trim(),
      ));

      saveStatus = 'success';
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));
      saveStatus = 'idle';
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Error guardando ajustes: $e');
      saveStatus = 'error';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    rfcController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    pinController.dispose();
    super.dispose();
  }
}
