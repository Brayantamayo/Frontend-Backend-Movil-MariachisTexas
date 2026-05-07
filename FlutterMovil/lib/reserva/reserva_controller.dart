import 'package:flutter/foundation.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'reserva_service.dart';
import '../core/services/servicio_service.dart';

enum ReservaStatus { inicial, cargando, listo, error }

class ReservaController extends ChangeNotifier {
  final ReservaService _service = ReservaService();

  ReservaStatus status = ReservaStatus.inicial;
  String errorMsg = '';

  List<Reserva> _todas = [];
  List<Reserva> _todasOriginales = [];
  List<Reserva> get reservas => _todas;

  // Catálogo de servicios para resolver nombres por ID
  Map<int, Servicio> _catalogoServicios = {};

  String _query = '';
  String get query => _query;

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> cargar() async {
    status = ReservaStatus.cargando;
    errorMsg = '';
    notifyListeners();

    try {
      // Cargar catálogo de servicios y reservas en paralelo
      final results = await Future.wait([
        ServicioService.obtenerServicios(),
        _service.getReservas(),
      ]);
      final servicios = (results[0] as List).cast<Servicio>();
      _catalogoServicios = {for (final s in servicios) s.id: s};

      final reservas = (results[1] as List).cast<Reserva>();
      _todas = reservas.map((r) => _enriquecerReserva(r)).toList();
      _todasOriginales = List.from(_todas);
      status = ReservaStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = ReservaStatus.error;
    }

    notifyListeners();
  }

  /// Enriquece una reserva resolviendo los nombres de servicios por ID
  Reserva _enriquecerReserva(Reserva r) {
    if (r.serviciosRaw.isEmpty) return r;
    final chipsNuevos = r.serviciosRaw.map((raw) {
      final id = _parseInt(raw['serviceId']);
      final qty = _parseInt(raw['quantity'] ?? 1);
      final servicio = _catalogoServicios[id];
      return VentaServicio(
        nombre: servicio?.nombre ?? 'Servicio $id',
        cantidad: qty,
        precio: servicio?.precio ?? 0,
      );
    }).toList();
    return r.copyWithChips(chipsNuevos);
  }

  Future<void> _cargarCatalogoSiVacio() async {
    if (_catalogoServicios.isNotEmpty) return;
    try {
      final servicios = await ServicioService.obtenerServicios();
      _catalogoServicios = {for (final s in servicios) s.id: s};
    } catch (_) {}
  }

  int _parseInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

  // ── Búsqueda ───────────────────────────────────────────────────────────────

  void buscar(String q) {
    _query = q;
    _aplicarFiltros();
  }

  EstadoReserva? _estadoFiltro;
  EstadoReserva? get estadoFiltro => _estadoFiltro;

  void filtrarPorEstado(EstadoReserva? estado) {
    _estadoFiltro = estado;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    var lista = List<Reserva>.from(_todasOriginales);
    if (_estadoFiltro != null) {
      lista = lista.where((r) => r.estadoEnum == _estadoFiltro).toList();
    }
    if (_query.trim().isNotEmpty) {
      final lower = _query.toLowerCase();
      lista = lista
          .where((r) =>
              r.clienteNombre.toLowerCase().contains(lower) ||
              r.homenajeado.toLowerCase().contains(lower) ||
              r.tipoEvento.toLowerCase().contains(lower) ||
              r.estadoLabel.toLowerCase().contains(lower))
          .toList();
    }
    _todas = lista;
    notifyListeners();
  }

  // ── Obtener detalle ────────────────────────────────────────────────────────

  Future<Reserva?> getDetalle(int id) async {
    try {
      await _cargarCatalogoSiVacio();
      final r = await _service.getReservaById(id);
      return _enriquecerReserva(r);
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

  // ── Crear reserva directa ──────────────────────────────────────────────────

  Future<bool> crearReserva({
    required int clienteId,
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required String homenajeado,
    required TipoEvento tipoEvento,
    required DateTime fechaEvento,
    required String horaInicio,
    required String horaFin,
    required String ubicacion,
    required double totalValor,
    List<Map<String, dynamic>>? servicios,
  }) async {
    try {
      await _service.crearReserva(
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteEmail: clienteEmail,
        clienteTelefono: clienteTelefono,
        homenajeado: homenajeado,
        tipoEvento: _tipoEventoToString(tipoEvento),
        fechaEvento: fechaEvento,
        horaInicio: horaInicio,
        horaFin: horaFin,
        ubicacion: ubicacion,
        totalValor: totalValor,
        servicios: servicios,
      );
      // Recargar la lista de reservas
      await cargar();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Obtener horas disponibles ──────────────────────────────────────────────

  Future<List<String>> obtenerHorasDisponibles(DateTime fecha) async {
    try {
      return await _service.obtenerHorasDisponibles(fecha);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      // Retornar horas por defecto si hay error
      return _generarHorasPorDefecto();
    }
  }

  List<String> _generarHorasPorDefecto() {
    // Generar horas de 8:00 AM a 11:00 PM cada hora
    final horas = <String>[];
    for (int h = 8; h <= 23; h++) {
      horas.add('${h.toString().padLeft(2, '0')}:00');
    }
    return horas;
  }

  // ── Helper para convertir TipoEvento a String ──────────────────────────────

  String _tipoEventoToString(TipoEvento tipo) {
    return switch (tipo) {
      TipoEvento.boda => 'BODA',
      TipoEvento.cumpleanos => 'CUMPLEANOS',
      TipoEvento.quinceanios => 'QUINCEANIOS',
      TipoEvento.funeral => 'FUNERAL',
      TipoEvento.reconciliacion => 'RECONCILIACION',
      TipoEvento.diaDeMadre => 'DIA_DE_MADRE',
      TipoEvento.amor => 'AMOR',
      TipoEvento.aniversario => 'ANIVERSARIO',
      TipoEvento.padres => 'PADRES',
      TipoEvento.fiesta => 'FIESTA',
      TipoEvento.otro => 'OTRO',
    };
  }

  // ── Actualizar reserva ────────────────────────────────────────────────────

  Future<bool> actualizarReserva(int id, Map<String, dynamic> datos) async {
    try {
      await _service.actualizarReserva(id, datos);
      await cargar();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Eliminar reserva ─────────────────────────────────────────────────────

  Future<bool> eliminarReserva(int id) async {
    try {
      await _service.eliminarReserva(id);
      // Remover de las listas locales
      _todas.removeWhere((r) => r.id == id);
      _todasOriginales.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Reprogramar reserva ──────────────────────────────────────────────────

  Future<bool> reprogramarReserva(int id, DateTime nuevaFecha,
      String nuevaHoraInicio, String nuevaHoraFin) async {
    try {
      await _service.reprogramarReserva(
          id, nuevaFecha, nuevaHoraInicio, nuevaHoraFin);
      await cargar();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Finalizar reserva ─────────────────────────────────────────────────────

  Future<bool> finalizarReserva(int id) async {
    try {
      await _service.finalizarReserva(id);
      _actualizarEstado(id, 'FINALIZADO');
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Obtener abonos de una reserva ─────────────────────────────────────────

  Future<List<Abono>> obtenerAbonosReserva(int reservaId) async {
    try {
      return await _service.obtenerAbonosReserva(reservaId);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return [];
    }
  }

  // ── Obtener todos los abonos ─────────────────────────────────────────────

  Future<List<Abono>> obtenerTodosAbonos() async {
    try {
      return await _service.obtenerTodosAbonos();
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return [];
    }
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
