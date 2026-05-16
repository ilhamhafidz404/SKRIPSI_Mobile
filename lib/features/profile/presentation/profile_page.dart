import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Sesuaikan path import ini dengan project Anda
import '../../auth/application/auth_provider.dart';

// ─── 1. MODELS ───────────────────────────────────────────────────────────────

class ProductItem {
  final String id;
  final String serialNumber;
  final DateTime? claimedAt;
  final String productName;
  final String productImage;

  ProductItem({
    required this.id,
    required this.serialNumber,
    this.claimedAt,
    required this.productName,
    required this.productImage,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    return ProductItem(
      id: json['id'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'])
          : null,
      productName: product['name'] ?? '',
      productImage: product['image'] ?? '',
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

      if (token == null || token.isEmpty) throw Exception("Unauthorized");

      final dio = Dio();
      try {
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
      } catch (e) {
        rethrow;
      }
    });

// ─── 3. PROFILE PAGE ─────────────────────────────────────────────────────────

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final productsAsync = user != null
        ? ref.watch(userProductsProvider(user.id.toString()))
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1654676066221-500d63a81951?q=80&w=1740&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.black],
                ),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildGlassCard(
                      child: user == null
                          ? const Center(child: CircularProgressIndicator())
                          : _buildProfileDetails(ref, user),
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (user != null && productsAsync != null)
                    productsAsync.when(
                      data: (data) => _buildProductSection(data.productItems),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC0202A),
                        ),
                      ),
                      error: (err, _) => _buildErrorState(err.toString()),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundImage: user.avatar.isNotEmpty
                ? NetworkImage(user.avatar)
                : null,
            child: user.avatar.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          user.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 20,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'SIGN OUT',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w800),
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
        const SizedBox(height: 16),

        // GUNAKAN INTRINSICHEIGHT UNTUK MENGHITUNG TINGGI OTOMATIS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "No items claimed",
                          style: GoogleFonts.inter(color: Colors.white24),
                        ),
                      ),
                    ]
                  : items.map((item) => _buildProductCard(item)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductItem item) {
    String formattedDate = item.claimedAt != null
        ? "${item.claimedAt!.day} ${_getMonthName(item.claimedAt!.month)} ${item.claimedAt!.year}"
        : "Not Claimed";

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      // Column tanpa Expanded/Spacer di dalamnya agar IntrinsicHeight bisa bekerja
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar dengan ClipRRect
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.white.withOpacity(0.03),
                child: item.productImage.isNotEmpty
                    ? Image.network(
                        'https://certipath-api.alope.id/uploads/${item.productImage}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white12,
                        ),
                      )
                    : const Icon(Icons.inventory_2, color: Colors.white12),
              ),
            ),
          ),

          // Area Teks
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName.toUpperCase(),
                  maxLines: 2, // Beri ruang 2 baris jika nama panjang
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Badge Serial
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0202A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.serialNumber,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFC0202A),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 12),

                // Baris Tanggal
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 10,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 9,
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
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Text(
        "Error: $error",
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
