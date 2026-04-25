import 'package:certipath_app/features/auth/application/auth_provider.dart';
import 'package:certipath_app/features/auth/presentation/login_page.dart';
import 'package:certipath_app/features/home/presentation/home_page.dart';
import 'package:certipath_app/features/scan/presentation/scan_page.dart';
import 'package:certipath_app/features/verify/presentation/verify_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Route yang bisa diakses tanpa login
const _publicRoutes = ['/login', '/verify'];

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading =
          authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      final path = state.matchedLocation;

      // Tunggu session selesai load
      if (isLoading) return null;

      // Cek apakah route ini publik
      final isPublic = _publicRoutes.any((r) => path.startsWith(r));

      // Belum login & bukan halaman publik → ke login
      if (!isAuthenticated && !isPublic) return '/login';

      // Sudah login tapi di halaman login → ke home
      if (isAuthenticated && path == '/login') return '/home';

      return null;
    },
    routes: [
      // ── Public ──────────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/verify/:serial',
        builder: (_, state) =>
            VerifyPage(serial: state.pathParameters['serial']!),
      ),

      // ── Protected ────────────────────────────────────────────────────────────
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/scan', builder: (_, __) => const ScanQrPage()),
    ],
  );
});
