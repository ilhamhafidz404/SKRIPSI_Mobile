import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme.dart';
import 'google_signin_button.dart';

class LoginCard extends ConsumerWidget {
  const LoginCard({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 32),
      child: Column(
        children: [
          Text(
            'REDLINE APPAREL',
            style: GoogleFonts.sourceCodePro(
              fontSize: 9,
              letterSpacing: 5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'CERTIPATH',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              letterSpacing: 4,
              color: AppColors.ink,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Sign in to access dashboard',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13),
          ),

          const SizedBox(height: 28),

          GoogleSignInButton(isLoading: isLoading),
        ],
      ),
    );
  }
}
