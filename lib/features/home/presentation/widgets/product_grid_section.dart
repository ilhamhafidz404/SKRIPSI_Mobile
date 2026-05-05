import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_provider.dart';
import 'product_card.dart';

class ProductGridSection extends ConsumerWidget {
  const ProductGridSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(1));

    return productsAsync.when(
      data: (apiResponse) {
        final products = apiResponse.data;

        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Produk tidak tersedia"),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(product: product);
            }, childCount: products.length),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Center(child: Text("Gagal ambil data: $err")),
      ),
    );
  }
}
