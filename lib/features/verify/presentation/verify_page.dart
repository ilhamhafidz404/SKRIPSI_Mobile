import 'dart:ui';
import 'package:certipath_app/core/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key, required this.serial});
  final String serial;

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _result;
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Logic untuk mengatur transparansi teks di AppBar saat scroll
  void _onScroll() {
    double offset = _scrollController.offset;
    double newOpacity = (offset / 100).clamp(0.0, 1.0);
    if (newOpacity != _headerOpacity) {
      setState(() {
        _headerOpacity = newOpacity;
      });
    }
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
        _error = (e.response?.data as Map?)?['message'] ?? 'Record Not Found';
      });
    } catch (_) {
      setState(() {
        _error = 'Authentication server unreachable.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(
      'https://certipath.alope.id/verify/${widget.serial}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(_headerOpacity * 0.8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Opacity(
          opacity: _headerOpacity,
          child: Text(
            'CERTIPATH',
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _buildCertificate(),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: Color(0xFFC0202A),
            strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'INITIALIZING VERIFICATION',
          style: GoogleFonts.lexend(
            color: const Color(0xFFC0202A),
            fontSize: 10,
            letterSpacing: 4,
          ),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Text(
      _error!,
      style: GoogleFonts.sourceCodePro(
        color: const Color(0xFFC0202A),
        fontSize: 12,
        letterSpacing: 2,
      ),
    ),
  );

  Widget _buildCertificate() {
    final r = _result!;
    final isAuth = r['is_authentic'] as bool? ?? false;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 40, 20, 40),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC0202A).withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF8B0000),
                        Color(0xFFC0202A),
                        Color(0xFFE8312A),
                      ],
                    ),
                  ),
                ),
                Stack(
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          'CP',
                          style: TextStyle(
                            fontSize: 180,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.black.withOpacity(0.03),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        children: [
                          _buildBrandHeader(),
                          const SizedBox(height: 8),
                          Text(
                            'Certificate',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 25,
                              color: const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            'of Authenticity',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 25,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SECURE BLOCKCHAIN VERIFICATION',
                            style: GoogleFonts.lexend(
                              fontSize: 8,
                              color: const Color(0xFF1A1A1A).withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildStatusIndicator(isAuth),
                          const SizedBox(height: 40),
                          const Divider(color: Colors.black12),
                          const SizedBox(height: 32),
                          _buildDetailRow(
                            "Serial Number",
                            r['serial_number'],
                            isHighlight: true,
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(
                            "Product Collection",
                            "Archive Model #${r['product_id']}",
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow("Origin", "Kuningan, Indonesia"),
                          const SizedBox(height: 40),
                          _buildBlockchainBox(r),

                          const SizedBox(height: 24),

                          _buildOwnershipCard(r),

                          const SizedBox(height: 24),

                          _buildOwnershipHistory(r),

                          const SizedBox(height: 48),

                          _buildCertificateFooter(r['serial_number']),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  color: const Color(0xFF1A1A1A),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '© 2026 REDLINE APPAREL CERTIPATH',
                        style: GoogleFonts.lexend(
                          fontSize: 7,
                          color: Colors.white24,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Row(children: [_dot(1.0), _dot(0.5), _dot(0.2)]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildPrintButton(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 1,
          color: const Color(0xFFC0202A).withOpacity(0.3),
        ),
        const SizedBox(width: 12),
        Text(
          'REDLINE APPAREL',
          style: GoogleFonts.lexend(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: const Color(0xFFC0202A),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 30,
          height: 1,
          color: const Color(0xFFC0202A).withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(bool isAuth) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isAuth ? const Color(0xFFC0202A) : Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              if (isAuth)
                BoxShadow(
                  color: const Color(0xFFC0202A).withOpacity(0.4),
                  blurRadius: 20,
                ),
            ],
          ),
          child: Icon(
            isAuth ? Icons.check : Icons.close,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isAuth ? 'Product Verified' : 'Verification Failed',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAuth
              ? 'This item is a certified genuine masterpiece.'
              : 'Unable to confirm authenticity.',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.lexend(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black26,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 15,
              color: isHighlight ? const Color(0xFFC0202A) : Colors.black,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainBox(Map r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRYPTOGRAPHIC EVIDENCE',
            style: GoogleFonts.lexend(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.black26,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _blockchainItem(Icons.hub_outlined, 'Network', 'Ethereum Mainnet'),
          const SizedBox(height: 12),
          _blockchainItem(
            Icons.link,
            'Transaction',
            r['tx_hash'],
            isHash: true,
          ),
          const SizedBox(height: 12),
          _blockchainItem(
            Icons.shield_outlined,
            'Root Hash',
            r['db_root_hash'],
            isHash: true,
          ),
        ],
      ),
    );
  }

  Widget _blockchainItem(
    IconData icon,
    String label,
    String value, {
    bool isHash = false,
  }) {
    String displayValue = isHash
        ? "${value.substring(0, 12)}...${value.substring(value.length - 12)}"
        : value;
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFC0202A).withOpacity(0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lexend(fontSize: 8, color: Colors.black38),
              ),
              Text(
                displayValue,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 9,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnershipCard(Map r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC0202A).withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC0202A).withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT OWNERSHIP',
            style: GoogleFonts.lexend(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.black26,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            r['ownership_label'] ?? 'Unclaimed',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: const Color(0xFFC0202A),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Ownership Sequence #${r['ownership_sequence'] ?? 0}',
            style: GoogleFonts.lexend(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnershipHistory(Map r) {
    final history = (r['ownership_history'] as List?) ?? [];

    if (history.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OWNERSHIP HISTORY',
            style: GoogleFonts.lexend(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.black26,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 20),

          ...history.map((e) {
            final seq = e['ownership_sequence'];

            final owner = e['to_user']?['name'] ?? 'Unknown Owner';

            final method = e['transfer_method'] ?? '-';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC0202A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$seq',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          method,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCertificateFooter(String serial) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Redline Apparel',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 120,
              height: 1,
              color: Colors.black12,
            ),
            Text(
              'OFFICIAL REPRESENTATIVE',
              style: GoogleFonts.lexend(
                fontSize: 7,
                letterSpacing: 2,
                color: Colors.black26,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 50,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UNIQUE ID',
              style: GoogleFonts.lexend(fontSize: 7, color: Colors.black26),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrintButton() {
    return InkWell(
      onTap: _launchUrl,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.print_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Text(
              'PRINT ARCHIVAL COPY',
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(double opacity) => Container(
    margin: const EdgeInsets.only(left: 4),
    width: 4,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFC0202A).withOpacity(opacity),
      shape: BoxShape.circle,
    ),
  );
}
