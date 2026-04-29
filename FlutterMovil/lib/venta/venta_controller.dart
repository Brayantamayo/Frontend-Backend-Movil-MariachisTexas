import 'package:flutter/material.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'venta_service.dart';

enum VentaStatus { inicial, cargando, listo, error }

class VentaController extends ChangeNotifier {
  final _service = VentaService();

  VentaStatus status = VentaStatus.inicial;
  List<Venta> ventas = [];
  List<Venta> _ventasFiltradas = [];
  String errorMsg = '';

  List<Venta> get ventasMostradas =>
      _ventasFiltradas.isEmpty ? ventas : _ventasFiltradas;

  Future<void> cargar() async {
    status = VentaStatus.cargando;
    notifyListeners();

    try {
      ventas = await _service.obtenerVentas();
      _ventasFiltradas = [];
      status = VentaStatus.listo;
    } catch (e) {
      errorMsg = 'Error al cargar ventas: $e';
      status = VentaStatus.error;
    }
    notifyListeners();
  }

  void buscar(String query) {
    if (query.isEmpty) {
      _ventasFiltradas = [];
    } else {
      _ventasFiltradas = ventas
          .where((v) =>
              v.clienteNombre.toLowerCase().contains(query.toLowerCase()) ||
              v.clienteEmail.toLowerCase().contains(query.toLowerCase()) ||
              v.clienteTelefono.contains(query))
          .toList();
    }
    notifyListeners();
  }

  Future<Venta?> getDetalle(int id) async {
    // Primero buscar en la lista ya cargada (el listado ya trae todos los campos)
    final local = ventas.where((v) => v.id == id).firstOrNull;
    if (local != null) return local;

    // Si no está en memoria, llamar al service
    try {
      return await _service.obtenerVentaById(id);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
