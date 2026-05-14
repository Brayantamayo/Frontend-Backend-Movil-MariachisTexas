/// Convierte un string "HH:mm" (24h) a formato "h:mm AM/PM"
String formatHora24a12(String hora24) {
  try {
    final parts = hora24.split(':');
    if (parts.length < 2) return hora24;
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  } catch (_) {
    return hora24;
  }
}

/// Convierte un DateTime a formato "h:mm AM/PM"
String formatDateTimeHora12(DateTime dt) {
  final period = dt.hour < 12 ? 'AM' : 'PM';
  final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  return '$h12:${dt.minute.toString().padLeft(2, '0')} $period';
}

/// Convierte un TimeOfDay a formato "h:mm AM/PM" para mostrar al usuario
String formatTimeOfDay12(int hour, int minute) {
  final period = hour < 12 ? 'AM' : 'PM';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12:${minute.toString().padLeft(2, '0')} $period';
}
