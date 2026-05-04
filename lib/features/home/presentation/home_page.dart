import 'dart:async';

import 'package:certipath_app/core/theme.dart';
import 'package:certipath_app/features/home/data/models/product_model.dart';
import 'package:certipath_app/features/home/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:certipath_app/features/home/presentation/widgets/home_profile_card.dart';

import '../../auth/application/auth_provider.dart';

// Models

class ApiResponse {
  final String code;
  final List<Product> data;
  final String message;
  final Meta meta;

  ApiResponse({
    required this.code,
    required this.data,
    required this.message,
    required this.meta,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<Product> products = dataList
        .map((item) => Product.fromJson(item))
        .toList();
    return ApiResponse(
      code: json['code'],
      data: products,
      message: json['message'],
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class Meta {
  final int limit;
  final int page;
  final int totalData;
  final int totalPage;

  Meta({
    required this.limit,
    required this.page,
    required this.totalData,
    required this.totalPage,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      limit: json['limit'],
      page: json['page'],
      totalData: json['total_data'],
      totalPage: json['total_page'],
    );
  }
}

// Product Provider
final productsProvider = FutureProvider.family<ApiResponse, int>((
  ref,
  page,
) async {
  final response = await http
      .get(
        Uri.parse('https://certipath-api.alope.id/api/products?page=$page'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'CertiPath/1.0.0 (Flutter)',
        },
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode == 200) {
    return ApiResponse.fromJson(json.decode(response.body));
  } else {
    throw HttpException('Server error: ${response.statusCode}');
  }
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // 1. Controller & State Variables
  late ScrollController _scrollController;
  late PageController _bannerController;
  late AnimationController _heroController;
  // late Animation<double> _heroAnimation;
  Timer? _bannerTimer;

  bool _isCollapsed = false;
  bool _showScrollToTop = false;
  int _currentBannerIndex = 0;

  // 2. Banner Data
  final List<String> _bannerMessages = [
    "Keaslian produk terlindungi dengan blockchain",
    "Redline Apparel menjadi kepercayaan masyarakat",
    "Ayo beli produk limited edition sekarang",
    "Sertifikat digital untuk setiap pembelian",
    "Transparansi total dari produksi hingga pengiriman",
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _scrollController = ScrollController();

    // _initializeAnimations();
    _setupScrollListener();
    _startBannerAutoScroll();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Logika untuk menampilkan nama aplikasi "Certipath" di AppBar
      if (_scrollController.offset > 180 && !_isCollapsed) {
        setState(() => _isCollapsed = true);
      } else if (_scrollController.offset <= 180 && _isCollapsed) {
        setState(() => _isCollapsed = false);
      }

      // Logika untuk menampilkan tombol Scroll To Top
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % _bannerMessages.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _scrollController.dispose();
    _bannerController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    ref.invalidate(productsProvider(1));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = ref.watch(authProvider).user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.ecru,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.inkLight),
              const SizedBox(height: 16),
              Text(
                'Please login to continue',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ecru,
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              elevation: 0,
              centerTitle: true,
              backgroundColor: AppColors.primary,

              title: _isCollapsed
                  ? Text(
                      'Certipath',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,

              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: HomeProfileCard(
                  userName: user.name,
                  bannerMessages: _bannerMessages,
                  bannerController: _bannerController,
                  currentIndex: _currentBannerIndex,
                  onPageChanged: (index) {
                    setState(() => _currentBannerIndex = index);
                  },
                ),
              ),
            ),

            _buildProductsTitleSliver(),
            _buildProductsGridSliver(),
            // const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              heroTag: "scroll_top",
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildProductsTitleSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Consumer(
          builder: (context, ref, child) {
            final asyncProducts = ref.watch(productsProvider(1));
            return Row(
              children: [
                SizedBox(height: 100),
                Text(
                  "Available Products",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
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
                    baseColor: AppColors.inkLight,
                    highlightColor: AppColors.primaryTint,
                    child: SizedBox(width: 24, height: 24),
                  ),
                  error: (_, _) =>
                      Icon(Icons.error, color: Colors.red.shade400),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductsGridSliver() {
    return Consumer(
      builder: (context, ref, child) {
        final asyncProducts = ref.watch(productsProvider(1));

        return asyncProducts.when(
          data: (response) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(product: response.data[index]),
                childCount: response.data.length,
              ),
            ),
          ),
          loading: () => _buildLoadingSliver(),
          error: (error, stack) => _buildErrorSliver(error.toString()),
        );
      },
    );
  }

  Widget _buildLoadingSliver() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSliver(String error) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text(
              "Failed to load products",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder ProductDetailPage
class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Product Detail Page\n(Implementasi selanjutnya)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// ✅ TRUNCATE NAME (Max 25 chars)
String _truncateProductName(String name) {
  if (name.length <= 15) return name;
  return '${name.substring(0, 15)}...';
}

// ✅ TOOLTIP DIALOG
void _showProductNameTooltip(BuildContext context, String fullName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Product Name',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fullName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${fullName.length} characters',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.inkLight,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    },
  );
}
