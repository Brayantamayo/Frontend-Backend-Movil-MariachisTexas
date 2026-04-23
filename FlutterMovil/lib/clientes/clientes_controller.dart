import 'package:flutter/material.dart';
import 'package:mariachi_admin/clientes/cliente_service.dart';
import 'package:mariachi_admin/core/models/app_models.dart';

class ClientesController extends ChangeNotifier {
  List<Cliente> clientes = [];
  bool isLoading = false;
  String? error;

  Future<void> cargarClientes() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      clientes = await ClienteService.obtenerClientes();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }

    isLoading = false;
    notifyListeners();
  }
}