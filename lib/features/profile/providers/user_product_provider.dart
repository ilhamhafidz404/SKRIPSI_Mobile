import 'package:certipath_app/features/auth/application/auth_provider.dart';
import 'package:certipath_app/features/profile/data/models/user_product_model.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProductsProvider = FutureProvider.autoDispose<UserProductResponse>((
  ref,
) async {
  print('--- LOG: PROVIDER DIBERHENTIKAN ---'); // Cek apakah ini muncul

  final authState = ref.watch(authProvider);
  final user = authState.user;
  final token = user?.token;

  if (user == null || token == null) {
    print('--- LOG: USER/TOKEN NULL ---');
    throw Exception("Unauthorized");
  }

  print('--- LOG: FETCHING UNTUK ID ${user.id} ---');

  final dio = Dio();
  try {
    final response = await dio.get(
      'https://certipath-api.alope.id/api/users/${user.id}',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
    return UserProductResponse.fromJson(response.data);
  } on DioException catch (e) {
    print('--- LOG: DIO ERROR ${e.response?.statusCode} ---');
    rethrow;
  }
});
