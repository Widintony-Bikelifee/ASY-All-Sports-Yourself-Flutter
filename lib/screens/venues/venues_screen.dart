import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/escenario.dart';
import '../../services/venues_service.dart';
import '../../theme/theme.dart';

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  List<Escenario> _allVenues = [];
  List<Escenario> _filteredVenues = [];
  String _selectedCategory = 'todos';
  bool _isLoading = true;
  String? _errorMessage;

  final List<Map<String, String>> _categories = [
    {'key': 'todos', 'label': 'Todos', 'icon': '🏟️'},
    {'key': 'futbol', 'label': 'Fútbol', 'icon': '⚽'},
    {'key': 'baloncesto', 'label': 'Baloncesto', 'icon': '🏀'},
    {'key': 'tenis', 'label': 'Tenis', 'icon': '🎾'},
    {'key': 'voleibol', 'label': 'Voleibol', 'icon': '🏐'},
    {'key': 'gimnasio', 'label': 'Gimnasio', 'icon': '🏋️'},
    {'key': 'natacion', 'label': 'Natación', 'icon': '🏊'},
  ];

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    try {
      final data = await VenuesService.instance.getEscenarios();
      setState(() {
        _allVenues = data;
        _filteredVenues = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar escenarios deportivos.';
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String categoryKey) {
    setState(() {
      _selectedCategory = categoryKey;
      if (categoryKey == 'todos') {
        _filteredVenues = _allVenues;
      } else {
        _filteredVenues = _allVenues.where((v) {
          final tipoNorm = v.tipo.toLowerCase();
          final keyNorm = categoryKey.toLowerCase();
          return tipoNorm.contains(keyNorm) || keyNorm.contains(tipoNorm);
        }).toList();
      }
    });
  }

  /// Asset local de respaldo cuando no hay imagen_url en Supabase
  String _getFallbackAsset(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('futbol') || t.contains('fútbol') || t.contains('micro')) {
      return 'assets/images/venues/futbol-5_1.jpg';
    } else if (t.contains('baloncesto') || t.contains('básquet')) {
      return 'assets/images/venues/Balconcesto_1.jpg';
    } else if (t.contains('tenis')) {
      return 'assets/images/venues/Tenis_1.jpg';
    } else if (t.contains('gimnasio') || t.contains('gym')) {
      return 'assets/images/venues/Gimancio_1.jpg';
    } else if (t.contains('volei') || t.contains('vóley')) {
      return 'assets/images/venues/Voleivol_1.jpg';
    } else if (t.contains('natacion') || t.contains('piscina') || t.contains('natación')) {
      return 'assets/images/venues/Piscina_1.jpg';
    }
    return 'assets/images/venues/Estadio_Ipiales.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingSide = size.width > 900 ? 60 : 20;

    int crossAxisCount = 1;
    if (size.width > 1200) {
      crossAxisCount = 4;
    } else if (size.width > 800) {
      crossAxisCount = 3;
    } else if (size.width > 550) {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catálogo de Espacios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.redAccent)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Encabezado ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(paddingSide, 24, paddingSide, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🏟️ CATÁLOGO',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Escenarios Deportivos',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mostrando ${_filteredVenues.length} espacios en Ipiales',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 15),
                            ),
                          ],
                        ),
                      ),

                      // ── Filtros horizontales ──
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                EdgeInsets.symmetric(horizontal: paddingSide),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected =
                                  _selectedCategory == cat['key'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: InkWell(
                                  onTap: () => _applyFilter(cat['key']!),
                                  borderRadius: BorderRadius.circular(30),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.white10,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(cat['icon']!,
                                            style: const TextStyle(
                                                fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          cat['label']!,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppTheme.backgroundColor
                                                : Colors.white70,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ── Cuadrícula de escenarios ──
                      if (_filteredVenues.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'No se encontraron escenarios deportivos en esta categoría.',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: paddingSide, vertical: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredVenues.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 24,
                              childAspectRatio:
                                  size.width > 550 ? 0.8 : 0.85,
                            ),
                            itemBuilder: (context, index) {
                              return _buildVenueCard(
                                  _filteredVenues[index]);
                            },
                          ),
                        ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVenueCard(Escenario venue) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Imagen: Supabase primero, asset local como fallback ──
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _VenueImage(
                  imagenUrl: venue.imagenUrl,
                  fallbackAsset: _getFallbackAsset(venue.tipo),
                ),
                // Overlay oscuro suave
                Container(color: Colors.black26),
                // Badge de tipo de deporte
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      venue.tipo.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Información del escenario ──
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.white38),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        venue.ubicacion,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white38),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white10),
                const SizedBox(height: 12),

                // ── Precio + botón reservar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRECIO / HORA',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white38,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${venue.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/book/${venue.id}'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reservar',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _VenueImage extends StatelessWidget {
  final String? imagenUrl;
  final String fallbackAsset;

  const _VenueImage({
    required this.imagenUrl,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Si hay URL de Supabase, intentar cargarla de red
    if (imagenUrl != null && imagenUrl!.isNotEmpty) {
      return Image.network(
        imagenUrl!,
        fit: BoxFit.cover,
        // Mientras carga: shimmer gris con indicador
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.white10,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
          );
        },
        // Si la URL falla: caer al asset local
        errorBuilder: (context, error, stackTrace) {
          return _AssetFallback(asset: fallbackAsset);
        },
      );
    }

    // 2️⃣ Sin URL: usar asset local según el tipo de deporte
    return _AssetFallback(asset: fallbackAsset);
  }
}

// Asset local con su propio errorBuilder por si el asset tampoco existe
class _AssetFallback extends StatelessWidget {
  final String asset;
  const _AssetFallback({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.white10,
        child: const Center(
          child: Icon(Icons.sports_soccer, size: 48, color: Colors.white24),
        ),
      ),
    );
  }
}