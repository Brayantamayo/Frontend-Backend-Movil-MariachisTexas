import 'package:flutter/foundation.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'cotizacion_service.dart';
import '../core/services/servicio_service.dart';

enum CotizacionStatus { inicial, cargando, listo, error }

class CotizacionController extends ChangeNotifier {
  final CotizacionService _service = CotizacionService();

  CotizacionStatus status = CotizacionStatus.inicial;
  String errorMsg = '';

  List<Cotizacion> _todas = [];
  List<Cotizacion> _todasOriginales = [];
  List<Cotizacion> get cotizaciones => _todas;

  Map<int, Servicio> _catalogoServicios = {};

  String _query = '';
  String get query => _query;
  EstadoCotizacion? _estadoFiltro;
  EstadoCotizacion? get estadoFiltro => _estadoFiltro;

  Future<void> cargar() async {
    status = CotizacionStatus.cargando;
    errorMsg = '';
    notifyListeners();
    try {
      // Primero cargar el catálogo
      final servicios = await ServicioService.obtenerServicios();
      _catalogoServicios = {for (final s in servicios) s.id: s};

      // Luego cargar cotizaciones y enriquecer cada una igual que el detalle
      final rawList = await _service.getCotizacionesRaw();
      _todas = rawList.map((j) {
        final c = Cotizacion.fromJson(j);
        return _enriquecerDesdeJson(c, j);
      }).toList();
      _todasOriginales = List.from(_todas);
      status = CotizacionStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = CotizacionStatus.error;
    }
    notifyListeners();
  }

  Cotizacion _enriquecerDesdeJson(Cotizacion c, Map<String, dynamic> j) {
    final svcsRaw = j['selectedServices'] ?? j['services'];
    if (svcsRaw == null) return c;
    final chips = <VentaServicio>[];
    try {
      for (final item in svcsRaw) {
        try {
          // Convertir cada item a Map<String, dynamic> de forma segura
          final m = <String, dynamic>{};
          (item as Map).forEach((k, v) => m[k.toString()] = v);
          final id = _parseInt(m['serviceId']);
          final qty = _parseInt(m['quantity'] ?? 1);
          final svc = _catalogoServicios[id];
          chips.add(VentaServicio(
            nombre: svc?.nombre ?? 'Servicio $id',
            cantidad: qty,
            precio: svc?.precio ?? 0,
          ));
        } catch (_) {}
      }
    } catch (_) {}
    if (chips.isEmpty) return c;
    return c.copyWithChips(chips);
  }

  Future<void> _cargarCatalogoSiVacio() async {
    if (_catalogoServicios.isNotEmpty) return;
    try {
      final servicios = await ServicioService.obtenerServicios();
      _catalogoServicios = {for (final s in servicios) s.id: s};
    } catch (_) {}
  }

  int _parseInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

  /// Buscar cotizaciones
  void buscar(String q) {
    _query = q;
    _aplicarFiltros();
  }

  void filtrarPorEstado(EstadoCotizacion? estado) {
    _estadoFiltro = estado;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    var lista = List<Cotizacion>.from(_todasOriginales);
    if (_estadoFiltro != null) {
      lista = lista.where((c) => c.estado == _estadoFiltro).toList();
    }
    if (_query.trim().isNotEmpty) {
      final lower = _query.toLowerCase();
      lista = lista
          .where((c) =>
              c.clienteNombre.toLowerCase().contains(lower) ||
              c.homenajeado.toLowerCase().contains(lower) ||
              c.tipoEventoLabel.toLowerCase().contains(lower) ||
              c.estadoLabel.toLowerCase().contains(lower))
          .toList();
    }
    _todas = lista;
    notifyListeners();
  }

  /// Obtener detalle de una cotización
  Future<Cotizacion?> getDetalle(int id) async {
    try {
      await _cargarCatalogoSiVacio();
      final j = await _service.getCotizacionByIdRaw(id);
      final c = Cotizacion.fromJson(j);
      return _enriquecerDesdeJson(c, j);
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

  // ── Crear cotización ───────────────────────────────────────────────────────

  Future<bool> crearCotizacion({
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required String homenajeado,
    required TipoEvento tipoEvento,
    required DateTime fechaEvento,
    required String horaInicio,
    required String horaFin,
    required String ubicacion,
    required List<Map<String, dynamic>> servicios,
  }) async {
    try {
      await _service.crearCotizacion(
        clienteNombre: clienteNombre,
        clienteEmail: clienteEmail,
        clienteTelefono: clienteTelefono,
        homenajeado: homenajeado,
        tipoEvento: _tipoEventoToString(tipoEvento),
        fechaEvento: fechaEvento,
        horaInicio: horaInicio,
        horaFin: horaFin,
        ubicacion: ubicacion,
        servicios: servicios,
      );
      // Recargar la lista de cotizaciones
      await cargar();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
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

  // ── Helper interno ────────────────────────────────────────────────────────
  void _actualizarEstado(int id, EstadoCotizacion nuevoEstado) {
    final idx = _todas.indexWhere((c) => c.id == id);
    if (idx != -1) _todas[idx] = _todas[idx].copyWith(estado: nuevoEstado);
    final idx2 = _todasOriginales.indexWhere((c) => c.id == id);
    if (idx2 != -1)
      _todasOriginales[idx2] =
          _todasOriginales[idx2].copyWith(estado: nuevoEstado);
    notifyListeners();
  }
}
