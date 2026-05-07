import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Sesuaikan path import ini dengan project Anda
import '../../auth/application/auth_provider.dart';

// ─── 1. MODELS ───────────────────────────────────────────────────────────────

class ProductItem {
  final String id;
  final String productId;
  final String serialNumber;

  ProductItem({
    required this.id,
    required this.productId,
    required this.serialNumber,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      serialNumber: json['serial_number'] ?? '',
    );
  }
}

class UserProductResponse {
  final List<ProductItem> productItems;
  UserProductResponse({required this.productItems});

  factory UserProductResponse.fromJson(Map<String, dynamic> json) {
    final List items = json['data']['product_items'] ?? [];
    return UserProductResponse(
      productItems: items.map((i) => ProductItem.fromJson(i)).toList(),
    );
  }
}

// ─── 2. PROVIDER ─────────────────────────────────────────────────────────────

final userProductsProvider = FutureProvider.autoDispose
    .family<UserProductResponse, String>((ref, userId) async {
      final authState = ref.watch(authProvider);
      final token = authState.user?.token;

      if (token == null || token.isEmpty)
        throw Exception("Unauthorized: No Token");

      final dio = Dio();
      final response = await dio.get(
        'https://certipath-api.alope.id/api/users/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return UserProductResponse.fromJson(response.data);
    });

// ─── 3. PROFILE PAGE ─────────────────────────────────────────────────────────

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Panggil provider produk
    final productsAsync = user != null
        ? ref.watch(userProductsProvider(user.id.toString()))
        : null;

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // BACKGROUND IMAGE (Full Screen)
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1654676066221-500d63a81951?q=80&w=1740&auto=format&fit=crop',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            ),

            // DARK OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // CONTENT
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(minHeight: screenHeight),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 40),

                        // PROFILE CARD
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _buildGlassCard(
                            child: user == null
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : _buildProfileDetails(ref, user),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // PRODUCTS SECTION
                        if (user != null && productsAsync != null)
                          productsAsync.when(
                            data: (data) =>
                                _buildProductSection(data.productItems),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFC0202A),
                              ),
                            ),
                            error: (err, _) => _buildErrorState(err.toString()),
                          ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDGET PARTS ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'CERTIPATH ARCHIVE',
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails(WidgetRef ref, dynamic user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC0202A), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC0202A).withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundImage: user.avatar.isNotEmpty
                ? NetworkImage(user.avatar)
                : null,
            child: user.avatar.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          user.name.toUpperCase(),
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          user.email,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'SIGN OUT',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSection(List<ProductItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'OWNED COLLECTIONS (${items.length})',
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 190,
          child: items.isEmpty
              ? Center(
                  child: Text(
                    "No items claimed",
                    style: GoogleFonts.inter(color: Colors.white24),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 24),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(items[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductItem item) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFC0202A).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Color(0xFFC0202A),
                size: 40,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRODUCT #${item.productId}',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SN: ${item.serialNumber.length > 10 ? item.serialNumber.substring(0, 10) : item.serialNumber}...',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          "ARCHIVE ERROR: $error",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC0202A),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
