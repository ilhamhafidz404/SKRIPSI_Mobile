import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatelessWidget {
  const ScanQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR'), centerTitle: true),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;

          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;

            if (code != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('QR: $code')));
            }
          }
        },
      ),
    );
  }
}
