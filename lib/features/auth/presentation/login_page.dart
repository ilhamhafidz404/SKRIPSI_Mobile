import 'package:certipath_app/features/auth/application/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import 'widgets/login_card.dart';
import 'widgets/dot_pattern_painter.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Login gagal'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.2,
                  colors: [Colors.transparent, Color(0x30C8BFB0)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: LoginCard(isLoading: isLoading),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
