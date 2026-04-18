import 'package:flutter/foundation.dart';
import 'cotizacion.model.dart';
import 'cotizacion_service.dart';

enum CotizacionStatus { inicial, cargando, listo, error }

class CotizacionController extends ChangeNotifier {
  final CotizacionService _service = CotizacionService();

  CotizacionStatus status = CotizacionStatus.inicial;
  String errorMsg = '';

  List<Cotizacion> _todas = [];
  List<Cotizacion> get cotizaciones => _todas;

  String _query = '';
  String get query => _query;

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> cargar() async {
    print('🔍 CotizacionController: Iniciando carga de cotizaciones');

    status = CotizacionStatus.cargando;
    errorMsg = '';
    notifyListeners();

    try {
      print('🔍 CotizacionController: Llamando al servicio...');
      _todas = await _service.getCotizaciones();
      print(
          '✅ CotizacionController: Cotizaciones cargadas exitosamente: ${_todas.length}');
      status = CotizacionStatus.listo;
    } catch (e) {
      print('❌ CotizacionController: Error al cargar cotizaciones: $e');
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = CotizacionStatus.error;
    }

    notifyListeners();
    print('🔍 CotizacionController: Estado final: $status');
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────────

  Future<void> buscar(String q) async {
    _query = q;
    notifyListeners();

    if (q.trim().isEmpty) {
      await cargar();
      return;
    }

    status = CotizacionStatus.cargando;
    notifyListeners();

    try {
      _todas = await _service.buscarCotizaciones(q);
      status = CotizacionStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = CotizacionStatus.error;
    }

    notifyListeners();
  }

  // ── Obtener detalle ────────────────────────────────────────────────────────

  Future<Cotizacion?> getDetalle(int id) async {
    print('🔍 CotizacionController: Obteniendo detalle de cotización $id');

    try {
      final cotizacion = await _service.getCotizacionById(id);
      print(
          '✅ CotizacionController: Detalle obtenido exitosamente - Estado: ${cotizacion.estado}');
      return cotizacion;
    } catch (e) {
      print('❌ CotizacionController: Error al obtener detalle: $e');
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Convertir a reserva ────────────────────────────────────────────────────

  Future<bool> convertirAReserva(int id) async {
    try {
      await _service.convertirAReserva(id);

      // Actualizar estado local
      final idx = _todas.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _todas[idx].estado = EstadoCotizacion.convertida;
        notifyListeners();
      }

      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Anular cotización ──────────────────────────────────────────────────────

  Future<bool> anular(int id) async {
    print('🔍 CotizacionController: Iniciando anulación de cotización $id');

    try {
      await _service.anularCotizacion(id);
      print('✅ CotizacionController: Servicio completado');

      // Actualizar estado local
      final idx = _todas.indexWhere((c) => c.id == id);
      print('🔍 CotizacionController: Índice encontrado: $idx');

      if (idx != -1) {
        print(
            '🔍 CotizacionController: Estado anterior: ${_todas[idx].estado}');
        _todas[idx].estado = EstadoCotizacion.anulada;
        print(
            '🔍 CotizacionController: Estado actualizado: ${_todas[idx].estado}');
        notifyListeners();
      }

      print('✅ CotizacionController: Anulación completada exitosamente');
      return true;
    } catch (e) {
      print('❌ CotizacionController: Error al anular: $e');
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Eliminar cotización ────────────────────────────────────────────────────

  Future<bool> eliminar(int id) async {
    try {
      await _service.eliminarCotizacion(id);

      // Remover de la lista local
      _todas.removeWhere((c) => c.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Generar PDF ────────────────────────────────────────────────────────────

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

  // ── Limpiar error ──────────────────────────────────────────────────────────

  void limpiarError() {
    errorMsg = '';
    notifyListeners();
  }
}
