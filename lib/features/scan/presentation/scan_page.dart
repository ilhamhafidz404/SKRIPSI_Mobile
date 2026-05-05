import 'dart:async';
import 'package:certipath_app/core/theme.dart';
import 'package:certipath_app/features/verify/presentation/verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:certipath_app/core/api_service.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage>
    with SingleTickerProviderStateMixin {
  // ── Controller ──────────────────────────────────────────────────────────────
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false; // cegah double-scan
  bool _torchOn = false;
  bool _isProcessing = false;

  // Tipe QR
  static const _verifyPath = 'verify';
  static const _claimPath = 'claim';

  final _dio = ApiService().client;

  // Animasi garis scan
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned || _isProcessing) return;

    final barcode = capture.barcodes.firstWhere(
      (b) => b.rawValue != null,
      orElse: () => const Barcode(),
    );

    final String? rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isScanned = true;
      _isProcessing = true;
    });
    HapticFeedback.mediumImpact();
    _controller.stop();

    // Tentukan tipe QR
    try {
      final uri = Uri.parse(rawValue);
      final segments = uri.pathSegments;

      final verifyIdx = segments.indexOf(_verifyPath);
      if (verifyIdx != -1 && verifyIdx + 1 < segments.length) {
        // QR Verifikasi
        _showResultSheet(context, segments[verifyIdx + 1], rawValue);
        return;
      }

      final claimIdx = segments.indexOf(_claimPath);
      if (claimIdx != -1 && claimIdx + 1 < segments.length) {
        // QR Klaim
        _showClaimConfirmSheet(segments[claimIdx + 1]);
        return;
      }
    } catch (_) {}

    // Tidak dikenali
    _showUnknownSheet();
  }

  void _showClaimConfirmSheet(String claimToken) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClaimConfirmSheet(
        onConfirm: () {
          Navigator.pop(context);
          _processClaim(claimToken);
        },
        onCancel: () {
          Navigator.pop(context);
          _resetScan();
        },
      ),
    );
  }

  Future<void> _processClaim(String claimToken) async {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoadingSheet(),
    );

    try {
      final res = await _dio.post('/claim/$claimToken');
      if (!mounted) return;
      Navigator.pop(context);

      // Pastikan data adalah Map sebelum diparse
      final data = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      _showClaimSuccessSheet(data);
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      // Ambil pesan error dengan aman
      String msg = 'Gagal mengklaim item.';
      final responseData = e.response?.data;
      if (responseData is Map) {
        msg = responseData['message']?.toString() ?? msg;
      }

      _showErrorSheet(msg);
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSheet('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  void _showClaimSuccessSheet(Map<String, dynamic> data) {
    final ownership = data['ownership'] as Map<String, dynamic>? ?? {};
    final productItem =
        ownership['product_item'] as Map<String, dynamic>? ?? {};
    final product = ownership['product'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClaimSuccessSheet(
        productName: product['name'] as String? ?? '-',
        serialNumber: productItem['serial_number'] as String? ?? '-',
        onDone: () {
          Navigator.pop(context);
          _resetScan();
        },
      ),
    );
  }

  void _showUnknownSheet() {
    _showErrorSheet(
      'QR tidak dikenali. Pastikan QR berasal dari produk Redline Apparel.',
    );
  }

  void _showErrorSheet(String message) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ErrorSheet(
        message: message,
        onScanAgain: () {
          Navigator.pop(context);
          _resetScan();
        },
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _isScanned = false;
      _isProcessing = false;
    });
    _controller.start();
  }

  // ── Bottom sheet setelah scan ───────────────────────────────────────────────
  void _showResultSheet(BuildContext context, String serial, String rawValue) {
    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScanResultSheet(
        serial: serial,
        rawValue: rawValue,
        onVerify: () {
          Navigator.pop(pageContext);
          Navigator.push(
            // ← pakai Navigator.push biasa, bukan GoRouter
            pageContext,
            MaterialPageRoute(builder: (_) => VerifyPage(serial: serial)),
          ).then((_) => _resetScan());
        },
        onScanAgain: () {
          Navigator.pop(context);
          _resetScan();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Text(
          'SCAN QR CODE',
          style: GoogleFonts.sourceCodePro(
            fontSize: 12,
            letterSpacing: 3,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          // Torch toggle
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? AppColors.primary : Colors.white60,
              size: 22,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Kamera ──────────────────────────────────────────────────────────
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // ── Overlay gelap di luar area scan ─────────────────────────────────
          _ScanOverlay(),

          // ── Scan area + animasi ──────────────────────────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  // Corner brackets
                  ..._buildCornerBrackets(),

                  // Garis scan animasi
                  if (!_isScanned)
                    AnimatedBuilder(
                      animation: _scanLineAnim,
                      builder: (_, __) => Positioned(
                        top: _scanLineAnim.value * 240 + 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withOpacity(0.8),
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Success indicator
                  if (_isScanned)
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.15),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Label bawah area scan ───────────────────────────────────────────
          if (!_isScanned)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'ARAHKAN KE QR CODE PRODUK',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pastikan QR code berada di dalam kotak',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

          // ── Processing indicator ────────────────────────────────────────────
          if (_isProcessing && _isScanned)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'MEMPROSES...',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Corner bracket builders
  List<Widget> _buildCornerBrackets() {
    const color = AppColors.primary;
    const len = 24.0;
    const thick = 2.5;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _Bracket(color: color, len: len, thick: thick, topLeft: true),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _Bracket(color: color, len: len, thick: thick, topRight: true),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _Bracket(color: color, len: len, thick: thick, bottomLeft: true),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _Bracket(
          color: color,
          len: len,
          thick: thick,
          bottomRight: true,
        ),
      ),
    ];
  }
}

// ── Scan Overlay (dark area di luar kotak) ─────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.55),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(color: Colors.transparent), // base
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corner Bracket ─────────────────────────────────────────────────────────────

class _Bracket extends StatelessWidget {
  const _Bracket({
    required this.color,
    required this.len,
    required this.thick,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  final Color color;
  final double len, thick;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: len,
      height: len,
      child: CustomPaint(
        painter: _BracketPainter(
          color: color,
          thick: thick,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({
    required this.color,
    required this.thick,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  final Color color;
  final double thick;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    if (topLeft) {
      canvas.drawLine(Offset.zero, Offset(w, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, h), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Scan Result Bottom Sheet ────────────────────────────────────────────────────

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.serial,
    required this.rawValue,
    required this.onVerify,
    required this.onScanAgain,
  });

  final String serial;
  final String rawValue;
  final VoidCallback onVerify;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top accent bar
          Container(
            height: 4,
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
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.08),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR TERDETEKSI',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Redline Apparel Product',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Serial number
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: AppColors.parchment,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SERIAL NUMBER',
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 8,
                          letterSpacing: 2.5,
                          color: AppColors.primary.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        serial,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tombol verifikasi (primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'VERIFIKASI KEASLIAN',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Tombol scan lagi (secondary)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onScanAgain,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'SCAN ULANG',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimConfirmSheet extends StatelessWidget {
  const _ClaimConfirmSheet({required this.onConfirm, required this.onCancel});
  final VoidCallback onConfirm, onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gradientBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.08),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR KLAIM KEPEMILIKAN',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Redline Apparel Product',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: AppColors.parchment,
                  child: Text(
                    'Item ini akan didaftarkan sebagai milik Anda.\nQR klaim hanya bisa digunakan sekali.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.inkLight,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'YA, KLAIM ITEM INI',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'BATAL',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gradientBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
            child: Column(
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
                  'MEMPROSES KLAIM...',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sedang mendaftarkan kepemilikan',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimSuccessSheet extends StatelessWidget {
  const _ClaimSuccessSheet({
    required this.productName,
    required this.serialNumber,
    required this.onDone,
  });
  final String productName, serialNumber;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gradientBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KLAIM BERHASIL',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Item terdaftar sebagai milik Anda',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _infoBox('PRODUK', productName),
                const SizedBox(height: 8),
                _infoBox(
                  'SERIAL NUMBER',
                  serialNumber.length > 20
                      ? '${serialNumber.substring(0, 20)}...'
                      : serialNumber,
                ),
                const SizedBox(height: 8),
                _infoBox('STATUS', 'Kepemilikan Terdaftar ✓'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'SELESAI',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorSheet extends StatelessWidget {
  const _ErrorSheet({required this.message, required this.onScanAgain});
  final String message;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gradientBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GAGAL',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Terjadi kesalahan',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: Colors.red.shade50,
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.red.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onScanAgain,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'SCAN ULANG',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper — gradient bar & info box (dipakai semua sheet)
Widget _gradientBar() => Container(
  height: 4,
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

Widget _infoBox(String label, String value) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  color: AppColors.parchment,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.sourceCodePro(
          fontSize: 8,
          letterSpacing: 2.5,
          color: AppColors.primary.withOpacity(0.6),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: GoogleFonts.sourceCodePro(fontSize: 11, color: AppColors.ink),
      ),
    ],
  ),
);
