import 'package:certipath_app/core/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AuthUser {
  final int id;
  final String email;
  final String name;
  final String avatar;
  final String role;
  final String token;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.avatar,
    required this.role,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, String token) =>
      AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        token: token,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user = null,
    this.errorMessage = null,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkExistingSession();
  }

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _api = ApiService();

  // Cek apakah sudah punya token tersimpan
  Future<void> _checkExistingSession() async {
    final loggedIn = await _api.isLoggedIn();
    state = state.copyWith(
      status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // 1. Trigger Google popup
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancel
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // 2. Ambil auth tokens dari Google
      final googleAuth = await googleUser.authentication;

      // 3. Kirim ke backend Go
      final response = await _api.googleLogin(
        googleId: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        avatar: googleUser.photoUrl ?? '',
        accessToken: googleAuth.accessToken ?? '',
      );

      // 4. Simpan JWT
      final token = response['token'] as String;
      await _api.saveToken(token);

      // 5. Set state
      final user = AuthUser.fromJson(
        response['user'] as Map<String, dynamic>,
        token,
      );

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      print("ERROR GOOGLE LOGIN: $e"); // 👈 penting
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _api.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
