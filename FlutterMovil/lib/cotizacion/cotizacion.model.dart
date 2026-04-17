enum EstadoCotizacion { enEspera, convertida, anulada }

enum TipoEvento {
  boda,
  cumpleanos,
  quinceanios,
  funeral,
  reconciliacion,
  diaDeMadre,
  otro,
  amor,
  aniversario,
  padres,
  fiesta
}

class Cliente {
  final int id;
  final String apellido;
  final String? email;
  final String? telefonoPrincipal;
  final String? telefonoAlternativo;
  final String? direccion;
  final String? ciudad;
  final Usuario usuario;

  Cliente({
    required this.id,
    required this.apellido,
    this.email,
    this.telefonoPrincipal,
    this.telefonoAlternativo,
    this.direccion,
    this.ciudad,
    required this.usuario,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      apellido: json['apellido'] as String,
      email: json['email'] as String?,
      telefonoPrincipal: json['telefonoPrincipal'] as String?,
      telefonoAlternativo: json['telefonoAlternativo'] as String?,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String?,
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }

  String get nombreCompleto => '${usuario.nombre} $apellido';
}

class Usuario {
  final String nombre;

  Usuario({required this.nombre});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(nombre: json['nombre'] as String);
  }
}

class Servicio {
  final int? id;
  final String nombre;
  final String? descripcion;
  final double precio;

  Servicio({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    try {
      print(
          '🔍 Servicio.fromJson: Parseando servicio - precio = ${json['precio']} (${json['precio'].runtimeType})');
      return Servicio(
        id: json['id'] as int?,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        precio: json['precio'] != null
            ? double.tryParse(json['precio'].toString()) ?? 0.0
            : 0.0,
      );
    } catch (e) {
      print('❌ Servicio.fromJson: Error: $e');
      print('❌ Servicio.fromJson: JSON: $json');
      rethrow;
    }
  }
}

class CotizacionServicio {
  final int? id;
  final int? cotizacionId;
  final int? servicioId;
  final Servicio servicio;
  final int cantidad;

  CotizacionServicio({
    this.id,
    this.cotizacionId,
    this.servicioId,
    required this.servicio,
    required this.cantidad,
  });

  factory CotizacionServicio.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 CotizacionServicio.fromJson: Parseando servicio');
      return CotizacionServicio(
        id: json['id'] as int?,
        cotizacionId: json['cotizacionId'] as int?,
        servicioId: json['servicioId'] as int?,
        servicio: Servicio.fromJson(json['servicio'] as Map<String, dynamic>),
        cantidad: json['cantidad'] as int,
      );
    } catch (e) {
      print('❌ CotizacionServicio.fromJson: Error: $e');
      print('❌ CotizacionServicio.fromJson: JSON: $json');
      rethrow;
    }
  }

  double get subtotal => servicio.precio * cantidad;
}

class RepertorioItem {
  final int? id;
  final String titulo;
  final String artista;
  final String? genero;
  final String? duracion;

  RepertorioItem({
    this.id,
    required this.titulo,
    required this.artista,
    this.genero,
    this.duracion,
  });

  factory RepertorioItem.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 RepertorioItem.fromJson: Parseando item de repertorio');
      return RepertorioItem(
        id: json['id'] as int?,
        titulo: json['titulo'] as String,
        artista: json['artista'] as String,
        genero: json['genero'] as String?,
        duracion: json['duracion'] as String?,
      );
    } catch (e) {
      print('❌ RepertorioItem.fromJson: Error: $e');
      print('❌ RepertorioItem.fromJson: JSON: $json');
      rethrow;
    }
  }
}

class CotizacionRepertorio {
  final int? id;
  final int? cotizacionId;
  final int? repertorioId;
  final RepertorioItem repertorio;
  final int orden;

  CotizacionRepertorio({
    this.id,
    this.cotizacionId,
    this.repertorioId,
    required this.repertorio,
    required this.orden,
  });

  factory CotizacionRepertorio.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 CotizacionRepertorio.fromJson: Parseando repertorio');
      return CotizacionRepertorio(
        id: json['id'] as int?,
        cotizacionId: json['cotizacionId'] as int?,
        repertorioId: json['repertorioId'] as int?,
        repertorio:
            RepertorioItem.fromJson(json['repertorio'] as Map<String, dynamic>),
        orden: json['orden'] as int,
      );
    } catch (e) {
      print('❌ CotizacionRepertorio.fromJson: Error: $e');
      print('❌ CotizacionRepertorio.fromJson: JSON: $json');
      rethrow;
    }
  }
}

class Reserva {
  final int id;
  final String estado;
  final double? totalValor;
  final double? saldoPendiente;

  Reserva({
    required this.id,
    required this.estado,
    this.totalValor,
    this.saldoPendiente,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Reserva.fromJson: Parseando reserva');
      print(
          '🔍 Reserva.fromJson: totalValor = ${json['totalValor']} (${json['totalValor'].runtimeType})');
      return Reserva(
        id: json['id'] as int,
        estado: json['estado'] as String,
        totalValor: json['totalValor'] != null
            ? double.tryParse(json['totalValor'].toString()) ?? 0.0
            : null,
        saldoPendiente: json['saldoPendiente'] != null
            ? double.tryParse(json['saldoPendiente'].toString()) ?? 0.0
            : null,
      );
    } catch (e) {
      print('❌ Reserva.fromJson: Error: $e');
      print('❌ Reserva.fromJson: JSON: $json');
      rethrow;
    }
  }
}

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
    required this.servicios,
    required this.repertorios,
    this.reserva,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Cotizacion.fromJson: Iniciando parseo de JSON');
      print('🔍 Cotizacion.fromJson: ID = ${json['id']}');
      print(
          '🔍 Cotizacion.fromJson: totalEstimado = ${json['totalEstimado']} (${json['totalEstimado'].runtimeType})');

      return Cotizacion(
        id: json['id'] as int,
        clienteId: json['clienteId'] as int?,
        nombreHomenajeado: json['nombreHomenajeado'] as String,
        tipoEvento: _tipoEventoFromString(json['tipoEvento'] as String),
        fechaEvento: DateTime.parse(json['fechaEvento'] as String),
        horaInicio: DateTime.parse(json['horaInicio'] as String),
        horaFin: DateTime.parse(json['horaFin'] as String),
        direccionEvento: json['direccionEvento'] as String,
        notasAdicionales: json['notasAdicionales'] as String?,
        totalEstimado: json['totalEstimado'] != null
            ? double.tryParse(json['totalEstimado'].toString()) ?? 0.0
            : null,
        esReservaDirecta: json['esReservaDirecta'] as bool,
        estado: _estadoFromString(json['estado'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        contactoEmail: json['contactoEmail'] as String?,
        contactoNombre: json['contactoNombre'] as String?,
        contactoTelefono: json['contactoTelefono'] as String?,
        contactoTelefono2: json['contactoTelefono2'] as String?,
        cliente: json['cliente'] != null
            ? Cliente.fromJson(json['cliente'] as Map<String, dynamic>)
            : null,
        servicios: _parseServicios(json['servicios'] as List<dynamic>),
        repertorios: _parseRepertorios(json['repertorios'] as List<dynamic>),
        reserva: json['reserva'] != null
            ? Reserva.fromJson(json['reserva'] as Map<String, dynamic>)
            : null,
      );
    } catch (e, stackTrace) {
      print('❌ Cotizacion.fromJson: Error al parsear JSON: $e');
      print('❌ Cotizacion.fromJson: StackTrace: $stackTrace');
      print('❌ Cotizacion.fromJson: JSON completo: $json');
      rethrow;
    }
  }

  static List<CotizacionServicio> _parseServicios(List<dynamic> serviciosJson) {
    try {
      print(
          '🔍 Cotizacion._parseServicios: Parseando ${serviciosJson.length} servicios');
      return serviciosJson
          .map((e) => CotizacionServicio.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Cotizacion._parseServicios: Error: $e');
      print('❌ Cotizacion._parseServicios: JSON: $serviciosJson');
      rethrow;
    }
  }

  static List<CotizacionRepertorio> _parseRepertorios(
      List<dynamic> repertoriosJson) {
    try {
      print(
          '🔍 Cotizacion._parseRepertorios: Parseando ${repertoriosJson.length} repertorios');
      return repertoriosJson
          .map((e) => CotizacionRepertorio.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Cotizacion._parseRepertorios: Error: $e');
      print('❌ Cotizacion._parseRepertorios: JSON: $repertoriosJson');
      rethrow;
    }
  }

  String get clienteNombre {
    if (cliente != null) return cliente!.nombreCompleto;
    if (contactoNombre != null) return contactoNombre!;
    return 'Cliente no especificado';
  }

  String get tipoEventoLabel => _tipoEventoToLabel(tipoEvento);
  String get estadoLabel => _estadoToLabel(estado);

  bool get puedeConvertirse =>
      estado == EstadoCotizacion.enEspera &&
      totalEstimado != null &&
      totalEstimado! > 0;
  bool get puedeAnularse => estado == EstadoCotizacion.enEspera;
  bool get puedeEliminarse => reserva == null;
}

EstadoCotizacion _estadoFromString(String estado) {
  return switch (estado) {
    'EN_ESPERA' => EstadoCotizacion.enEspera,
    'CONVERTIDA' => EstadoCotizacion.convertida,
    'ANULADA' => EstadoCotizacion.anulada,
    _ => EstadoCotizacion.enEspera,
  };
}

String _estadoToLabel(EstadoCotizacion estado) {
  return switch (estado) {
    EstadoCotizacion.enEspera => 'En Espera',
    EstadoCotizacion.convertida => 'Convertida',
    EstadoCotizacion.anulada => 'Anulada',
  };
}

TipoEvento _tipoEventoFromString(String tipo) {
  return switch (tipo) {
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
}

String _tipoEventoToLabel(TipoEvento tipo) {
  return switch (tipo) {
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
}
