import 'package:certipath_app/features/auth/application/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme.dart';
import 'google_icon.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isLoading;

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!isDisabled) setState(() => hovered = true);
      },
      onExit: (_) {
        if (!isDisabled) setState(() => hovered = false);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDisabled
                  ? AppColors.parchment.withOpacity(0.5)
                  : hovered
                  ? AppColors.parchment
                  : AppColors.paper,
              border: Border.all(
                color: isDisabled
                    ? AppColors.primaryBorder.withOpacity(0.4)
                    : AppColors.primaryBorder,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const GoogleIcon(),

                const SizedBox(width: 12),

                Text(
                  widget.isLoading ? 'SIGNING IN...' : 'CONTINUE WITH GOOGLE',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isDisabled ? Colors.black38 : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
