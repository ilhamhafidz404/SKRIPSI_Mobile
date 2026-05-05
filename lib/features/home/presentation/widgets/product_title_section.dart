import 'package:certipath_app/core/theme.dart';
import 'package:certipath_app/features/home/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ProductTitleSection extends ConsumerWidget {
  const ProductTitleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(productsProvider(1));
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(height: 100),
            Text(
              "Available Products",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            asyncProducts.when(
              data: (data) => Badge(
                label: Text("${data.meta.totalData}"),
                backgroundColor: AppColors.primary,
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                child: Icon(Icons.grid_view, color: AppColors.primary),
              ),
              loading: () => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: SizedBox(width: 24, height: 24),
              ),
              error: (_, _) => Icon(Icons.error),
            ),
          ],
        ),
      ),
    );
  }
}
