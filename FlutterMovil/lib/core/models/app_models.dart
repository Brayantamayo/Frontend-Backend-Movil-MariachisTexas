// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum EstadoCotizacion { enEspera, convertida, anulada }

enum EstadoReserva { pendiente, confirmada, anulada, finalizado }

enum EstadoEnsayo { pendiente, listo }

enum EstadoVenta { pendiente, completada, cancelada }

enum TipoEvento {
  boda,
  cumpleanos,
  quinceanios,
  funeral,
  reconciliacion,
  diaDeMadre,
  amor,
  aniversario,
  padres,
  fiesta,
  otro
}

// ─── HELPERS DE PARSEO SEGUROS ────────────────────────────────────────────────

int _parseInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
int? _parseIntNull(dynamic v) =>
    v == null ? null : (v is int ? v : int.tryParse(v.toString()));
double _parseDouble(dynamic v) =>
    v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
double? _parseDoubleNull(dynamic v) =>
    v == null ? null : double.tryParse(v.toString());
DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.isUtc ? v.toLocal() : v;
  try {
    final dt = DateTime.parse(v.toString());
    return dt.isUtc ? dt.toLocal() : dt;
  } catch (_) {
    return null;
  }
}

// ─── USUARIO ──────────────────────────────────────────────────────────────────

class Usuario {
  final int id;
  final String nombre;
  final String email;

  const Usuario({required this.id, required this.nombre, required this.email});

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: _parseInt(j['id']),
        nombre: j['nombre'] as String,
        email: j['email'] as String? ?? '',
      );
}

// ─── CLIENTE ──────────────────────────────────────────────────────────────────

class Cliente {
  final int id;
  final String apellido;
  final String? email;
  final String? telefonoPrincipal;
  final String? telefonoAlternativo;
  final String? direccion;
  final String? ciudad;
  final Usuario? usuario;

  const Cliente({
    required this.id,
    required this.apellido,
    this.email,
    this.telefonoPrincipal,
    this.telefonoAlternativo,
    this.direccion,
    this.ciudad,
    this.usuario,
  });

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
        id: _parseInt(j['id']),
        apellido: j['apellido'] as String,
        email: j['email'] as String?,
        telefonoPrincipal: j['telefonoPrincipal'] as String?,
        telefonoAlternativo: j['telefonoAlternativo'] as String?,
        direccion: j['direccion'] as String?,
        ciudad: j['ciudad'] as String?,
        usuario: j['usuario'] != null
            ? Usuario.fromJson(j['usuario'] as Map<String, dynamic>)
            : null,
      );

  String get nombreCompleto =>
      usuario != null ? '${usuario!.nombre} $apellido' : apellido;
}

// ─── SERVICIO ─────────────────────────────────────────────────────────────────

class Servicio {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;

  const Servicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
  });

  factory Servicio.fromJson(Map<String, dynamic> j) => Servicio(
        id: _parseInt(j['id']),
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        precio: _parseDouble(j['precio']),
      );
}

class CotizacionServicio {
  final int id;
  final int cotizacionId;
  final int servicioId;
  final Servicio servicio;
  final int cantidad;

  const CotizacionServicio({
    required this.id,
    required this.cotizacionId,
    required this.servicioId,
    required this.servicio,
    required this.cantidad,
  });

  factory CotizacionServicio.fromJson(Map<String, dynamic> j) {
    // Soporta múltiples formatos del backend:
    // Formato A: { id, cotizacionId, servicioId, servicio: {...}, cantidad }
    // Formato B: { id, serviceId, service: {...}, quantity }
    // Formato C: { serviceId, quantity, service: {...} }
    final servicioRaw = j['servicio'] ?? j['service'];
    final Servicio servicio;
    if (servicioRaw != null) {
      servicio = Servicio.fromJson(servicioRaw as Map<String, dynamic>);
    } else {
      // Fallback: construir servicio desde los campos planos
      final id = _parseInt(j['serviceId'] ?? j['servicioId'] ?? j['id'] ?? 0);
      final nombre =
          (j['nombre'] ?? j['name'] ?? j['serviceName'] ?? '') as String;
      final precio = _parseDouble(j['precio'] ?? j['price'] ?? 0);
      servicio = Servicio(id: id, nombre: nombre, precio: precio);
    }
    return CotizacionServicio(
      id: _parseInt(j['id'] ?? j['serviceId'] ?? j['servicioId'] ?? 0),
      cotizacionId: _parseInt(
          j['cotizacionId'] ?? j['reservationId'] ?? j['quoteId'] ?? 0),
      servicioId: _parseInt(j['servicioId'] ?? j['serviceId'] ?? servicio.id),
      servicio: servicio,
      cantidad: _parseInt(j['cantidad'] ?? j['quantity'] ?? 1),
    );
  }

  double get subtotal => servicio.precio * cantidad;
}

// ─── REPERTORIO ───────────────────────────────────────────────────────────────

class Repertorio {
  final int id;
  final String titulo;
  final String artista;
  final String genero;
  final String categoria;
  final String duracion;
  final String dificultad;
  final String? portada;
  final String? audioUrl;
  final String? letra;
  final bool activa;

  const Repertorio({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.genero,
    required this.categoria,
    required this.duracion,
    required this.dificultad,
    this.portada,
    this.audioUrl,
    this.letra,
    this.activa = true,
  });

  factory Repertorio.fromJson(Map<String, dynamic> j) => Repertorio(
        id: _parseInt(j['id']),
        titulo: j['titulo'] as String,
        artista: j['artista'] as String? ?? '',
        genero: j['genero'] as String? ?? '',
        categoria: j['categoria'] as String? ?? '',
        duracion: j['duracion'] as String? ?? '',
        dificultad: j['dificultad'] as String? ?? '',
        portada: j['portada'] as String?,
        audioUrl: j['audioUrl'] as String?,
        letra: j['letra'] as String?,
        activa: j['activa'] as bool? ?? true,
      );
}

class CotizacionRepertorio {
  final int id;
  final int cotizacionId;
  final int repertorioId;
  final Repertorio repertorio;
  final int orden;

  const CotizacionRepertorio({
    required this.id,
    required this.cotizacionId,
    required this.repertorioId,
    required this.repertorio,
    required this.orden,
  });

  factory CotizacionRepertorio.fromJson(Map<String, dynamic> j) =>
      CotizacionRepertorio(
        id: _parseInt(j['id']),
        cotizacionId: _parseInt(j['cotizacionId']),
        repertorioId: _parseInt(j['repertorioId']),
        repertorio:
            Repertorio.fromJson(j['repertorio'] as Map<String, dynamic>),
        orden: _parseInt(j['orden']),
      );
}

// ─── ABONO ────────────────────────────────────────────────────────────────────

class Abono {
  final int id;
  final double monto;
  final DateTime fechaPago;
  final String metodoPago;
  final double nuevoSaldo;
  final String? notas;

  const Abono({
    required this.id,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    required this.nuevoSaldo,
    this.notas,
  });

  factory Abono.fromJson(Map<String, dynamic> j) => Abono(
        id: _parseInt(j['id']),
        monto: _parseDouble(j['amount'] ?? j['monto']),
        fechaPago: _parseDateTime(
                (j['date'] ?? j['paymentDate'] ?? j['fechaPago']) as String?) ??
            DateTime.now(),
        metodoPago: (j['method'] ?? j['paymentMethod'] ?? j['metodoPago'] ?? '')
            as String,
        nuevoSaldo: _parseDouble(j['newBalance'] ?? j['nuevoSaldo']),
        notas: (j['notes'] ?? j['notas']) as String?,
      );
}

// ─── RESERVA ──────────────────────────────────────────────────────────────────

class Reserva {
  final int id;
  final int cotizacionId;
  final String estado;
  final double totalValor;
  final double saldoPendiente;
  final String clienteNombre;
  final String clienteEmail;
  final String clienteTelefono;
  final String homenajeado;
  final String tipoEvento;
  final DateTime fechaEvento;
  final String horaInicio;
  final String horaFin;
  final String ubicacion;
  final List<Abono> abonos;
  final List<CotizacionServicio> servicios;

  const Reserva({
    required this.id,
    required this.cotizacionId,
    required this.estado,
    required this.totalValor,
    required this.saldoPendiente,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteTelefono,
    required this.homenajeado,
    required this.tipoEvento,
    required this.fechaEvento,
    required this.horaInicio,
    required this.horaFin,
    required this.ubicacion,
    this.abonos = const [],
    this.servicios = const [],
  });

  factory Reserva.fromJson(Map<String, dynamic> j) {
    // Los servicios pueden venir directamente o dentro de cotizacion/quotation
    final cotizacion = j['cotizacion'] as Map<String, dynamic>? ??
        j['quotation'] as Map<String, dynamic>? ??
        j['quote'] as Map<String, dynamic>?;

    final serviciosRaw = j['selectedServices'] ??
        j['services'] ??
        j['tiposSerenata'] ??
        j['reservationServices'] ??
        j['items'] ??
        cotizacion?['services'] ??
        cotizacion?['servicios'] ??
        cotizacion?['selectedServices'];

    return Reserva(
      id: _parseInt(j['id']),
      cotizacionId: _parseInt(j['cotizacionId'] ?? j['quotationId'] ?? 0),
      estado: (j['status'] as String?) ?? 'PENDIENTE',
      totalValor: _parseDouble(j['totalAmount'] ?? j['totalValor']),
      saldoPendiente: _parseDouble(j['pendingBalance'] ?? j['saldoPendiente']),
      clienteNombre: (j['clientName'] as String?) ?? '',
      clienteEmail: (j['clientEmail'] as String?) ?? '',
      clienteTelefono: (j['clientPhone'] as String?) ?? '',
      homenajeado: (j['homenajeado'] as String?) ?? '',
      tipoEvento: (j['eventType'] as String?) ?? '',
      fechaEvento: _parseDateTime(j['eventDate']) ?? DateTime.now(),
      horaInicio: (j['startTime'] as String?) ?? '',
      horaFin: (j['endTime'] as String?) ?? '',
      ubicacion: (j['location'] as String?) ?? '',
      abonos: (j['payments'] as List<dynamic>?)
              ?.map((e) => Abono.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      servicios: _parseServicios(serviciosRaw),
    );
  }

  EstadoReserva get estadoEnum => _estadoReservaFromString(estado);

  String get estadoLabel => _estadoReservaToLabel(estadoEnum);

  String get tipoSerenata {
    if (servicios.isEmpty) return 'Sin servicios';
    if (servicios.length == 1) return servicios.first.servicio.nombre;
    return servicios.map((s) => s.servicio.nombre).join(', ');
  }

  static List<CotizacionServicio> _parseServicios(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    if ((raw).isEmpty) return [];
    return raw
        .map((e) {
          try {
            final m = e as Map<String, dynamic>;

            // Intentar extraer el objeto servicio de cualquier clave posible
            final servicioRaw = m['servicio'] ??
                m['service'] ??
                m['tipoSerenata'] ??
                m['serenata'];

            String nombre = '';
            double precio = 0;
            int svcId = 0;

            if (servicioRaw is Map<String, dynamic>) {
              // Objeto anidado con el servicio
              nombre = (servicioRaw['nombre'] ??
                  servicioRaw['name'] ??
                  servicioRaw['title'] ??
                  servicioRaw['descripcion'] ??
                  '') as String;
              precio = _parseDouble(servicioRaw['precio'] ??
                  servicioRaw['price'] ??
                  servicioRaw['costo'] ??
                  0);
              svcId = _parseInt(servicioRaw['id'] ?? 0);
            } else {
              // Campos planos en el mismo objeto
              nombre = (m['nombre'] ??
                  m['name'] ??
                  m['serviceName'] ??
                  m['title'] ??
                  '') as String;
              precio =
                  _parseDouble(m['precio'] ?? m['price'] ?? m['costo'] ?? 0);
              svcId =
                  _parseInt(m['id'] ?? m['serviceId'] ?? m['servicioId'] ?? 0);
            }

            final cantidad =
                _parseInt(m['cantidad'] ?? m['quantity'] ?? m['qty'] ?? 1);
            final id = _parseInt(
                m['id'] ?? m['serviceId'] ?? m['servicioId'] ?? svcId);

            final svc = Servicio(id: svcId, nombre: nombre, precio: precio);
            return CotizacionServicio(
              id: id,
              cotizacionId: 0,
              servicioId: svcId,
              servicio: svc,
              cantidad: cantidad,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<CotizacionServicio>()
        .toList();
  }

  String _estadoReservaToLabel(EstadoReserva e) => switch (e) {
        EstadoReserva.pendiente => 'Pendiente',
        EstadoReserva.confirmada => 'Confirmada',
        EstadoReserva.anulada => 'Anulada',
        EstadoReserva.finalizado => 'Finalizado',
      };
}

// ─── VENTA ────────────────────────────────────────────────────────────────────

/// Servicio plano tal como lo devuelve el endpoint de ventas
/// { nombre, cantidad, precio }
class VentaServicio {
  final String nombre;
  final int cantidad;
  final double precio;

  const VentaServicio({
    required this.nombre,
    required this.cantidad,
    required this.precio,
  });

  factory VentaServicio.fromJson(Map<String, dynamic> j) => VentaServicio(
        nombre: (j['nombre'] ?? j['name'] ?? '') as String,
        cantidad: _parseInt(j['cantidad'] ?? j['quantity'] ?? 1),
        precio: _parseDouble(j['precio'] ?? j['price'] ?? 0),
      );

  double get subtotal => precio * cantidad;
}

class Venta {
  /// Puede ser "1" o "RES-3" — se guarda como String
  final String idRaw;
  final String clienteNombre;
  final String clienteEmail;
  final String clienteTelefono;
  final double totalValor;
  final double saldoPendiente;
  final double montoPagado;

  /// "Confirmado" | "Finalizado" | "Cancelada"
  final String estado;
  final DateTime fechaVenta;
  final String? concepto;
  final String? tipo;
  // Datos del evento (cuando viene de reserva)
  final DateTime? fechaEvento;
  final String? tipoEvento;
  final String? horaInicio;
  final String? horaFin;
  final String? ubicacion;
  final String? homenajeado;
  final String? notas;
  final List<VentaServicio> servicios;
  final List<Abono> abonos;

  const Venta({
    required this.idRaw,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteTelefono,
    required this.totalValor,
    required this.saldoPendiente,
    required this.montoPagado,
    required this.estado,
    required this.fechaVenta,
    this.concepto,
    this.tipo,
    this.fechaEvento,
    this.tipoEvento,
    this.horaInicio,
    this.horaFin,
    this.ubicacion,
    this.homenajeado,
    this.notas,
    this.servicios = const [],
    this.abonos = const [],
  });

  /// ID numérico para navegación (extrae el número de "RES-3" → 3)
  int get id => int.tryParse(idRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  factory Venta.fromJson(Map<String, dynamic> j) => Venta(
        idRaw: (j['id'] ?? '0').toString(),
        clienteNombre: (j['clientName'] ?? j['clienteNombre'] ?? '') as String,
        clienteEmail: (j['clientEmail'] ?? j['clienteEmail'] ?? '') as String,
        clienteTelefono:
            (j['clientPhone'] ?? j['clienteTelefono'] ?? '') as String,
        totalValor: _parseDouble(j['totalAmount'] ?? j['totalValor']),
        saldoPendiente: _parseDouble(j['pendingAmount'] ?? j['saldoPendiente']),
        montoPagado: _parseDouble(j['paidAmount'] ?? j['montoPagado']),
        // El backend devuelve "Confirmado"/"Finalizado"/"Cancelada"
        estado: (j['status'] ?? j['estado'] ?? 'Pendiente') as String,
        fechaVenta:
            _parseDateTime(j['date'] ?? j['saleDate'] ?? j['fechaVenta']) ??
                DateTime.now(),
        concepto: (j['concept'] ?? j['descripcion']) as String?,
        tipo: (j['type'] ?? j['tipo']) as String?,
        fechaEvento: _parseDateTime(j['eventDate']),
        tipoEvento: (j['eventType'] ?? '') as String,
        horaInicio: (j['eventTime'] ?? j['horaInicio']) as String?,
        horaFin: (j['eventEndTime'] ?? j['horaFin']) as String?,
        ubicacion: (j['eventLocation'] ?? j['location']) as String?,
        homenajeado: (j['homenajeado']) as String?,
        notas: (j['notes'] ?? j['notas']) as String?,
        servicios: _parseVentaServicios(j['services'] ?? j['servicios']),
        abonos: (j['abonos'] as List<dynamic>?)
                ?.map((e) => Abono.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  EstadoVenta get estadoEnum => _estadoVentaFromString(estado);
  String get estadoLabel => _estadoVentaToLabel(estadoEnum);
}

List<VentaServicio> _parseVentaServicios(dynamic raw) {
  if (raw == null || raw is! List) return [];
  return (raw)
      .map((e) {
        try {
          return VentaServicio.fromJson(e as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      })
      .whereType<VentaServicio>()
      .toList();
}

// ─── COTIZACIÓN ───────────────────────────────────────────────────────────────

class Cotizacion {
  final int id;
  final int? clienteId;
  final String clienteNombre;
  final String clienteEmail;
  final String clienteTelefono;
  final String homenajeado;
  final TipoEvento tipoEvento;
  final DateTime fechaEvento;
  final String horaInicio;
  final String horaFin;
  final String ubicacion;
  final String? notas;
  final double? totalEstimado;
  final bool esReservaDirecta;
  EstadoCotizacion estado;
  final DateTime createdAt;
  final List<CotizacionServicio> servicios;
  final List<CotizacionRepertorio> repertorios;
  final Reserva? reserva;

  Cotizacion({
    required this.id,
    this.clienteId,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteTelefono,
    required this.homenajeado,
    required this.tipoEvento,
    required this.fechaEvento,
    required this.horaInicio,
    required this.horaFin,
    required this.ubicacion,
    this.notas,
    this.totalEstimado,
    required this.esReservaDirecta,
    required this.estado,
    required this.createdAt,
    this.servicios = const [],
    this.repertorios = const [],
    this.reserva,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> j) => Cotizacion(
        id: _parseInt(j['id']),
        clienteId: _parseIntNull(j['clientId']),
        clienteNombre: j['clientName'] as String? ?? '',
        clienteEmail: j['clientEmail'] as String? ?? '',
        clienteTelefono: j['clientPhone'] as String? ?? '',
        homenajeado: j['homenajeado'] as String? ?? '',
        tipoEvento: _tipoEventoFromString(j['eventType'] as String? ?? 'OTRO'),
        fechaEvento: DateTime.parse(j['eventDate'] as String),
        horaInicio: j['startTime'] as String? ?? '',
        horaFin: j['endTime'] as String? ?? '',
        ubicacion: j['location'] as String? ?? '',
        notas: j['notes'] as String?,
        totalEstimado: _parseDoubleNull(j['totalAmount']),
        esReservaDirecta: j['isDirectReservation'] as bool? ?? false,
        estado:
            _estadoCotizacionFromString(j['status'] as String? ?? 'EN_ESPERA'),
        createdAt: DateTime.parse(j['createdAt'] as String),
        servicios: (j['services'] as List<dynamic>?)
                ?.map((e) =>
                    CotizacionServicio.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        repertorios: (j['repertoire'] as List<dynamic>?)
                ?.map((e) =>
                    CotizacionRepertorio.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        reserva: j['reservation'] != null
            ? Reserva.fromJson(j['reservation'] as Map<String, dynamic>)
            : null,
      );

  Cotizacion copyWith({EstadoCotizacion? estado}) => Cotizacion(
        id: id,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteEmail: clienteEmail,
        clienteTelefono: clienteTelefono,
        homenajeado: homenajeado,
        tipoEvento: tipoEvento,
        fechaEvento: fechaEvento,
        horaInicio: horaInicio,
        horaFin: horaFin,
        ubicacion: ubicacion,
        notas: notas,
        totalEstimado: totalEstimado,
        esReservaDirecta: esReservaDirecta,
        estado: estado ?? this.estado,
        createdAt: createdAt,
        servicios: servicios,
        repertorios: repertorios,
        reserva: reserva,
      );

  String get tipoEventoLabel => _tipoEventoToLabel(tipoEvento);
  String get estadoLabel => _estadoCotizacionToLabel(estado);
  bool get puedeConvertirse =>
      estado == EstadoCotizacion.enEspera &&
      totalEstimado != null &&
      totalEstimado! > 0;
  bool get puedeAnularse => estado == EstadoCotizacion.enEspera;
  bool get puedeEliminarse => true;
}

// ─── ENSAYO ───────────────────────────────────────────────────────────────────

class Ensayo {
  final int id;
  final String nombre;
  final DateTime fechaHora;
  final String lugar;
  final String? ubicacion;
  final EstadoEnsayo estado;
  final List<Repertorio> repertorios;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Ensayo({
    required this.id,
    required this.nombre,
    required this.fechaHora,
    required this.lugar,
    this.ubicacion,
    required this.estado,
    this.repertorios = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Ensayo.fromJson(Map<String, dynamic> j) => Ensayo(
        id: _parseInt(j['id']),
        nombre: (j['title'] ??
            j['nombre'] ??
            j['name'] ??
            j['titulo'] ??
            'Sin nombre') as String,
        fechaHora: _parseDateTime(j['dateTime'] ??
                j['date_time'] ??
                j['fechaHora'] ??
                j['fecha_hora'] ??
                j['fecha'] ??
                j['date']) ??
            DateTime.now(),
        lugar: (j['location'] ??
            j['lugar'] ??
            j['place'] ??
            j['sede'] ??
            'Sin lugar') as String,
        ubicacion:
            (j['address'] ?? j['ubicacion'] ?? j['direccion']) as String?,
        estado: _estadoEnsayoFromString((j['status'] ??
            j['estado'] ??
            j['state'] ??
            'PENDIENTE') as String),
        repertorios: (j['repertoires'] as List<dynamic>? ??
                    j['repertorios'] as List<dynamic>? ??
                    j['songs'] as List<dynamic>?)
                ?.map((e) {
              final data = e['repertorio'] ?? e['repertoire'] ?? e['song'] ?? e;
              return Repertorio.fromJson(data as Map<String, dynamic>);
            }).toList() ??
            [],
        createdAt: _parseDateTime(j['createdAt'] ?? j['created_at']),
        updatedAt: _parseDateTime(j['updatedAt'] ?? j['updated_at']),
      );

  String get estadoLabel =>
      estado == EstadoEnsayo.listo ? 'listo' : 'pendiente';
}

// ─── ENUM HELPERS ─────────────────────────────────────────────────────────────

EstadoCotizacion _estadoCotizacionFromString(String s) => switch (s) {
      'CONVERTIDA' => EstadoCotizacion.convertida,
      'ANULADA' => EstadoCotizacion.anulada,
      _ => EstadoCotizacion.enEspera,
    };

String _estadoCotizacionToLabel(EstadoCotizacion e) => switch (e) {
      EstadoCotizacion.enEspera => 'En Espera',
      EstadoCotizacion.convertida => 'Aceptada',
      EstadoCotizacion.anulada => 'Anulada',
    };

EstadoReserva _estadoReservaFromString(String s) => switch (s) {
      'CONFIRMADA' => EstadoReserva.confirmada,
      'ANULADA' => EstadoReserva.anulada,
      'FINALIZADO' => EstadoReserva.finalizado,
      _ => EstadoReserva.pendiente,
    };

EstadoVenta _estadoVentaFromString(String s) => switch (s.toUpperCase()) {
      'COMPLETADA' || 'FINALIZADO' || 'FINALIZADA' => EstadoVenta.completada,
      'CANCELADA' || 'CANCELADO' => EstadoVenta.cancelada,
      _ => EstadoVenta.pendiente,
    };

String _estadoVentaToLabel(EstadoVenta e) => switch (e) {
      EstadoVenta.pendiente => 'Pendiente',
      EstadoVenta.completada => 'Completada',
      EstadoVenta.cancelada => 'Cancelada',
    };

EstadoEnsayo _estadoEnsayoFromString(String s) => switch (s) {
      'LISTO' => EstadoEnsayo.listo,
      _ => EstadoEnsayo.pendiente,
    };

TipoEvento _tipoEventoFromString(String s) => switch (s) {
      'BODA' => TipoEvento.boda,
      'CUMPLEANOS' => TipoEvento.cumpleanos,
      'QUINCEANIOS' => TipoEvento.quinceanios,
      'FUNERAL' => TipoEvento.funeral,
      'RECONCILIACION' => TipoEvento.reconciliacion,
      'DIA_DE_MADRE' => TipoEvento.diaDeMadre,
      'AMOR' => TipoEvento.amor,
      'ANIVERSARIO' => TipoEvento.aniversario,
      'PADRES' => TipoEvento.padres,
      'FIESTA' => TipoEvento.fiesta,
      _ => TipoEvento.otro,
    };

String _tipoEventoToLabel(TipoEvento t) => switch (t) {
      TipoEvento.boda => 'Boda',
      TipoEvento.cumpleanos => 'Cumpleaños',
      TipoEvento.quinceanios => 'Quinceaños',
      TipoEvento.funeral => 'Funeral',
      TipoEvento.reconciliacion => 'Reconciliación',
      TipoEvento.diaDeMadre => 'Día de la Madre',
      TipoEvento.amor => 'Amor',
      TipoEvento.aniversario => 'Aniversario',
      TipoEvento.padres => 'Día del Padre',
      TipoEvento.fiesta => 'Fiesta',
      TipoEvento.otro => 'Otro',
    };

// ─── CANCION (alias de Repertorio para el módulo de repertorio) ───────────────

class Cancion {
  final int id;
  final String titulo;
  final String artista;
  final String genero;
  final String categoria;
  final String duracion;
  final String dificultad;
  final String? portada;
  final String? audioUrl;
  final String? letra;
  final bool activa;

  const Cancion({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.genero,
    required this.categoria,
    required this.duracion,
    required this.dificultad,
    this.portada,
    this.audioUrl,
    this.letra,
    this.activa = true,
  });

  factory Cancion.fromJson(Map<String, dynamic> j) => Cancion(
        id: _parseInt(j['id']),
        titulo: (j['titulo'] ?? j['title']) as String? ?? '',
        artista: (j['artista'] ?? j['artist']) as String? ?? '',
        genero: (j['genero'] ?? j['genre']) as String? ?? '',
        categoria: (j['categoria'] ?? j['category']) as String? ?? '',
        duracion: (j['duracion'] ?? j['duration']) as String? ?? '',
        dificultad: (j['dificultad'] ?? j['difficulty']) as String? ?? '',
        portada: (j['portada'] ?? j['coverImage']) as String?,
        audioUrl: j['audioUrl'] as String?,
        letra: (j['letra'] ?? j['lyrics']) as String?,
        activa: (j['activa'] ?? j['isActive']) as bool? ?? true,
      );

  Cancion copyWith({bool? activa}) => Cancion(
        id: id,
        titulo: titulo,
        artista: artista,
        genero: genero,
        categoria: categoria,
        duracion: duracion,
        dificultad: dificultad,
        portada: portada,
        audioUrl: audioUrl,
        letra: letra,
        activa: activa ?? this.activa,
      );
}
