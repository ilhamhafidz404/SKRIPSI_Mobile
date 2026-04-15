import 'package:certipath_app/features/auth/application/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme.dart';
import 'google_icon.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key, required this.isLoading});
  final bool isLoading;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        onTap: widget.isLoading
            ? null
            : () => ref.read(authProvider.notifier).signInWithGoogle(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hovered ? AppColors.parchment : AppColors.paper,
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const GoogleIcon(),
              const SizedBox(width: 12),
              Text(widget.isLoading ? 'SIGNING IN...' : 'CONTINUE WITH GOOGLE'),
            ],
          ),
        ),
      ),
    );
  }
}
