import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escenario.dart';
import '../models/reserva.dart';

class VenuesService {
  final SupabaseClient _client = Supabase.instance.client;

  // Patrón Singleton
  VenuesService._internal();
  static final VenuesService instance = VenuesService._internal();

  User? get _currentUser => _client.auth.currentUser;

  /// Obtiene todos los escenarios ordenados por ID
  Future<List<Escenario>> getEscenarios() async {
    final List<dynamic> response = await _client
        .from('escenarios')
        .select('*')
        .order('id');
    return response.map((json) => Escenario.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Crea una nueva reserva para el usuario actual
  Future<void> insertReserva({
    required int escenarioId,
    required String fecha,
    required String horaInicio,
    required String horaFin,
    String? metodoPago,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('No hay sesión activa.');

    await _client.from('reservas').insert({
      'usuario_id': user.id,
      'escenario_id': escenarioId,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'estado': 'pendiente',
      'metodo_pago': metodoPago ?? 'efectivo',
    });
  }

  /// Obtiene las reservas del usuario actual (con información de escenarios)
  Future<List<Reserva>> getMisReservas() async {
    final user = _currentUser;
    if (user == null) return [];

    final List<dynamic> response = await _client
        .from('reservas')
        .select('''
          id,
          usuario_id,
          escenario_id,
          fecha,
          hora_inicio,
          hora_fin,
          estado,
          metodo_pago,
          escenarios ( id, nombre, tipo, ubicacion, precio )
        ''')
        .eq('usuario_id', user.id)
        .order('fecha', ascending: false);

    return response.map((json) => Reserva.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Obtiene los escenarios que pertenecen al administrador actual
  Future<List<Escenario>> getMisEscenarios() async {
    final user = _currentUser;
    if (user == null) return [];

    final List<dynamic> response = await _client
        .from('escenarios')
        .select('*')
        .eq('propietario_id', user.id)
        .order('id');

    return response.map((json) => Escenario.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Crea un nuevo escenario asignando al usuario actual como propietario
  Future<void> insertEscenario(Map<String, dynamic> escenarioData) async {
    final user = _currentUser;
    if (user == null) throw Exception('No hay sesión activa.');

    final payload = {
      ...escenarioData,
      'propietario_id': user.id,
    };

    await _client.from('escenarios').insert(payload);
  }

  /// Actualiza un escenario existente
  Future<void> updateEscenario(int id, Map<String, dynamic> updates) async {
    await _client.from('escenarios').update(updates).eq('id', id);
  }

  /// Elimina un escenario
  Future<void> deleteEscenario(int id) async {
    await _client.from('escenarios').delete().eq('id', id);
  }

  /// Cancela una reserva propia
  Future<void> cancelReserva(int reservaId) async {
    final user = _currentUser;
    if (user == null) throw Exception('No hay sesión activa.');

    await _client
        .from('reservas')
        .update({'estado': 'cancelada'})
        .eq('id', reservaId)
        .eq('usuario_id', user.id);
  }

  /// Obtiene todas las reservas de los escenarios del administrador actual
  Future<List<Reserva>> getReservasAdmin() async {
    final user = _currentUser;
    if (user == null) return [];

    // Paso 1: Obtener los escenarios del admin
    final List<dynamic> escenariosData = await _client
        .from('escenarios')
        .select('id')
        .eq('propietario_id', user.id);

    if (escenariosData.isEmpty) return [];
    final List<int> idsEscenarios = escenariosData.map((e) => e['id'] as int).toList();

    // Paso 2: Obtener reservas asociadas a esos escenarios
    final List<dynamic> reservasData = await _client
        .from('reservas')
        .select('''
          id,
          usuario_id,
          escenario_id,
          fecha,
          hora_inicio,
          hora_fin,
          estado,
          metodo_pago,
          escenarios ( id, nombre, tipo, precio )
        ''')
        .inFilter('escenario_id', idsEscenarios)
        .order('fecha', ascending: false);

    if (reservasData.isEmpty) return [];

    // Paso 3: Obtener información de los usuarios deportistas que reservaron
    final List<String> userIds = reservasData
        .map((r) => r['usuario_id'] as String)
        .toSet()
        .toList();

    Map<String, Map<String, dynamic>> usersMap = {};
    if (userIds.isNotEmpty) {
      try {
        final List<dynamic> usersData = await _client
            .from('usuarios')
            .select('id, nombre, apellido, correo_electronico, telefono')
            .inFilter('id', userIds);
        
        for (var u in usersData) {
          usersMap[u['id'] as String] = u as Map<String, dynamic>;
        }
      } catch (_) {
        // Ignorar si hay algún problema consultando usuarios
      }
    }

    // Paso 4: Combinar datos
    final List<Reserva> reservasCompletas = [];
    for (var r in reservasData) {
      final Map<String, dynamic> rMap = Map<String, dynamic>.from(r as Map);
      final String uId = rMap['usuario_id'] as String;
      if (usersMap.containsKey(uId)) {
        rMap['usuarios'] = usersMap[uId];
      }
      reservasCompletas.add(Reserva.fromJson(rMap));
    }

    return reservasCompletas;
  }

  /// Actualiza el estado de una reserva (Confirmar / Rechazar, etc.)
  Future<void> updateReservaEstado(int reservaId, String estado) async {
    await _client.from('reservas').update({'estado': estado}).eq('id', reservaId);
  }
}
