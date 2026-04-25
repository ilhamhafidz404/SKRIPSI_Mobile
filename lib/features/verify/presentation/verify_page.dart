import 'package:certipath_app/core/api_service.dart';
import 'package:certipath_app/core/theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key, required this.serial});
  final String serial;

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _api = ApiService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.client.get('/verify/${widget.serial}');
      setState(() {
        _result = res.data as Map<String, dynamic>;
      });
    } on DioException catch (e) {
      setState(() {
        _error = (e.response?.data as Map?)?['message'] ?? 'Gagal memuat data.';
      });
    } catch (_) {
      setState(() {
        _error = 'Terjadi kesalahan. Periksa koneksi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ecru,
      appBar: AppBar(
        title: Text(
          'VERIFIKASI KEASLIAN',
          style: GoogleFonts.sourceCodePro(fontSize: 11, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _buildResult(),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'MEMVERIFIKASI...',
          style: GoogleFonts.sourceCodePro(
            fontSize: 10,
            letterSpacing: 3,
            color: AppColors.primary.withOpacity(0.6),
          ),
        ),
      ],
    ),
  );

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: AppColors.primary.withOpacity(0.4),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(
              'COBA LAGI',
              style: GoogleFonts.sourceCodePro(fontSize: 10, letterSpacing: 2),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Result ─────────────────────────────────────────────────────────────────

  Widget _buildResult() {
    final r = _result!;
    final isAuthentic = r['is_authentic'] as bool? ?? false;
    final serial = r['serial_number'] as String? ?? widget.serial;
    final productId = r['product_id'] as String? ?? '-';
    final merkleRoot = r['db_root_hash'] as String? ?? '';
    final txHash = r['tx_hash'] as String? ?? '';
    final verifiedAt = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // ── Sertifikat ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.paper,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: AppColors.ink.withOpacity(0.10),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top bar
                _GradientBar(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: Column(
                    children: [
                      // Logo
                      _LogoRow(),
                      const SizedBox(height: 12),

                      Text(
                        'REDLINE APPAREL',
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 8,
                          letterSpacing: 5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CERTIFICATE',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          letterSpacing: 4,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'OF AUTHENTICITY',
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 7,
                          letterSpacing: 3,
                          color: AppColors.inkFaint,
                        ),
                      ),

                      const SizedBox(height: 20),
                      _Divider(),
                      const SizedBox(height: 20),

                      // Status banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isAuthentic
                              ? AppColors.primary.withOpacity(0.06)
                              : Colors.red.shade50,
                          border: Border.all(
                            color: isAuthentic
                                ? AppColors.primary.withOpacity(0.2)
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAuthentic
                                  ? Icons.verified_outlined
                                  : Icons.dangerous_outlined,
                              color: isAuthentic
                                  ? AppColors.primary
                                  : Colors.red.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAuthentic
                                  ? 'VERIFIED AUTHENTIC'
                                  : 'NOT AUTHENTIC',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 10,
                                letterSpacing: 2.5,
                                color: isAuthentic
                                    ? AppColors.primary
                                    : Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Body text
                      Text(
                        isAuthentic
                            ? 'Item ini telah diverifikasi dan tercatat secara kriptografis di blockchain sebagai produk asli Redline Apparel.'
                            : 'Item ini tidak dapat diverifikasi sebagai produk asli Redline Apparel.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.8,
                          color: AppColors.inkLight,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Detail grid
                      _DetailGrid(
                        items: [
                          ('PRODUCT ID', '#$productId'),
                          (
                            'VERIFIED ON',
                            '${verifiedAt.day}/${verifiedAt.month}/${verifiedAt.year}',
                          ),
                          (
                            'MERKLE ROOT',
                            merkleRoot.isNotEmpty
                                ? '${merkleRoot.substring(0, 14)}...'
                                : '-',
                          ),
                          (
                            'TX HASH',
                            txHash.isNotEmpty
                                ? '${txHash.substring(0, 14)}...'
                                : '-',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Chain badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        color: AppColors.parchment,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.link,
                              size: 11,
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SECURED BY ETHEREUM BLOCKCHAIN',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 7,
                                letterSpacing: 2,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      _Divider(),
                      const SizedBox(height: 12),

                      // Cert number
                      Text(
                        'CERT-$productId-${serial.substring(0, 8).toUpperCase()} · CERTIPATH',
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 7,
                          letterSpacing: 2,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),

                _GradientBar(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol kembali
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'KEMBALI',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: AppColors.inkLight,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _GradientBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 5,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF8B0000),
          Color(0xFFC0202A),
          Color(0xFFE8312A),
          Color(0xFFC0202A),
          Color(0xFF8B0000),
        ],
      ),
    ),
  );
}

class _LogoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0x50C0202A)],
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          color: AppColors.primary.withOpacity(0.06),
        ),
        child: Center(
          child: Text(
            'R',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x50C0202A), Colors.transparent],
            ),
          ),
        ),
      ),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(height: 1, color: AppColors.primary.withOpacity(0.15)),
      ),
      const SizedBox(width: 12),
      Column(
        children: [
          _Diamond(opacity: 0.2),
          const SizedBox(height: 3),
          _Diamond(opacity: 0.5),
          const SizedBox(height: 3),
          _Diamond(opacity: 0.2),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(height: 1, color: AppColors.primary.withOpacity(0.15)),
      ),
    ],
  );
}

class _Diamond extends StatelessWidget {
  const _Diamond({required this.opacity});
  final double opacity;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.785,
    child: Container(
      width: 5,
      height: 5,
      color: AppColors.primary.withOpacity(opacity),
    ),
  );
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.parchment,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 7,
                      letterSpacing: 1.5,
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$2,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
