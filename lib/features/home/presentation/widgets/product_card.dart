import 'package:certipath_app/core/theme.dart';
import 'package:certipath_app/features/home/data/models/product_model.dart';
import 'package:certipath_app/features/home/presentation/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // Helper function dipindahkan ke dalam class agar bisa diakses
  String _truncateProductName(String name) {
    return name.length > 30 ? '${name.substring(0, 27)}...' : name;
  }

  void _showProductNameTooltip(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(name),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerified =
        product.merkleRoot.isNotEmpty || product.blockchainTx.isNotEmpty;

    return Hero(
      tag: 'product_${product.id}',
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 5,
        shadowColor: AppColors.primaryTint.withOpacity(0.4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.paper, AppColors.paper.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isVerified
                  ? Colors.purple.withOpacity(0.3)
                  : AppColors.primaryTint,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // builder: (context) => ProductDetailPage(product: product),
                  builder: (context) => ProductDetailPage(product: product),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- IMAGE SECTION ---
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        product.image.isNotEmpty
                            ? 'https://certipath-api.alope.id/uploads/${product.image}'
                            : '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.parchment,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.parchment,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: AppColors.inkFaint,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "No Image",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.inkFaint,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // --- INFO SECTION ---
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onLongPress: () =>
                              _showProductNameTooltip(context, product.name),
                          child: Text(
                            _truncateProductName(product.name),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(product.price),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
