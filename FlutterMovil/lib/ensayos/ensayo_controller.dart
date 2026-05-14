import 'package:flutter/foundation.dart';
import '../core/models/app_models.dart';
import 'ensayo_service.dart';

enum EnsayoStatus { inicial, cargando, listo, error }

class EnsayoController extends ChangeNotifier {
  final EnsayoService _service = EnsayoService();

  EnsayoStatus status = EnsayoStatus.inicial;
  String errorMsg = '';

  List<Ensayo> _todos = [];
  List<Ensayo> _todosOriginales = [];
  List<Ensayo> get ensayos => _todos;

  String _query = '';
  String get query => _query;
  EstadoEnsayo? _estadoFiltro;
  EstadoEnsayo? get estadoFiltro => _estadoFiltro;

  // ── Cargar ensayos ─────────────────────────────────────────────────────────
  Future<void> cargar() async {
    status = EnsayoStatus.cargando;
    errorMsg = '';
    notifyListeners();
    try {
      _todos = await _service.getEnsayos();
      _todosOriginales = List.from(_todos);
      status = EnsayoStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = EnsayoStatus.error;
    }
    notifyListeners();
  }

  // ── Buscar ensayos ─────────────────────────────────────────────────────────
  void buscar(String q) {
    _query = q;
    _aplicarFiltros();
  }

  void filtrarPorEstado(EstadoEnsayo? estado) {
    _estadoFiltro = estado;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    var lista = List<Ensayo>.from(_todosOriginales);
    if (_estadoFiltro != null) {
      lista = lista.where((e) => e.estadoEfectivo == _estadoFiltro).toList();
    }
    if (_query.trim().isNotEmpty) {
      final lower = _query.toLowerCase();
      lista = lista
          .where((e) =>
              e.nombre.toLowerCase().contains(lower) ||
              e.lugar.toLowerCase().contains(lower) ||
              e.estadoLabel.toLowerCase().contains(lower))
          .toList();
    }
    _todos = lista;
    notifyListeners();
  }

  // ── Obtener detalle de un ensayo ───────────────────────────────────────────
  Future<Ensayo?> getDetalle(int id) async {
    try {
      return await _service.getEnsayoById(id);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Actualizar ensayo ─────────────────────────────────────────────────────
  Future<bool> actualizarEnsayo(
    int id, {
    required String titulo,
    required String lugar,
    required String fecha,
    required String hora,
    String? notas,
  }) async {
    try {
      await _service.actualizarEnsayo(id,
          titulo: titulo, lugar: lugar, fecha: fecha, hora: hora, notas: notas);
      await cargar();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Marcar como listo ──────────────────────────────────────────────────────
  Future<bool> marcarComoListo(int id) async {
    try {
      await _service.toggleEstado(id);
      _actualizarEstado(id, EstadoEnsayo.listo);
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Marcar como pendiente ──────────────────────────────────────────────────
  Future<bool> marcarComoPendiente(int id) async {
    try {
      await _service.toggleEstado(id);
      _actualizarEstado(id, EstadoEnsayo.pendiente);
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Eliminar ensayo ────────────────────────────────────────────────────────
  Future<bool> eliminar(int id) async {
    try {
      await _service.eliminarEnsayo(id);
      _todos.removeWhere((e) => e.id == id);
      _todosOriginales.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Actualizar estado ──────────────────────────────────────────────────────
  void _actualizarEstado(int id, EstadoEnsayo nuevoEstado) {
    final idx = _todos.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _todos[idx] = Ensayo(
        id: _todos[idx].id,
        nombre: _todos[idx].nombre,
        fechaHora: _todos[idx].fechaHora,
        lugar: _todos[idx].lugar,
        ubicacion: _todos[idx].ubicacion,
        notas: _todos[idx].notas,
        estado: nuevoEstado,
        repertorios: _todos[idx].repertorios,
      );
    }

    final idxOrig = _todosOriginales.indexWhere((e) => e.id == id);
    if (idxOrig >= 0) {
      _todosOriginales[idxOrig] = Ensayo(
        id: _todosOriginales[idxOrig].id,
        nombre: _todosOriginales[idxOrig].nombre,
        fechaHora: _todosOriginales[idxOrig].fechaHora,
        lugar: _todosOriginales[idxOrig].lugar,
        ubicacion: _todosOriginales[idxOrig].ubicacion,
        notas: _todosOriginales[idxOrig].notas,
        estado: nuevoEstado,
        repertorios: _todosOriginales[idxOrig].repertorios,
      );
    }
    notifyListeners();
  }
}
