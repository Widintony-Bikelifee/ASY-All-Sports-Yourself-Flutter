class Escenario {
  final int id;
  final String nombre;
  final String tipo;
  final double precio;
  final String ubicacion;
  final String? propietarioId;
  final String? imagenUrl;

  Escenario({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.precio,
    required this.ubicacion,
    this.propietarioId,
    this.imagenUrl,
  });

  factory Escenario.fromJson(Map<String, dynamic> json) {
    return Escenario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      precio: (json['precio'] as num).toDouble(),
      ubicacion: json['ubicacion'] as String,
      propietarioId: json['propietario_id'] as String?,
      imagenUrl: json['imagen_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'precio': precio,
      'ubicacion': ubicacion,
      if (propietarioId != null) 'propietario_id': propietarioId,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
    };
  }
}