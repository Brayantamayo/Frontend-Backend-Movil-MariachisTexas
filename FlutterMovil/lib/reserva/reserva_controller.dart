import 'package:flutter/foundation.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'reserva_service.dart';

enum ReservaStatus { inicial, cargando, listo, error }

class ReservaController extends ChangeNotifier {
  final ReservaService _service = ReservaService();

  ReservaStatus status = ReservaStatus.inicial;
  String errorMsg = '';

  List<Reserva> _todas = [];
  List<Reserva> get reservas => _todas;

  String _query = '';
  String get query => _query;

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> cargar() async {
    print('🔍 ReservaController: Iniciando carga de reservas');

    status = ReservaStatus.cargando;
    errorMsg = '';
    notifyListeners();

    try {
      print('🔍 ReservaController: Llamando al servicio...');
      _todas = await _service.getReservas();
      print(
          '✅ ReservaController: Reservas cargadas exitosamente: ${_todas.length}');
      status = ReservaStatus.listo;
    } catch (e) {
      print('❌ ReservaController: Error al cargar reservas: $e');
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = ReservaStatus.error;
    }

    notifyListeners();
    print('🔍 ReservaController: Estado final: $status');
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────────

  Future<void> buscar(String q) async {
    _query = q;
    notifyListeners();

    if (q.trim().isEmpty) {
      await cargar();
      return;
    }

    status = ReservaStatus.cargando;
    notifyListeners();

    try {
      _todas = await _service.buscarReservas(q);
      status = ReservaStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = ReservaStatus.error;
    }

    notifyListeners();
  }

  // ── Obtener detalle ────────────────────────────────────────────────────────

  Future<Reserva?> getDetalle(int id) async {
    print('🔍 ReservaController: Obteniendo detalle de reserva $id');

    try {
      final reserva = await _service.getReservaById(id);
      print(
          '✅ ReservaController: Detalle obtenido exitosamente - Estado: ${reserva.estado}');
      return reserva;
    } catch (e) {
      print('❌ ReservaController: Error al obtener detalle: $e');
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Limpiar error ──────────────────────────────────────────────────────────

  void limpiarError() {
    errorMsg = '';
    notifyListeners();
  }
}
