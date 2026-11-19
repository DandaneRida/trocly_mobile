import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

class AuthGuardBottomSheet extends StatelessWidget {
  final String? customTitle;
  final String? customSubtitle;

  const AuthGuardBottomSheet({
    Key? key,
    this.customTitle,
    this.customSubtitle,
  }) : super(key: key);

  static Future<bool> checkAuthOrShow(BuildContext context, {required bool isLoggedIn}) async {
    if (isLoggedIn) return true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (ctx) => const AuthGuardBottomSheet(),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                size: 28,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              customTitle ?? 'Connectez-vous pour échanger',
              textAlign: TextAlign.center,
              style: AppTypography.serif(size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              customSubtitle ??
                  'Vérifiez votre numéro WhatsApp (+212) pour publier, proposer un échange et discuter en direct.',
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                size: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Continuer avec WhatsApp',
              icon: Icons.phone_outlined,
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed('/login');
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Plus tard',
                style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
