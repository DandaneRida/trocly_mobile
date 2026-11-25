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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: AppTypography.wordmark(size: 28)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'TROC AU MAROC',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.eyebrow(
                                      color: AppColors.accent),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Carte héro arrondie 24px avec badge flottant
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.imagePlaceholder,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: Image.asset(
                                    'assets/images/welcome_exchange.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surface
                                      .withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppColors.pillShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      '100 % troc · Zéro frais',
                                      style: AppTypography.sans(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        Text(
                          'Échangez ce que vous n\'utilisez plus.',
                          style: AppTypography.serif(size: 28, height: 1.15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Proposez un ou plusieurs objets près de chez vous, discutez en direct et validez la rencontre par double scan QR.',
                          style: AppTypography.sans(
                            size: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const _FeatureCard(
                          icon: Icons.location_on_rounded,
                          title: 'Annonces par ville',
                          subtitle: 'Explorez librement, sans créer de compte',
                        ),
                        const SizedBox(height: 10),
                        const _FeatureCard(
                          icon: Icons.swap_horiz_rounded,
                          title: 'Échange multi-objets',
                          subtitle: 'Combinez plusieurs biens, soulte optionnelle',
                        ),
                        const SizedBox(height: 10),
                        const _FeatureCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Rencontre sécurisée',
                          subtitle: 'Double scan QR sur place et avis mutuels',
                        ),

                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: 'Explorer les annonces',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => Get.offNamed('/feed'),
                        ),
                        const SizedBox(height: 6),
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
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          );
                        }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: AppColors.accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.sans(size: 13.5, weight: FontWeight.w700),
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
