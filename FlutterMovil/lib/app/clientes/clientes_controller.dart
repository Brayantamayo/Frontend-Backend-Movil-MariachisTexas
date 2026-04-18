import 'package:flutter/material.dart';
import 'package:mariachi_admin/app/clientes/cliente_service.dart';
import 'package:mariachi_admin/app/clientes/cliente_model.dart';

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
      error = 'Error al cargar clientes';
      debugPrint(e.toString());
    }

    isLoading = false;
    notifyListeners();
  }
}