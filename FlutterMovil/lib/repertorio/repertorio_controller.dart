import 'package:flutter/foundation.dart';
import 'cancion.model.dart';
import 'repertorio_service.dart';

enum RepertorioStatus { inicial, cargando, listo, error }

class RepertorioController extends ChangeNotifier {
  final RepertorioService _service = RepertorioService();

  RepertorioStatus status = RepertorioStatus.inicial;
  String errorMsg = '';

  List<Cancion> _todas = [];
  List<Cancion> get canciones => _todas;

  String _query = '';
  String get query => _query;

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> cargar() async {
    status = RepertorioStatus.cargando;
    errorMsg = '';
    notifyListeners();

    try {
      _todas = await _service.getCanciones();
      status = RepertorioStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = RepertorioStatus.error;
    }

    notifyListeners();
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────────

  Future<void> buscar(String q) async {
    _query = q;
    notifyListeners();

    if (q.trim().isEmpty) {
      await cargar();
      return;
    }

    status = RepertorioStatus.cargando;
    notifyListeners();

    try {
      _todas = await _service.buscarCanciones(q);
      status = RepertorioStatus.listo;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      status = RepertorioStatus.error;
    }

    notifyListeners();
  }

  // ── Detalle (carga letra y audioUrl completo) ─────────────────────────────

  Future<Cancion?> getDetalle(int id) async {
    try {
      return await _service.getDetalle(id);
    } catch (e) {
      return null;
    }
  }

  // ── Toggle activa / inactiva ──────────────────────────────────────────────

  Future<void> toggle(int id) async {
    try {
      final actualizada = await _service.toggleCancion(id);
      final idx = _todas.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _todas[idx].activa = actualizada.activa;
        notifyListeners();
      }
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ── Eliminar ───────────────────────────────────────────────────────────────

  Future<bool> eliminar(int id) async {
    try {
      await _service.eliminarCancion(id);
      _todas.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMsg = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}