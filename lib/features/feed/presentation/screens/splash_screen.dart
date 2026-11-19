import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTypography.wordmark(size: 30),
              const SizedBox(height: 6),
              Text(
                'TROC LOCAL AU MAROC',
                style: AppTypography.eyebrow(color: AppColors.accent),
              ),
              const Spacer(),
              Text(
                'Donnez une seconde vie à ce que vous n\'utilisez plus.',
                style: AppTypography.serif(size: 34, height: 1.15),
              ),
              const SizedBox(height: 16),
              Text(
                'Proposez un ou plusieurs objets, négociez une soulte si besoin, et validez la rencontre par double scan QR.',
                style: AppTypography.sans(
                  size: 14,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              _FeatureRow(
                icon: Icons.location_on_outlined,
                title: 'Annonces par ville',
                subtitle: 'Explorez librement, sans créer de compte',
              ),
              const Divider(),
              _FeatureRow(
                icon: Icons.swap_horiz_rounded,
                title: 'Échange multi-objets',
                subtitle: 'Combinez plusieurs biens et ajustez en dirhams',
              ),
              const Divider(),
              _FeatureRow(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Rencontre sécurisée',
                subtitle: 'Double scan QR sur place et avis mutuels',
              ),
              const Divider(),
              const Spacer(),
              PrimaryButton(
                label: 'Explorer les annonces',
                onPressed: () => Get.offNamed('/feed'),
              ),
              const SizedBox(height: 10),
              Obx(() {
                if (auth.authToken.value.isNotEmpty) {
                  return const SizedBox.shrink();
                }
                return Center(
                  child: TextButton(
                    onPressed: () => Get.toNamed('/login'),
                    child: Text(
                      'Déjà membre ? Se connecter',
                      style: AppTypography.sans(
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.sans(
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
