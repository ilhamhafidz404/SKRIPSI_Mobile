import 'package:certipath_app/features/auth/application/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.ecru,
      appBar: AppBar(
        title: const Text('CERTIPATH'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.avatar.isNotEmpty == true)
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(user!.avatar),
              ),
            const SizedBox(height: 16),
            Text(
              'Selamat datang,',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkLight),
            ),
            Text(
              user?.name ?? '',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
