import 'package:flutter/material.dart';

class AjustesProvider extends ChangeNotifier {
  final nombreController = TextEditingController(text: 'La Brasa — Parrilla & Grill');
  final rfcController = TextEditingController(text: 'XAXX010101000');
  final direccionController = TextEditingController(text: 'Av. Reforma 123, CDMX');
  final telefonoController = TextEditingController(text: '+52 55 1234 5678');
  final pinController = TextEditingController(text: '1234');

  bool alertaStock = true;
  bool resumenDiario = true;
  bool nuevasOrdenes = true;
  bool cierreAutomatico = true;
  bool showPin = false;
  String saveStatus = 'idle'; // idle | saving | success

  void toggleAlertaStock(bool v) { alertaStock = v; notifyListeners(); }
  void toggleResumenDiario(bool v) { resumenDiario = v; notifyListeners(); }
  void toggleNuevasOrdenes(bool v) { nuevasOrdenes = v; notifyListeners(); }
  void toggleCierreAutomatico(bool v) { cierreAutomatico = v; notifyListeners(); }
  void toggleShowPin() { showPin = !showPin; notifyListeners(); }

  void guardarCambios() {
    saveStatus = 'saving';
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      saveStatus = 'success';
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () {
        saveStatus = 'idle';
        notifyListeners();
      });
    });
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