import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Patrón Singleton
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  /// Inicia sesión con email y contraseña, luego recupera el perfil del usuario
  Future<Usuario> loginUser(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Autenticación fallida: el servidor no retornó un usuario.');
    }

    return await getUserProfile(response.user!.id);
  }

  /// Registra un nuevo usuario en Supabase Auth
  Future<User?> registerUserAuth({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nombre': nombre,
        'apellido': apellido,
      },
    );
    return response.user;
  }

  /// Inserta el perfil del usuario en la tabla 'usuarios' de la base de datos
  Future<void> insertUserProfile({
    required String userId,
    required String email,
    required String nombre,
    required String apellido,
    String? telefono,
    required String rol,
  }) async {
    await _client.from('usuarios').insert({
      'id': userId,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'correo_electronico': email,
      'rol': rol,
    });
  }

  /// Obtiene los detalles de perfil de un usuario por su ID
  Future<Usuario> getUserProfile(String userId) async {
    final data = await _client
        .from('usuarios')
        .select('id, nombre, apellido, telefono, correo_electronico, rol')
        .eq('id', userId)
        .single();
    
    return Usuario.fromJson(data);
  }

  /// Obtiene el rol del usuario actualmente autenticado
  Future<String?> getUserRole() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await _client
          .from('usuarios')
          .select('rol')
          .eq('id', userId)
          .single();
      return data['rol'] as String?;
    } catch (_) {
      return 'user'; // Rol por defecto si no se encuentra
    }
  }

  /// Cierra la sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
