import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;
  String _userRole = 'user';
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        final profile = await AuthService.instance.getUserProfile(user.id);
        setState(() {
          _isLoggedIn = true;
          _userRole = profile.rol;
          _userName = profile.nombre;
        });
      } catch (_) {
        setState(() {
          _isLoggedIn = true;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo base oscuro
          Container(color: AppTheme.backgroundColor),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. BARRA DE NAVEGACIÓN (NAVBAR)
                  _buildNavbar(isWideScreen),

                  // 2. HERO SECTION
                  _buildHeroSection(isWideScreen, size),

                  // 3. SECCIÓN DE ESTADÍSTICAS
                  _buildStatsSection(isWideScreen),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        border: const Border(
          bottom: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo & Text
          InkWell(
            onTap: () => context.go('/'),
            child: Row(
              children: [
                Image.asset('assets/images/Logo-ASY.png', height: 40),
                const SizedBox(width: 12),
                if (isWideScreen)
                  const Text(
                    'All Sports Yourself',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Navigation Actions
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
            )
          else if (_isLoggedIn)
            Row(
              children: [
                if (isWideScreen) ...[
                  Text(
                    'Hola, $_userName',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton(
                  onPressed: () {
                    if (_userRole == 'admin_cancha') {
                      context.go('/dashboard/admin');
                    } else {
                      context.go('/dashboard/user');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Mi Panel', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, color: Colors.white60),
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    setState(() {
                      _isLoggedIn = false;
                      _userRole = 'user';
                      _userName = '';
                    });
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Registrarse', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isWideScreen, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 60 : 24,
        vertical: isWideScreen ? 100 : 60,
      ),
      child: Column(
        crossAxisAlignment: isWideScreen ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // Location Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.location_on, size: 14, color: AppTheme.primaryColor),
                SizedBox(width: 6),
                Text(
                  'Ipiales, Nariño — Colombia',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Headline
          RichText(
            textAlign: isWideScreen ? TextAlign.start : TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 48,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: Colors.white,
              ),
              children: [
                const TextSpan(text: 'Reserva tu\n'),
                TextSpan(
                  text: 'Espacio Ideal',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    shadows: [
                      Shadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'La plataforma más completa para reservar canchas de fútbol, baloncesto, tenis, gimnasios y más en Ipiales. Disponibilidad en tiempo real, pagos seguros y sin complicaciones.',
              textAlign: isWideScreen ? TextAlign.start : TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // CTA Buttons
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/venues'),
                icon: const Icon(Icons.sports_soccer_outlined),
                label: const Text('Explorar Espacios'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  elevation: 8,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // Mostrar diálogo o pantalla de ayuda
                },
                icon: const Icon(Icons.info_outline, color: Colors.white),
                label: const Text('Cómo Funciona', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  side: const BorderSide(color: Colors.white30, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isWideScreen) {
    final stats = [
      {'val': '50+', 'lbl': 'Espacios'},
      {'val': '2.4K+', 'lbl': 'Reservas'},
      {'val': '1.2K+', 'lbl': 'Usuarios'},
      {'val': '98%', 'lbl': 'Satisfacción'},
    ];

    if (isWideScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stats.map((stat) => Expanded(child: _buildStatCard(stat['val']!, stat['lbl']!))).toList(),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: stats.map((stat) => _buildStatCard(stat['val']!, stat['lbl']!)).toList(),
        ),
      );
    }
  }

  Widget _buildStatCard(String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white38,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
