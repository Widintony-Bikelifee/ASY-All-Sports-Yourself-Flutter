import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'theme/theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/venues/venues_screen.dart';
import 'screens/venues/booking_screen.dart';
import 'screens/dashboard/user_dashboard.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/admin_venues_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase globalmente
  await Supabase.initialize(
    url: 'https://syiyfvfuondxuntkoumb.supabase.co',
    anonKey: 'sb_publishable_7mNlNfecB1RnCxLqRvprzA_jOmvwgRW',
  );

  runApp(const MyApp());
}

/// Enrutador principal de la aplicación utilizando GoRouter
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/venues',
      builder: (BuildContext context, GoRouterState state) => const VenuesScreen(),
    ),
    GoRoute(
      path: '/book/:id',
      builder: (BuildContext context, GoRouterState state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return BookingScreen(escenarioId: id);
      },
    ),
    GoRoute(
      path: '/dashboard/user',
      builder: (BuildContext context, GoRouterState state) => const UserDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/admin',
      builder: (BuildContext context, GoRouterState state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/venues',
      builder: (BuildContext context, GoRouterState state) => const AdminVenuesScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'All Sports Yourself',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Aplicamos nuestro tema oscuro premium
      routerConfig: _router,
    );
  }
}
