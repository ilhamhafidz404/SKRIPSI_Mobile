import 'package:certipath_app/features/auth/application/auth_provider.dart';
import 'package:certipath_app/features/auth/presentation/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading =
          authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      final onLogin = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isAuthenticated && !onLogin) return '/login';
      if (isAuthenticated && onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    ],
  );
});
