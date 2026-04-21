class Cancion {
  final int id;
  final String titulo;
  final String artista;
  final String genero;
  final String categoria;
  final String? letra;
  final String? audioUrl;
  final String duracion;
  final String dificultad;
  final String? portada;
  bool activa;

  Cancion({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.genero,
    required this.categoria,
    this.letra,
    this.audioUrl,
    required this.duracion,
    required this.dificultad,
    this.portada,
    required this.activa,
  });

  factory Cancion.fromJson(Map<String, dynamic> json) {
    return Cancion(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      artista: json['artista'] as String,
      genero: json['genero'] as String,
      categoria: json['categoria'] as String,
      letra: json['letra'] as String?,
      audioUrl: json['audioUrl'] as String?,
      duracion: json['duracion'] as String,
      dificultad: json['dificultad'] as String,
      portada: json['portada'] as String?,
      activa: json['activa'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'artista': artista,
        'genero': genero,
        'categoria': categoria,
        'letra': letra,
        'audioUrl': audioUrl,
        'duracion': duracion,
        'dificultad': dificultad,
        'portada': portada,
        'activa': activa,
      };
    Cancion copyWith({bool? activa}) => Cancion(
    id: id,
    titulo: titulo,
    artista: artista,
    genero: genero,
    categoria: categoria,
    letra: letra,
    audioUrl: audioUrl,
    duracion: duracion,
    dificultad: dificultad,
    portada: portada,
    activa: activa ?? this.activa,
  );
}