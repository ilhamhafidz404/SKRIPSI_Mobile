import 'package:certipath_app/models/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/product_repository.dart';

final productsProvider = FutureProvider.family<ApiResponse, int>((
  ref,
  page,
) async {
  final repository = ref.watch(productRepositoryProvider);

  return repository.fetchProducts(page);
});
