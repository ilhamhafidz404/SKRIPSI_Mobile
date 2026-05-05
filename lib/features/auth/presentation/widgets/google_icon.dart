import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/google.png',
      height: 20,
      width: 20,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.g_mobiledata, color: Colors.red, size: 24);
      },
    );
  }
}
