class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String email;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}