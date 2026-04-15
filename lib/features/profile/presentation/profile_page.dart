import 'package:certipath_app/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/application/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),

      body: user == null
          ? const Center(child: Text('Tidak ada user'))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// 👤 AVATAR
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: user.avatar.isNotEmpty
                          ? NetworkImage(user.avatar)
                          : null,
                      child: user.avatar.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 42,
                              color: Colors.grey,
                            )
                          : null,
                    ),

                    const SizedBox(height: 18),

                    /// 👋 GREETING
                    Text(
                      'User Profile',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.inkLight,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// NAME
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        color: AppColors.ink,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// EMAIL
                    Text(
                      user.email,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// LOGOUT BUTTON (better UI)
                    SizedBox(
                      width: 180,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(authProvider.notifier).signOut(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
