import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/escenario.dart';
import '../../services/auth_service.dart';
import '../../services/venues_service.dart';
import '../../theme/theme.dart';

class AdminVenuesScreen extends StatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  State<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen> {
  bool _isLoading = true;
  List<Escenario> _myVenues = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadVenues();
  }

  Future<void> _checkAuthAndLoadVenues() async {
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

      final data = await VenuesService.instance.getMisEscenarios();
      if (!mounted) return;
      setState(() {
        _myVenues = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar escenarios: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteVenue(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Cancha?'),
        content: const Text('¿Estás seguro de que deseas eliminar este escenario deportivo? Esta acción cancelará las reservas asociadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await VenuesService.instance.deleteEscenario(id);
      await _checkAuthAndLoadVenues();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escenario eliminado correctamente.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('No se pudo eliminar el escenario: ${e.toString()}');
    }
  }

  void _showVenueFormDialog([Escenario? venue]) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: venue?.nombre ?? '');
    final ubicacionController = TextEditingController(text: venue?.ubicacion ?? '');
    final precioController = TextEditingController(text: venue != null ? venue.precio.toStringAsFixed(0) : '');
    String selectedDeporte = venue != null ? venue.tipo : 'Fútbol';

    final deportes = ['Fútbol', 'Baloncesto', 'Tenis', 'Voleibol', 'Natación', 'Gimnasio'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(venue == null ? 'Añadir Cancha' : 'Editar Cancha'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Nombre de la cancha *'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDeporte,
                        dropdownColor: AppTheme.surfaceColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Tipo de Deporte *'),
                        items: deportes.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedDeporte = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ubicacionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Ubicación *'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: precioController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio por Hora (\$) *'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Obligatorio';
                          if (double.tryParse(value) == null) return 'Ingresa un número válido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context); // Cerrar diálogo

                    setState(() => _isLoading = true);

                    final payload = {
                      'nombre': nombreController.text.trim(),
                      'tipo': selectedDeporte,
                      'ubicacion': ubicacionController.text.trim(),
                      'precio': double.parse(precioController.text),
                    };

                    try {
                      if (venue == null) {
                        await VenuesService.instance.insertEscenario(payload);
                      } else {
                        await VenuesService.instance.updateEscenario(venue.id, payload);
                      }
                      await _checkAuthAndLoadVenues();
                    } catch (e) {
                      setState(() => _isLoading = false);
                      _showError('Error al guardar el escenario: ${e.toString()}');
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
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
        title: const Text('Mis Canchas Publicadas'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard/admin'),
        ),
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
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '🏟️ GESTIÓN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Mis Canchas',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Administra los espacios deportivos que tienes registrados.',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showVenueFormDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir Cancha'),
                        ),
                      ],
                    ),
                  ),

                  // Lista de Canchas
                  if (_myVenues.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('🏟️', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            const Text(
                              'Aún no tienes canchas registradas',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Añade tu primer espacio deportivo para empezar a recibir reservas.',
                              style: TextStyle(color: Colors.white60),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => _showVenueFormDialog(),
                              child: const Text('Crear mi primera cancha'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: paddingSide),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myVenues.length,
                        itemBuilder: (context, index) {
                          final v = _myVenues[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(child: Text('🏟️', style: TextStyle(fontSize: 24))),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.nombre,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${v.tipo}  |  ${v.ubicacion}',
                                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(v.precio) + ' / Hora',
                                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (size.width > 550) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppTheme.secondaryColor),
                                      onPressed: () => _showVenueFormDialog(v),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteVenue(v.id),
                                    ),
                                  ] else
                                    PopupMenuButton<String>(
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showFormDialog(v);
                                        } else if (action == 'delete') {
                                          _deleteVenue(v.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  void _showFormDialog(Escenario v) {
    _showVenueFormDialog(v);
  }
}
