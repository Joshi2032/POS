import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  bool isLoading = false;
  String? error;

  Future<bool> login(
    String email,
    String password,
  ) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.login(email, password);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}