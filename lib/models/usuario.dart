class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String? telefono;
  final String correoElectronico;
  final String rol; // 'user' | 'admin_cancha'

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.telefono,
    required this.correoElectronico,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      telefono: json['telefono'] as String?,
      correoElectronico: json['correo_electronico'] as String,
      rol: json['rol'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'correo_electronico': correoElectronico,
      'rol': rol,
    };
  }
}
