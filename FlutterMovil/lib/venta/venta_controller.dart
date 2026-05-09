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
  String _query = '';
  EstadoVenta? _estadoFiltro;
  EstadoVenta? get estadoFiltro => _estadoFiltro;

  List<Venta> get ventasMostradas =>
      _ventasFiltradas.isEmpty && _estadoFiltro == null && _query.isEmpty
          ? ventas
          : _ventasFiltradas;

  Future<void> cargar() async {
    status = VentaStatus.cargando;
    notifyListeners();

    try {
      // Cargar ventas del endpoint + reservas anuladas con abonos
      final results = await Future.wait([
        _service.obtenerVentas(),
        _service.obtenerReservasAnuladasConAbonos(),
      ]);
      final ventasNormales = results[0];
      final ventasDeAnuladas = results[1];

      // Combinar evitando duplicados por id
      final ids = ventasNormales.map((v) => v.id).toSet();
      final extras =
          ventasDeAnuladas.where((v) => !ids.contains(v.id)).toList();
      ventas = [...ventasNormales, ...extras];
      _ventasFiltradas = [];
      status = VentaStatus.listo;
    } catch (e) {
      errorMsg = 'Error al cargar ventas: $e';
      status = VentaStatus.error;
    }
    notifyListeners();
  }

  void buscar(String query) {
    _query = query;
    _aplicarFiltros();
  }

  void filtrarPorEstado(EstadoVenta? estado) {
    _estadoFiltro = estado;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    var lista = List<Venta>.from(ventas);
    if (_estadoFiltro != null) {
      lista = lista.where((v) => v.estadoEnum == _estadoFiltro).toList();
    }
    if (_query.isNotEmpty) {
      lista = lista
          .where((v) =>
              v.clienteNombre.toLowerCase().contains(_query.toLowerCase()) ||
              v.clienteEmail.toLowerCase().contains(_query.toLowerCase()) ||
              v.clienteTelefono.contains(_query))
          .toList();
    }
    _ventasFiltradas = lista;
    notifyListeners();
  }

  Future<bool> registrarAbono(
    int reservaId, {
    required double monto,
    required String metodoPago,
    String? notas,
  }) async {
    try {
      await _service.registrarAbono(reservaId,
          monto: monto, metodoPago: metodoPago, notas: notas);
      await cargar();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> anularVenta(int reservaId) async {
    try {
      await _service.anularReserva(reservaId);
      await cargar();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
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
