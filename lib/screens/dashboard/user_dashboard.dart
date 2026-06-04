import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/reserva.dart';
import '../../services/auth_service.dart';
import '../../services/venues_service.dart';
import '../../theme/theme.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  bool _isLoading = true;
  List<Reserva> _reservas = [];
  int _proximosPartidosCount = 0;
  int _partidosJugadosCount = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    try {
      // Validar rol
      final role = await AuthService.instance.getUserRole();
      if (role == 'admin_cancha') {
        if (!mounted) return;
        context.go('/dashboard/admin');
        return;
      }

      // Cargar datos
      final profile = await AuthService.instance.getUserProfile(user.id);
      final reservasData = await VenuesService.instance.getMisReservas();

      int upcoming = 0;
      int completed = 0;

      for (var r in reservasData) {
        if (r.estado == 'pendiente' || r.estado == 'confirmada') {
          upcoming++;
        } else if (r.estado == 'completada') {
          completed++;
        }
      }

      if (!mounted) return;
      setState(() {
        _userName = profile.nombre;
        _reservas = reservasData;
        _proximosPartidosCount = upcoming;
        _partidosJugadosCount = completed;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del panel: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelBooking(int reservaId) async {
    // Diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar Reserva?'),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await VenuesService.instance.cancelReserva(reservaId);
      // Recargar datos
      await _checkAuthAndLoadData();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada exitosamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar reserva: ${e.toString()}')),
      );
    }
  }

  Color _getStatusColor(String state) {
    switch (state) {
      case 'pendiente':
        return AppTheme.accentColor;
      case 'confirmada':
        return AppTheme.primaryColor;
      case 'cancelada':
        return Colors.redAccent;
      case 'completada':
        return AppTheme.secondaryColor;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingSide = size.width > 900 ? 60 : 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Deportista'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (!mounted) return;
              context.go('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingSide, vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '🏅 DEPORTISTA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mi Actividad, $_userName',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Revisa tus próximas reservas y tu historial de juego.',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        if (size.width > 600)
                          ElevatedButton.icon(
                            onPressed: () => context.go('/venues'),
                            icon: const Icon(Icons.add),
                            label: const Text('Nueva Reserva'),
                          ),
                      ],
                    ),
                  ),

                  // Mobile Floating CTA
                  if (size.width <= 600)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: paddingSide, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/venues'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva Reserva'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      ),
                    ),

                  // Tarjetas de Estadísticas
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingSide, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.upcoming,
                            iconColor: AppTheme.secondaryColor,
                            label: 'Próximos Partidos',
                            value: _proximosPartidosCount.toString(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle_outline,
                            iconColor: AppTheme.primaryColor,
                            label: 'Partidos Jugados',
                            value: _partidosJugadosCount.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de Reservas
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingSide, vertical: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mis Reservas',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            if (_reservas.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Text(
                                    'No has realizado ninguna reserva aún.',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _reservas.length,
                                itemBuilder: (context, index) {
                                  final r = _reservas[index];
                                  final canCancel = r.estado == 'pendiente' || r.estado == 'confirmada';
                                  final nombreCancha = r.escenario?.nombre ?? 'Cancha';
                                  final tipoCancha = r.escenario?.tipo ?? '';
                                  
                                  return Card(
                                    color: AppTheme.backgroundColor,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text('🏟️', style: TextStyle(fontSize: 18)),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        nombreCancha,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        tipoCancha,
                                                        style: const TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(r.estado).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _getStatusColor(r.estado),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  r.estado.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(r.estado),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(color: Colors.white10, height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'FECHA Y HORA',
                                                    style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${r.fecha}  |  ${r.horaInicio.substring(0, 5)} - ${r.horaFin.substring(0, 5)}',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  const Text(
                                                    'PAGO / DETALLE',
                                                    style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    r.metodoPago?.toUpperCase() ?? 'EFECTIVO',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (canCancel) ...[
                                            const SizedBox(height: 16),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(
                                                onPressed: () => _cancelBooking(r.id),
                                                icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                                                label: const Text('Cancelar Reserva', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
