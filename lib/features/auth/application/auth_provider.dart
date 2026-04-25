import 'package:certipath_app/core/api_service.dart';
import 'package:dio/dio.dart';
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

  Future<void> _checkExistingSession() async {
    // Hapus token lama setiap buka app — paksa login ulang
    await _api.clearToken();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          return data['error'] ??
              data['message'] ??
              'Terjadi kesalahan pada server';
        }
      }
      return error.message ?? 'Koneksi bermasalah';
    }
    return error.toString();
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final response = await _api.googleLogin(
        googleId: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        avatar: googleUser.photoUrl ?? '',
        accessToken: googleAuth.accessToken ?? '',
      );

      final token = response['token'] as String;
      await _api.saveToken(token);

      final user = AuthUser.fromJson(
        response['user'] as Map<String, dynamic>,
        token,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      );
    } catch (e) {
      final message = _extractErrorMessage(e);
      print('ERROR GOOGLE LOGIN: $message');
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _api.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
