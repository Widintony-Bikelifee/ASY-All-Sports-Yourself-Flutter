import 'escenario.dart';

class Reserva {
  final int id;
  final String usuarioId;
  final int escenarioId;
  final String fecha; // 'YYYY-MM-DD'
  final String horaInicio; // 'HH:MM:SS'
  final String horaFin; // 'HH:MM:SS'
  final String estado; // 'pendiente' | 'confirmada' | 'cancelada' | 'completada'
  final String? metodoPago;
  final Escenario? escenario;
  final Map<String, dynamic>? usuarioInfo; // Para detalles del usuario deportista (join)

  Reserva({
    required this.id,
    required this.usuarioId,
    required this.escenarioId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    this.metodoPago,
    this.escenario,
    this.usuarioInfo,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as int,
      usuarioId: json['usuario_id'] as String,
      escenarioId: json['escenario_id'] as int,
      fecha: json['fecha'] as String,
      horaInicio: json['hora_inicio'] as String,
      horaFin: json['hora_fin'] as String,
      estado: json['estado'] as String,
      metodoPago: json['metodo_pago'] as String?,
      escenario: json['escenarios'] != null
          ? Escenario.fromJson(json['escenarios'] as Map<String, dynamic>)
          : null,
      usuarioInfo: json['usuarios'] != null
          ? json['usuarios'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'usuario_id': usuarioId,
      'escenario_id': escenarioId,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'estado': estado,
      if (metodoPago != null) 'metodo_pago': metodoPago,
    };
  }
}
