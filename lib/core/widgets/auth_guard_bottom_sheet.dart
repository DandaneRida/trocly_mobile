import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AuthGuardBottomSheet(),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horizontal_circle_outlined,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            customTitle ?? 'Connectez-vous via WhatsApp pour échanger',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customSubtitle ??
                'Rejoignez la communauté locale vérifiée pour proposer des échanges, publier des annonces et discuter en temps réel.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Continuer avec WhatsApp',
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed('/login');
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Plus tard',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
