import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/reserva.dart';
import '../../models/escenario.dart';
import '../../services/auth_service.dart';
import '../../services/venues_service.dart';
import '../../theme/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  List<Reserva> _allReservas = [];
  List<Reserva> _filteredReservas = [];
  List<Escenario> _myVenues = [];

  int _canchasCount = 0;
  int _pendientesCount = 0;
  int _confirmadasCount = 0;
  double _ingresosEstimados = 0.0;

  // Filters
  String _statusFilter = ''; // '' = Todos, 'pendiente', 'confirmada', 'completada', 'cancelada'
  int _venueFilter = 0; // 0 = Todas

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
      final role = await AuthService.instance.getUserRole();
      if (role != 'admin_cancha') {
        if (!mounted) return;
        context.go('/dashboard/user');
        return;
      }

      // Cargar mis canchas y mis reservas recibidas
      final venues = await VenuesService.instance.getMisEscenarios();
      final reservas = await VenuesService.instance.getReservasAdmin();

      int pending = 0;
      int confirmed = 0;
      double earnings = 0.0;

      for (var r in reservas) {
        if (r.estado == 'pendiente') {
          pending++;
        } else if (r.estado == 'confirmada') {
          confirmed++;
        }
        
        // Sumar ingresos de confirmadas o completadas
        if (r.estado == 'confirmada' || r.estado == 'completada') {
          final price = r.escenario?.precio ?? 0.0;
          
          // Calcular horas de duración
          try {
            final start = TimeOfDay(
              hour: int.parse(r.horaInicio.split(':')[0]),
              minute: int.parse(r.horaInicio.split(':')[1]),
            );
            final end = TimeOfDay(
              hour: int.parse(r.horaFin.split(':')[0]),
              minute: int.parse(r.horaFin.split(':')[1]),
            );
            final double startMin = start.hour * 60.0 + start.minute;
            final double endMin = end.hour * 60.0 + end.minute;
            final duration = (endMin - startMin) / 60.0;
            earnings += (duration > 0 ? duration : 1.0) * price;
          } catch (_) {
            earnings += price; // Fallback a 1 hora si falla el parseo
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _myVenues = venues;
        _canchasCount = venues.length;
        _allReservas = reservas;
        _filteredReservas = reservas;
        _pendientesCount = pending;
        _confirmadasCount = confirmed;
        _ingresosEstimados = earnings;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de administración: ${e.toString()}')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReservas = _allReservas.where((r) {
        final matchesStatus = _statusFilter.isEmpty || r.estado == _statusFilter;
        final matchesVenue = _venueFilter == 0 || r.escenarioId == _venueFilter;
        return matchesStatus && matchesVenue;
      }).toList();
    });
  }

  Future<void> _updateBookingStatus(int reservaId, String newStatus) async {
    try {
      await VenuesService.instance.updateReservaEstado(reservaId, newStatus);
      await _checkAuthAndLoadData();
      _applyFilters();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reserva actualizada a "$newStatus".'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: ${e.toString()}')),
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

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingSide = size.width > 900 ? 60 : 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin/venues'),
            icon: const Icon(Icons.edit_road, color: AppTheme.primaryColor),
            label: const Text('Mis Canchas', style: TextStyle(color: AppTheme.primaryColor)),
          ),
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '🏟️ DASHBOARD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Control de Reservas',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gestiona las solicitudes de tus escenarios deportivos.',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/admin/venues'),
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir Cancha'),
                        ),
                      ],
                    ),
                  ),

                  // Tarjetas de Estadísticas
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingSide),
                    child: GridView.count(
                      crossAxisCount: size.width > 900 ? 4 : (size.width > 550 ? 2 : 1),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: [
                        _buildStatCard(Icons.sports_soccer, AppTheme.primaryColor, 'Mis Canchas', _canchasCount.toString()),
                        _buildStatCard(Icons.pending_actions, AppTheme.accentColor, 'Pendientes', _pendientesCount.toString()),
                        _buildStatCard(Icons.check_circle_outline, AppTheme.secondaryColor, 'Confirmadas', _confirmadasCount.toString()),
                        _buildStatCard(Icons.monetization_on_outlined, Colors.green, 'Ingresos Est.', _formatCurrency(_ingresosEstimados)),
                      ],
                    ),
                  ),

                  // Sección de filtros y tabla de reservas
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingSide, vertical: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reservas Recibidas',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white60),
                                onPressed: _checkAuthAndLoadData,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Filtros de estado y canchas
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              DropdownButton<String>(
                                value: _statusFilter,
                                dropdownColor: AppTheme.surfaceColor,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: '', child: Text('Todos los estados')),
                                  DropdownMenuItem(value: 'pendiente', child: Text('🟡 Pendiente')),
                                  DropdownMenuItem(value: 'confirmada', child: Text('🔵 Confirmada')),
                                  DropdownMenuItem(value: 'completada', child: Text('🟢 Completada')),
                                  DropdownMenuItem(value: 'cancelada', child: Text('🔴 Cancelada')),
                                ],
                                onChanged: (val) {
                                  setState(() => _statusFilter = val ?? '');
                                  _applyFilters();
                                },
                              ),
                              DropdownButton<int>(
                                value: _venueFilter,
                                dropdownColor: AppTheme.surfaceColor,
                                style: const TextStyle(color: Colors.white),
                                items: [
                                  const DropdownMenuItem(value: 0, child: Text('Todas las canchas')),
                                  ..._myVenues.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nombre))),
                                ],
                                onChanged: (val) {
                                  setState(() => _venueFilter = val ?? 0);
                                  _applyFilters();
                                },
                              ),
                              Text(
                                'Encontradas: ${_filteredReservas.length}',
                                style: const TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Listado de Reservas
                          if (_filteredReservas.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Center(
                                child: Text('No hay reservas registradas con estos filtros.', style: TextStyle(color: Colors.white38)),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredReservas.length,
                              itemBuilder: (context, index) {
                                final r = _filteredReservas[index];
                                final clientName = r.usuarioInfo != null
                                    ? '${r.usuarioInfo!['nombre']} ${r.usuarioInfo!['apellido']}'
                                    : 'Deportista';
                                final clientPhone = r.usuarioInfo?['telefono'] ?? 'Sin teléfono';

                                return Card(
                                  color: AppTheme.backgroundColor,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r.escenario?.nombre ?? 'Cancha',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Cliente: $clientName ($clientPhone)',
                                                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(r.estado).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: _getStatusColor(r.estado)),
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
                                                const Text('FECHA / HORARIO', style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text('${r.fecha}  |  ${r.horaInicio.substring(0, 5)} - ${r.horaFin.substring(0, 5)}', style: const TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('PAGO / PRECIO', style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text(r.metodoPago?.toUpperCase() ?? 'EFECTIVO', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        
                                        // Acciones del Admin
                                        if (r.estado == 'pendiente' || r.estado == 'confirmada') ...[
                                          const Divider(color: Colors.white10, height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              if (r.estado == 'pendiente')
                                                TextButton.icon(
                                                  onPressed: () => _updateBookingStatus(r.id, 'confirmada'),
                                                  icon: const Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
                                                  label: const Text('Confirmar', style: TextStyle(color: AppTheme.primaryColor)),
                                                ),
                                              if (r.estado == 'confirmada')
                                                TextButton.icon(
                                                  onPressed: () => _updateBookingStatus(r.id, 'completada'),
                                                  icon: const Icon(Icons.done_all, size: 16, color: Colors.green),
                                                  label: const Text('Completar', style: TextStyle(color: Colors.green)),
                                                ),
                                              const SizedBox(width: 12),
                                              TextButton.icon(
                                                onPressed: () => _updateBookingStatus(r.id, 'cancelada'),
                                                icon: const Icon(Icons.cancel, size: 16, color: Colors.redAccent),
                                                label: const Text('Rechazar / Cancelar', style: TextStyle(color: Colors.redAccent)),
                                              ),
                                            ],
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

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(IconData icon, Color iconColor, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
