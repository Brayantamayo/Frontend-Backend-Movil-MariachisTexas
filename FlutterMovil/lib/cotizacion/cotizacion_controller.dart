import 'package:flutter/foundation.dart';
import 'cotizacion.model.dart';
import 'cotizacion_service.dart';

enum CotizacionStatus { inicial, cargando, listo, error }

class CotizacionController extends ChangeNotifier {
  final CotizacionService _service = CotizacionService();

  CotizacionStatus status = CotizacionStatus.inicial;
  String errorMsg = '';

  List<Cotizacion> _todas = [];
  List<Cotizacion> _todasOriginales = [];
  List<Cotizacion> get cotizaciones => _todas;

  String _query = '';
  String get query => _query;

  Future<void> cargar() async {
    status = CotizacionStatus.cargando;
    errorMsg = '';
    notifyListeners();
    try {
      _todas = await _service.getCotizaciones();
      _todasOriginales = List.from(_todas);
      status = CotizacionStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = CotizacionStatus.error;
    }
    notifyListeners();
  }

/// Buscar cotizaciones
  void buscar(String q) {
    _query = q;
    if (q.trim().isEmpty) {
      _todas = List.from(_todasOriginales);
    } else {
      final lower = q.toLowerCase();
      _todas = _todasOriginales.where((c) =>
        c.clienteNombre.toLowerCase().contains(lower) ||
        c.nombreHomenajeado.toLowerCase().contains(lower) ||
        c.tipoEventoLabel.toLowerCase().contains(lower) ||
        c.estadoLabel.toLowerCase().contains(lower),
      ).toList();
    }
    notifyListeners();
  }

/// Obtener detalle de una cotización
  Future<Cotizacion?> getDetalle(int id) async {
    try {
      return await _service.getCotizacionById(id);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
/// Convertir a reserva
  Future<bool> convertirAReserva(int id) async {
    try {
      await _service.convertirAReserva(id);
      _actualizarEstado(id, EstadoCotizacion.convertida);
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

/// Anular cotización
  Future<bool> anular(int id) async {
    try {
      await _service.anularCotizacion(id);
      _actualizarEstado(id, EstadoCotizacion.anulada);
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

/// Eliminar cotización
  Future<bool> eliminar(int id) async {
    try {
      await _service.eliminarCotizacion(id);
      _todas.removeWhere((c) => c.id == id);
      _todasOriginales.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

/// Descargar PDF de la cotización
  Future<bool> descargarPDF(int id) async {
    try {
      await _service.descargarPDF(id);
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  void limpiarError() {
    errorMsg = '';
    notifyListeners();
  }

  // ── Helper interno ────────────────────────────────────────────────────────
  void _actualizarEstado(int id, EstadoCotizacion nuevoEstado) {
    final idx = _todas.indexWhere((c) => c.id == id);
    if (idx != -1) _todas[idx] = _todas[idx].copyWith(estado: nuevoEstado);
    final idx2 = _todasOriginales.indexWhere((c) => c.id == id);
    if (idx2 != -1) _todasOriginales[idx2] = _todasOriginales[idx2].copyWith(estado: nuevoEstado);
    notifyListeners();
  }
}