class Cotizacion {
  final int id;
  final String nombreHomenajeado;
  final String tipoEvento;
  final DateTime fechaEvento;
  final DateTime horaInicio;
  final DateTime horaFin;
  final String direccionEvento;
  final String? notasAdicionales;
  final double? totalEstimado;
  final String estado;
  final String? contactoEmail;
  final String? contactoNombre;
  final String? contactoTelefono;
  final Cliente? cliente;
  final List<Repertorio> repertorios;
  final List<Servicio> servicios;

  Cotizacion({
    required this.id,
    required this.nombreHomenajeado,
    required this.tipoEvento,
    required this.fechaEvento,
    required this.horaInicio,
    required this.horaFin,
    required this.direccionEvento,
    this.notasAdicionales,
    this.totalEstimado,
    required this.estado,
    this.contactoEmail,
    this.contactoNombre,
    this.contactoTelefono,
    this.cliente,
    required this.repertorios,
    required this.servicios,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) {
    return Cotizacion(
      id: json['id'] as int,
      nombreHomenajeado: json['nombreHomenajeado'] as String,
      tipoEvento: json['tipoEvento'] as String,
      fechaEvento: DateTime.parse(json['fechaEvento'] as String),
      horaInicio: DateTime.parse(json['horaInicio'] as String),
      horaFin: DateTime.parse(json['horaFin'] as String),
      direccionEvento: json['direccionEvento'] as String,
      notasAdicionales: json['notasAdicionales'] as String?,
      totalEstimado: json['totalEstimado'] != null
          ? double.tryParse(json['totalEstimado'].toString())
          : null,
      estado: json['estado'] as String,
      contactoEmail: json['contactoEmail'] as String?,
      contactoNombre: json['contactoNombre'] as String?,
      contactoTelefono: json['contactoTelefono'] as String?,
      cliente: json['cliente'] != null
          ? Cliente.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      repertorios: (json['repertorios'] as List<dynamic>?)
              ?.map((e) => Repertorio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      servicios: (json['servicios'] as List<dynamic>?)
              ?.map((e) => Servicio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Cliente {
  final int id;
  final String apellido;
  final String email;
  final String telefonoPrincipal;

  Cliente({
    required this.id,
    required this.apellido,
    required this.email,
    required this.telefonoPrincipal,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefonoPrincipal: json['telefonoPrincipal'] as String,
    );
  }
}

class Repertorio {
  final int id;
  final String titulo;
  final String artista;
  final String genero;
  final String categoria;
  final String duracion;
  final String dificultad;
  final String? portada;

  Repertorio({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.genero,
    required this.categoria,
    required this.duracion,
    required this.dificultad,
    this.portada,
  });

  factory Repertorio.fromJson(Map<String, dynamic> json) {
    return Repertorio(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      artista: json['artista'] as String,
      genero: json['genero'] as String,
      categoria: json['categoria'] as String,
      duracion: json['duracion'] as String,
      dificultad: json['dificultad'] as String,
      portada: json['portada'] as String?,
    );
  }
}

class Servicio {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int cantidad;

  Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.cantidad,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      cantidad: json['cantidad'] as int? ?? 1,
    );
  }
}

class Abono {
  final int id;
  final double monto;
  final DateTime fechaPago;
  final String metodoPago;
  final double nuevoSaldo;
  final String? notas;

  Abono({
    required this.id,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    required this.nuevoSaldo,
    this.notas,
  });

  factory Abono.fromJson(Map<String, dynamic> json) {
    return Abono(
      id: json['id'] as int,
      monto: double.tryParse(json['monto'].toString()) ?? 0.0,
      fechaPago: DateTime.parse(json['fechaPago'] as String),
      metodoPago: json['metodoPago'] as String,
      nuevoSaldo: double.tryParse(json['nuevoSaldo'].toString()) ?? 0.0,
      notas: json['notas'] as String?,
    );
  }
}

class Reserva {
  final int id;
  final int cotizacionId;
  final String estado;
  final double? totalValor;
  final double? saldoPendiente;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Cotizacion? cotizacion;
  final List<Abono> abonos;

  Reserva({
    required this.id,
    required this.cotizacionId,
    required this.estado,
    this.totalValor,
    this.saldoPendiente,
    required this.createdAt,
    this.updatedAt,
    this.cotizacion,
    required this.abonos,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Reserva.fromJson: Parseando reserva');
      return Reserva(
        id: json['id'] as int,
        cotizacionId: json['cotizacionId'] as int,
        estado: json['estado'] as String,
        totalValor: json['totalValor'] != null
            ? double.tryParse(json['totalValor'].toString()) ?? 0.0
            : null,
        saldoPendiente: json['saldoPendiente'] != null
            ? double.tryParse(json['saldoPendiente'].toString()) ?? 0.0
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        cotizacion: json['cotizacion'] != null
            ? Cotizacion.fromJson(json['cotizacion'] as Map<String, dynamic>)
            : null,
        abonos: (json['abonos'] as List<dynamic>?)
                ?.map((e) => Abono.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      print('❌ Reserva.fromJson: Error: $e');
      print('❌ Reserva.fromJson: JSON: $json');
      rethrow;
    }
  }

  String get estadoLabel => estado;
}
