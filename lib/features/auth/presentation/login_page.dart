import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/auth_provider.dart';
import 'widgets/login_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      // Mengatur status bar agar tetap putih (light) di atas gambar gelap
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1654676066221-500d63a81951?q=80&w=1740&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', // Gambar bertema Blockchain/Tech
              fit: BoxFit.cover,
            ),
          ),

          // 2. Dark Overlay (Untuk memastikan teks & glass tetap kontras)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branding Header
                    _buildHeroSection(),

                    const SizedBox(height: 50),

                    // GLASSMORPHISM CARD
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: LoginCard(
                            isLoading: isLoading,
                            onGoogleSignIn: () {
                              if (!isLoading) {
                                HapticFeedback.heavyImpact();
                                ref
                                    .read(authProvider.notifier)
                                    .signInWithGoogle();
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    _buildVersionInfo(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Text(
          'CertiPath',
          style: GoogleFonts.lexend(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Securing Authenticity on Chain',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Text(
      'Version 1.0.0 (Beta)',
      style: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.white.withOpacity(0.5),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
