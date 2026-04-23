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
    if (q.trim().isEmpty) {
      _todos = List.from(_todosOriginales);
    } else {
      final lower = q.toLowerCase();
      _todos = _todosOriginales
          .where(
            (e) =>
                e.nombre.toLowerCase().contains(lower) ||
                e.lugar.toLowerCase().contains(lower) ||
                e.estadoLabel.toLowerCase().contains(lower),
          )
          .toList();
    }
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
        estado: nuevoEstado,
        repertorios: _todosOriginales[idxOrig].repertorios,
      );
    }
    notifyListeners();
  }
}
