import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'google_signin_button.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({
    super.key,
    required this.isLoading,
    required this.onGoogleSignIn,
  });

  final bool isLoading;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'IN COLLABORATION WITH',
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'REDLINE APPAREL',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),
          Container(height: 1, width: 40, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 20),

          Text(
            'Sign in to access your secure\nproduct verification',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 40),

          GoogleSignInButton(isLoading: isLoading, onPressed: onGoogleSignIn),

          const SizedBox(height: 16),

          // Tambahan teks kecil keamanan
          Text(
            'Encrypted by CertiPath Protocol',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white.withOpacity(0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
