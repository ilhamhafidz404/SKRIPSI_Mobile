import 'dart:convert';

import 'package:certipath_app/models/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ProductRepository {
  Future<ApiResponse> fetchProducts(int page) async {
    final response = await http.get(
      Uri.parse('https://certipath-api.alope.id/api/products?page=$page'),
      // ... headers dll
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Gagal memuat data');
    }
  }
}

// Tambahkan provider untuk repository-nya sendiri
final productRepositoryProvider = Provider((ref) => ProductRepository());
