import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = 'http://10.131.2.246:8080/api';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();

  late final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(_authInterceptor())
        ..interceptors.add(LogInterceptor(responseBody: true));

  // Otomatis inject JWT ke setiap request
  Interceptor _authInterceptor() => InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        // Token expired — bisa trigger logout di sini
      }
      handler.next(error);
    },
  );

  Dio get client => _dio;

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> googleLogin({
    required String googleId,
    required String email,
    required String name,
    required String avatar,
    required String accessToken,
  }) async {
    final res = await _dio.post(
      '/auth/google',
      data: {
        'google_id': googleId,
        'email': email,
        'name': name,
        'avatar': avatar,
        'access_token': accessToken,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'jwt_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }
}
