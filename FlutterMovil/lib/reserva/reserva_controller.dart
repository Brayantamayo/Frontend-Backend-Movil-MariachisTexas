import 'package:flutter/foundation.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'reserva_service.dart';

enum ReservaStatus { inicial, cargando, listo, error }

class ReservaController extends ChangeNotifier {
  final ReservaService _service = ReservaService();

  ReservaStatus status = ReservaStatus.inicial;
  String errorMsg = '';

  List<Reserva> _todas = [];
  List<Reserva> _todasOriginales = [];
  List<Reserva> get reservas => _todas;

  String _query = '';
  String get query => _query;

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> cargar() async {
    status = ReservaStatus.cargando;
    errorMsg = '';
    notifyListeners();

    try {
      _todas = await _service.getReservas();
      _todasOriginales = List.from(_todas);
      status = ReservaStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = ReservaStatus.error;
    }

    notifyListeners();
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────────

  void buscar(String q) {
    _query = q;
    if (q.trim().isEmpty) {
      _todas = List.from(_todasOriginales);
    } else {
      final lower = q.toLowerCase();
      _todas = _todasOriginales.where((r) =>
        r.clienteNombre.toLowerCase().contains(lower) ||
        r.homenajeado.toLowerCase().contains(lower) ||
        r.tipoEvento.toLowerCase().contains(lower) ||
        r.estadoLabel.toLowerCase().contains(lower),
      ).toList();
    }
    notifyListeners();
  }

  // ── Obtener detalle ────────────────────────────────────────────────────────

  Future<Reserva?> getDetalle(int id) async {
    try {
      return await _service.getReservaById(id);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Anular reserva ─────────────────────────────────────────────────────────

  Future<bool> anular(int id) async {
    try {
      await _service.anularReserva(id);
      _actualizarEstado(id, 'ANULADA');
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Registrar abono ────────────────────────────────────────────────────────

  Future<bool> registrarAbono(
    int reservaId, {
    required double monto,
    required String metodoPago,
    String? notas,
  }) async {
    try {
      await _service.registrarAbono(
        reservaId,
        monto: monto,
        metodoPago: metodoPago,
        notas: notas,
      );
      // Recargar la reserva actualizada
      await cargar();
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

  // ── Helper interno ─────────────────────────────────────────────────────────

  void _actualizarEstado(int id, String nuevoEstado) {
    for (final list in [_todas, _todasOriginales]) {
      final idx = list.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final r = list[idx];
        list[idx] = Reserva(
          id: r.id,
          cotizacionId: r.cotizacionId,
          estado: nuevoEstado,
          totalValor: r.totalValor,
          saldoPendiente: r.saldoPendiente,
          clienteNombre: r.clienteNombre,
          clienteEmail: r.clienteEmail,
          clienteTelefono: r.clienteTelefono,
          homenajeado: r.homenajeado,
          tipoEvento: r.tipoEvento,
          fechaEvento: r.fechaEvento,
          horaInicio: r.horaInicio,
          horaFin: r.horaFin,
          ubicacion: r.ubicacion,
          abonos: r.abonos,
        );
      }
    }
    notifyListeners();
  }
}
