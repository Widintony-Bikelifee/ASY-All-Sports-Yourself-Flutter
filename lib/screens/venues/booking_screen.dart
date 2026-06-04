import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/escenario.dart';
import '../../services/venues_service.dart';
import '../../theme/theme.dart';

class BookingScreen extends StatefulWidget {
  final int escenarioId;
  const BookingScreen({super.key, required this.escenarioId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Escenario? _venue;
  bool _isLoadingVenue = true;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  // Form State
  int _currentStep = 1; // 1 = Fecha y Hora, 2 = Resumen y Pago
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedPaymentMethod = 'efectivo';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadVenue();
  }

  Future<void> _checkAuthAndLoadVenue() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _errorMessage = 'AUTH_REQUIRED';
        _isLoadingVenue = false;
      });
      return;
    }

    try {
      final venues = await VenuesService.instance.getEscenarios();
      final matched = venues.where((v) => v.id == widget.escenarioId).toList();
      if (matched.isNotEmpty) {
        setState(() {
          _venue = matched.first;
          _isLoadingVenue = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Escenario deportivo no encontrado.';
          _isLoadingVenue = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los detalles del escenario.';
        _isLoadingVenue = false;
      });
    }
  }

  // Helpers
  double _calculateDuration() {
    if (_startTime == null || _endTime == null) return 0.0;
    final double startMin = _startTime!.hour * 60.0 + _startTime!.minute;
    final double endMin = _endTime!.hour * 60.0 + _endTime!.minute;
    final double diff = endMin - startMin;
    return diff > 0 ? diff / 60.0 : 0.0;
  }

  double _calculateTotal() {
    if (_venue == null) return 0.0;
    return _calculateDuration() * _venue!.precio;
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Validaciones
  bool _validateStep1() {
    if (_selectedDate == null) {
      _showSnackbar('Por favor selecciona una fecha.', Colors.redAccent);
      return false;
    }
    if (_startTime == null || _endTime == null) {
      _showSnackbar('Por favor selecciona hora de inicio y fin.', Colors.redAccent);
      return false;
    }
    final duration = _calculateDuration();
    if (duration <= 0) {
      _showSnackbar('La hora de fin debe ser posterior a la hora de inicio.', Colors.redAccent);
      return false;
    }
    return true;
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  // Enviar Reserva a Supabase
  Future<void> _submitBooking() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await VenuesService.instance.insertReserva(
        escenarioId: _venue!.id,
        fecha: _formatDate(_selectedDate),
        horaInicio: '${_formatTime(_startTime)}:00',
        horaFin: '${_formatTime(_endTime)}:00',
        metodoPago: _selectedPaymentMethod,
      );

      setState(() {
        _isSuccess = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showSnackbar('Error al registrar la reserva: ${e.toString()}', Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {

    // Vista de carga
    if (_isLoadingVenue) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    // Vista de autenticación obligatoria
    if (_errorMessage == 'AUTH_REQUIRED') {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.backgroundColor, elevation: 0),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 20),
                const Text(
                  'Inicia Sesión para Reservar',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Necesitas tener una cuenta para poder reservar escenarios deportivos.',
                  style: TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Iniciar Sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Vista de error general
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.backgroundColor, elevation: 0),
        body: Center(
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
        ),
      );
    }

    // Pantalla de Éxito
    if (_isSuccess) {
      return Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, size: 48, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Reserva Confirmada!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu reserva ha sido registrada exitosamente. El administrador de la cancha la revisará pronto.',
                  style: TextStyle(color: Colors.white60, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard/user'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: const Text('Ver mis reservas'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Render del Formulario Principal
    return Scaffold(
      appBar: AppBar(
        title: Text('Reserva: ${_venue!.nombre}'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              context.go('/venues');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Indicador de pasos
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PASO $_currentStep DE 2',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentStep == 1 ? 'Elige fecha y horario' : 'Resumen y Pago',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _currentStep / 2.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tira informativa del Escenario
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text('🏟️', style: TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _venue!.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_venue!.tipo} · ${_formatCurrency(_venue!.precio)} / hr',
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PASO 1: Selector de fecha y hora
                    if (_currentStep == 1) ...[
                      // Selector de Fecha
                      const Text('📅 Fecha de la reserva', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null ? 'Seleccionar fecha' : _formatDate(_selectedDate),
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.white30 : Colors.white,
                                ),
                              ),
                              const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Horas de inicio y fin
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hora de inicio', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
                                    );
                                    if (time != null) {
                                      setState(() => _startTime = time);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startTime == null ? '08:00' : _formatTime(_startTime),
                                          style: TextStyle(
                                            color: _startTime == null ? Colors.white30 : Colors.white,
                                          ),
                                        ),
                                        const Icon(Icons.access_time, color: Colors.white38, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hora de fin', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _endTime ?? const TimeOfDay(hour: 9, minute: 0),
                                    );
                                    if (time != null) {
                                      setState(() => _endTime = time);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endTime == null ? '09:00' : _formatTime(_endTime),
                                          style: TextStyle(
                                            color: _endTime == null ? Colors.white30 : Colors.white,
                                          ),
                                        ),
                                        const Icon(Icons.access_time, color: Colors.white38, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]
                    // PASO 2: Resumen y Pago
                    else ...[
                      // Resumen de Reserva
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow('Cancha', _venue!.nombre),
                            _buildSummaryRow('Fecha', _formatDate(_selectedDate)),
                            _buildSummaryRow('Horario', '${_formatTime(_startTime)} - ${_formatTime(_endTime)}'),
                            _buildSummaryRow('Duración', '${_calculateDuration().toStringAsFixed(1)} hr'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(color: Colors.white10),
                            ),
                            _buildSummaryRow(
                              'Total estimado',
                              _formatCurrency(_calculateTotal()),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Métodos de Pago
                      const Text('💳 Método de pago', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _buildPaymentOption('efectivo', '💵', 'Efectivo', 'Al llegar'),
                          _buildPaymentOption('transferencia', '🏦', 'Transferencia', 'Nequi / Bancolombia'),
                          _buildPaymentOption('tarjeta', '💳', 'Tarjeta', 'Débito / Crédito'),
                          _buildPaymentOption('pse', '🌐', 'PSE', 'Pago en línea'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Botones del footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_currentStep > 1)
                          OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              side: const BorderSide(color: Colors.white24),
                            ),
                            child: const Text('Volver', style: TextStyle(color: Colors.white)),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : (_currentStep == 1 ? () {
                                    if (_validateStep1()) setState(() => _currentStep = 2);
                                  } : _submitBooking),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundColor),
                                    ),
                                  )
                                : Text(_currentStep == 1 ? 'Siguiente' : 'Confirmar Reserva'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white60, fontSize: isTotal ? 15 : 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 17 : 14,
              color: isTotal ? AppTheme.primaryColor : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String key, String icon, String name, String subtitle) {
    final isSelected = _selectedPaymentMethod == key;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9, color: Colors.white38),
                    maxLines: 1,
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
