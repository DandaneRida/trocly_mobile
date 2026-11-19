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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTypography.wordmark(size: 28),
                          const SizedBox(height: 4),
                          Text(
                            'TROC LOCAL AU MAROC',
                            style: AppTypography.eyebrow(color: AppColors.accent),
                          ),
                          const SizedBox(height: 18),

                          // Editorial exchange hero photo bundled in assets/images/
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.imagePlaceholder,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.asset(
                                  'assets/images/welcome_exchange.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          Text(
                            'Donnez une seconde vie à ce que vous n\'utilisez plus.',
                            style: AppTypography.serif(size: 30, height: 1.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Proposez un ou plusieurs objets, négociez une soulte si besoin, et validez la rencontre par double scan QR.',
                            style: AppTypography.sans(
                              size: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Divider(),
                          const _FeatureRow(
                            icon: Icons.location_on_outlined,
                            title: 'Annonces par ville',
                            subtitle: 'Explorez librement, sans créer de compte',
                          ),
                          const Divider(),
                          const _FeatureRow(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Échange multi-objets',
                            subtitle: 'Combinez plusieurs biens et ajustez en dirhams',
                          ),
                          const Divider(),
                          const _FeatureRow(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Rencontre sécurisée',
                            subtitle: 'Double scan QR sur place et avis mutuels',
                          ),
                          const Divider(),
                          const Spacer(),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Explorer les annonces',
                            onPressed: () => Get.offNamed('/feed'),
                          ),
                          const SizedBox(height: 8),
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
                ),
              ),
            );
          },
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
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.ink),
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
