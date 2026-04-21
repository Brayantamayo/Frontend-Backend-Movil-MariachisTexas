// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum EstadoCotizacion { enEspera, convertida, anulada }

enum EstadoReserva { pendiente, confirmada, anulada, finalizado }

enum EstadoEnsayo { pendiente, listo }

enum TipoEvento {
  boda, cumpleanos, quinceanios, funeral, reconciliacion,
  diaDeMadre, amor, aniversario, padres, fiesta, otro
}

// ─── HELPERS DE PARSEO SEGUROS ────────────────────────────────────────────────

int _parseInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
int? _parseIntNull(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));
double _parseDouble(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
double? _parseDoubleNull(dynamic v) => v == null ? null : double.tryParse(v.toString());

// ─── USUARIO ──────────────────────────────────────────────────────────────────

class Usuario {
  final int id;
  final String nombre;
  final String email;

  const Usuario({required this.id, required this.nombre, required this.email});

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
    id:     _parseInt(j['id']),
    nombre: j['nombre'] as String,
    email:  j['email'] as String? ?? '',
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
    id:                  _parseInt(j['id']),
    apellido:            j['apellido'] as String,
    email:               j['email'] as String?,
    telefonoPrincipal:   j['telefonoPrincipal'] as String?,
    telefonoAlternativo: j['telefonoAlternativo'] as String?,
    direccion:           j['direccion'] as String?,
    ciudad:              j['ciudad'] as String?,
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
    id:          _parseInt(j['id']),
    nombre:      j['nombre'] as String,
    descripcion: j['descripcion'] as String?,
    precio:      _parseDouble(j['precio']),
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

  factory CotizacionServicio.fromJson(Map<String, dynamic> j) =>
      CotizacionServicio(
        id:           _parseInt(j['id']),
        cotizacionId: _parseInt(j['cotizacionId']),
        servicioId:   _parseInt(j['servicioId']),
        servicio:     Servicio.fromJson(j['servicio'] as Map<String, dynamic>),
        cantidad:     _parseInt(j['cantidad']),
      );

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
    id:         _parseInt(j['id']),
    titulo:     j['titulo'] as String,
    artista:    j['artista'] as String,
    genero:     j['genero'] as String,
    categoria:  j['categoria'] as String,
    duracion:   j['duracion'] as String,
    dificultad: j['dificultad'] as String? ?? '',
    portada:    j['portada'] as String?,
    audioUrl:   j['audioUrl'] as String?,
    letra:      j['letra'] as String?,
    activa:     j['activa'] as bool? ?? true,
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
        id:           _parseInt(j['id']),
        cotizacionId: _parseInt(j['cotizacionId']),
        repertorioId: _parseInt(j['repertorioId']),
        repertorio:   Repertorio.fromJson(j['repertorio'] as Map<String, dynamic>),
        orden:        _parseInt(j['orden']),
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
    id:         _parseInt(j['id']),
    monto:      _parseDouble(j['monto']),
    fechaPago:  DateTime.parse(j['fechaPago'] as String),
    metodoPago: j['metodoPago'] as String,
    nuevoSaldo: _parseDouble(j['nuevoSaldo']),
    notas:      j['notas'] as String?,
  );
}

// ─── RESERVA ──────────────────────────────────────────────────────────────────

class Reserva {
  final int id;
  final int cotizacionId;
  final String estado;
  final double totalValor;
  final double saldoPendiente;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Cotizacion? cotizacion;
  final List<Abono> abonos;

  const Reserva({
    required this.id,
    required this.cotizacionId,
    required this.estado,
    required this.totalValor,
    required this.saldoPendiente,
    required this.createdAt,
    this.updatedAt,
    this.cotizacion,
    this.abonos = const [],
  });

  factory Reserva.fromJson(Map<String, dynamic> j) => Reserva(
    id:             _parseInt(j['id']),
    cotizacionId:   _parseInt(j['cotizacionId']),
    estado:         j['estado'] as String,
    totalValor:     _parseDouble(j['totalValor']),
    saldoPendiente: _parseDouble(j['saldoPendiente']),
    createdAt:      DateTime.parse(j['createdAt'] as String),
    updatedAt:      j['updatedAt'] != null
        ? DateTime.parse(j['updatedAt'] as String)
        : null,
    cotizacion: j['cotizacion'] != null
        ? Cotizacion.fromJson(j['cotizacion'] as Map<String, dynamic>)
        : null,
    abonos: (j['abonos'] as List<dynamic>?)
            ?.map((e) => Abono.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  EstadoReserva get estadoEnum => _estadoReservaFromString(estado);
  String get estadoLabel => _estadoReservaToLabel(estadoEnum);
  
  String _estadoReservaToLabel(EstadoReserva e) => switch (e) {
  EstadoReserva.pendiente   => 'Pendiente',
  EstadoReserva.confirmada  => 'Confirmada',
  EstadoReserva.anulada     => 'Anulada',
  EstadoReserva.finalizado  => 'Finalizado',
};
}

// ─── COTIZACIÓN ───────────────────────────────────────────────────────────────

class Cotizacion {
  final int id;
  final int? clienteId;
  final String nombreHomenajeado;
  final TipoEvento tipoEvento;
  final DateTime fechaEvento;
  final DateTime horaInicio;
  final DateTime horaFin;
  final String direccionEvento;
  final String? notasAdicionales;
  final double? totalEstimado;
  final bool esReservaDirecta;
  EstadoCotizacion estado;
  final DateTime createdAt;
  final String? contactoEmail;
  final String? contactoNombre;
  final String? contactoTelefono;
  final String? contactoTelefono2;
  final Cliente? cliente;
  final List<CotizacionServicio> servicios;
  final List<CotizacionRepertorio> repertorios;
  final Reserva? reserva;

  Cotizacion({
    required this.id,
    this.clienteId,
    required this.nombreHomenajeado,
    required this.tipoEvento,
    required this.fechaEvento,
    required this.horaInicio,
    required this.horaFin,
    required this.direccionEvento,
    this.notasAdicionales,
    this.totalEstimado,
    required this.esReservaDirecta,
    required this.estado,
    required this.createdAt,
    this.contactoEmail,
    this.contactoNombre,
    this.contactoTelefono,
    this.contactoTelefono2,
    this.cliente,
    this.servicios = const [],
    this.repertorios = const [],
    this.reserva,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> j) => Cotizacion(
    id:               _parseInt(j['id']),
    clienteId:        _parseIntNull(j['clienteId']),
    nombreHomenajeado: j['nombreHomenajeado'] as String,
    tipoEvento:       _tipoEventoFromString(j['tipoEvento'] as String),
    fechaEvento:      DateTime.parse(j['fechaEvento'] as String),
    horaInicio:       DateTime.parse(j['horaInicio'] as String),
    horaFin:          DateTime.parse(j['horaFin'] as String),
    direccionEvento:  j['direccionEvento'] as String,
    notasAdicionales: j['notasAdicionales'] as String?,
    totalEstimado:    _parseDoubleNull(j['totalEstimado']),
    esReservaDirecta: j['esReservaDirecta'] as bool? ?? false,
    estado:           _estadoCotizacionFromString(j['estado'] as String),
    createdAt:        DateTime.parse(j['createdAt'] as String),
    contactoEmail:    j['contactoEmail'] as String?,
    contactoNombre:   j['contactoNombre'] as String?,
    contactoTelefono: j['contactoTelefono'] as String?,
    contactoTelefono2: j['contactoTelefono2'] as String?,
    cliente: j['cliente'] != null
        ? Cliente.fromJson(j['cliente'] as Map<String, dynamic>)
        : null,
    servicios: (j['servicios'] as List<dynamic>?)
            ?.map((e) => CotizacionServicio.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
    repertorios: (j['repertorios'] as List<dynamic>?)
            ?.map((e) => CotizacionRepertorio.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
    reserva: j['reserva'] != null
        ? Reserva.fromJson(j['reserva'] as Map<String, dynamic>)
        : null,
  );

  Cotizacion copyWith({EstadoCotizacion? estado}) => Cotizacion(
    id: id, clienteId: clienteId, nombreHomenajeado: nombreHomenajeado,
    tipoEvento: tipoEvento, fechaEvento: fechaEvento, horaInicio: horaInicio,
    horaFin: horaFin, direccionEvento: direccionEvento,
    notasAdicionales: notasAdicionales, totalEstimado: totalEstimado,
    esReservaDirecta: esReservaDirecta, estado: estado ?? this.estado,
    createdAt: createdAt, contactoEmail: contactoEmail,
    contactoNombre: contactoNombre, contactoTelefono: contactoTelefono,
    contactoTelefono2: contactoTelefono2, cliente: cliente,
    servicios: servicios, repertorios: repertorios, reserva: reserva,
  );

  String get clienteNombre =>
      cliente?.nombreCompleto ?? contactoNombre ?? 'Cliente no especificado';
  String get tipoEventoLabel => _tipoEventoToLabel(tipoEvento);
  String get estadoLabel     => _estadoCotizacionToLabel(estado);
  bool get puedeConvertirse  =>
      estado == EstadoCotizacion.enEspera &&
      totalEstimado != null && totalEstimado! > 0;
  bool get puedeAnularse   => estado == EstadoCotizacion.enEspera;
  bool get puedeEliminarse => reserva == null;
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

  const Ensayo({
    required this.id,
    required this.nombre,
    required this.fechaHora,
    required this.lugar,
    this.ubicacion,
    required this.estado,
    this.repertorios = const [],
  });

  factory Ensayo.fromJson(Map<String, dynamic> j) => Ensayo(
    id:          _parseInt(j['id']),
    nombre:      j['nombre'] as String,
    fechaHora:   DateTime.parse(j['fechaHora'] as String),
    lugar:       j['lugar'] as String,
    ubicacion:   j['ubicacion'] as String?,
    estado:      _estadoEnsayoFromString(j['estado'] as String? ?? 'PENDIENTE'),
    repertorios: (j['repertorios'] as List<dynamic>?)
            ?.map((e) {
              final data = e['repertorio'] ?? e;
              return Repertorio.fromJson(data as Map<String, dynamic>);
            })
            .toList() ?? [],
  );

  String get estadoLabel => estado == EstadoEnsayo.listo ? 'listo' : 'pendiente';
}

// ─── ENUM HELPERS ─────────────────────────────────────────────────────────────

EstadoCotizacion _estadoCotizacionFromString(String s) => switch (s) {
  'CONVERTIDA' => EstadoCotizacion.convertida,
  'ANULADA'    => EstadoCotizacion.anulada,
  _            => EstadoCotizacion.enEspera,
};

String _estadoCotizacionToLabel(EstadoCotizacion e) => switch (e) {
  EstadoCotizacion.enEspera   => 'En Espera',
  EstadoCotizacion.convertida => 'Convertida',
  EstadoCotizacion.anulada    => 'Anulada',
};

EstadoReserva _estadoReservaFromString(String s) => switch (s) {
  'CONFIRMADA' => EstadoReserva.confirmada,
  'ANULADA'    => EstadoReserva.anulada,
  'FINALIZADO' => EstadoReserva.finalizado,
  _            => EstadoReserva.pendiente,
};

EstadoEnsayo _estadoEnsayoFromString(String s) => switch (s) {
  'LISTO' => EstadoEnsayo.listo,
  _       => EstadoEnsayo.pendiente,
};

TipoEvento _tipoEventoFromString(String s) => switch (s) {
  'BODA'           => TipoEvento.boda,
  'CUMPLEANOS'     => TipoEvento.cumpleanos,
  'QUINCEANIOS'    => TipoEvento.quinceanios,
  'FUNERAL'        => TipoEvento.funeral,
  'RECONCILIACION' => TipoEvento.reconciliacion,
  'DIA_DE_MADRE'   => TipoEvento.diaDeMadre,
  'AMOR'           => TipoEvento.amor,
  'ANIVERSARIO'    => TipoEvento.aniversario,
  'PADRES'         => TipoEvento.padres,
  'FIESTA'         => TipoEvento.fiesta,
  _                => TipoEvento.otro,
};

String _tipoEventoToLabel(TipoEvento t) => switch (t) {
  TipoEvento.boda           => 'Boda',
  TipoEvento.cumpleanos     => 'Cumpleaños',
  TipoEvento.quinceanios    => 'Quinceaños',
  TipoEvento.funeral        => 'Funeral',
  TipoEvento.reconciliacion => 'Reconciliación',
  TipoEvento.diaDeMadre     => 'Día de la Madre',
  TipoEvento.amor           => 'Amor',
  TipoEvento.aniversario    => 'Aniversario',
  TipoEvento.padres         => 'Día del Padre',
  TipoEvento.fiesta         => 'Fiesta',
  TipoEvento.otro           => 'Otro',
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
    id:         _parseInt(j['id']),
    titulo:     j['titulo'] as String,
    artista:    j['artista'] as String,
    genero:     j['genero'] as String,
    categoria:  j['categoria'] as String,
    duracion:   j['duracion'] as String,
    dificultad: j['dificultad'] as String? ?? '',
    portada:    j['portada'] as String?,
    audioUrl:   j['audioUrl'] as String?,
    letra:      j['letra'] as String?,
    activa:     j['activa'] as bool? ?? true,
  );

  Cancion copyWith({bool? activa}) => Cancion(
    id: id, titulo: titulo, artista: artista, genero: genero,
    categoria: categoria, duracion: duracion, dificultad: dificultad,
    portada: portada, audioUrl: audioUrl, letra: letra,
    activa: activa ?? this.activa,
  );
}