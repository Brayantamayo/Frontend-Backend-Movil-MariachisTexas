class Cliente {
  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String email;
  final bool activo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.email,
    required this.activo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    // El nombre viene del usuario relacionado
    final usuario = json['usuario'] as Map<String, dynamic>?;
    return Cliente(
      id: json['id']?.toString() ?? '',
      nombre: usuario?['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      telefono: json['telefonoPrincipal']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      activo: json['activo'] as bool? ?? true,
    );
  }
}