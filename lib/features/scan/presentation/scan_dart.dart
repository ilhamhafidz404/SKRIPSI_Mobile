import 'dart:async';
import 'package:certipath_app/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ── Handle deteksi QR ───────────────────────────────────────────────────────
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

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Pause kamera
    _controller.stop();

    // Ekstrak serial dari URL atau langsung pakai raw value
    // Format URL: http://localhost:8080/api/verify/{serial}
    // Format langsung: uuid string
    final serial = _extractSerial(rawValue);

    // Tampilkan bottom sheet hasil scan
    _showResultSheet(context, serial, rawValue);
  }

  // Ekstrak serial number dari URL jika QR berisi URL verifikasi
  String _extractSerial(String raw) {
    try {
      final uri = Uri.parse(raw);
      final segments = uri.pathSegments;
      // /api/verify/{serial} → ambil segment terakhir
      if (segments.isNotEmpty) return segments.last;
    } catch (_) {}
    return raw; // kalau bukan URL, pakai langsung
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
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScanResultSheet(
        serial: serial,
        rawValue: rawValue,
        onVerify: () {
          Navigator.pop(context); // tutup sheet
          // Navigate ke halaman verifikasi
          Navigator.pushNamed(context, '/verify/$serial').then((_) {
            _resetScan(); // reset setelah kembali
          });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
