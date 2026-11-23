import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// En-tête de marque uniforme : affiche le logo « trocly. » cliquable (retour Accueil)
/// suivi optionnellement du titre de la page courante.
class TroclyAppBarTitle extends StatelessWidget {
  final String? pageTitle;
  final bool darkBackground;

  const TroclyAppBarTitle({
    Key? key,
    this.pageTitle,
    this.darkBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fg = darkBackground ? Colors.white : AppColors.ink;
    final sub = darkBackground
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (Get.currentRoute != '/feed') {
              Get.offAllNamed('/feed');
            }
          },
          child: AppTypography.wordmark(size: 20, color: fg),
        ),
        if (pageTitle != null && pageTitle!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '·',
              style: AppTypography.sans(
                size: 16,
                weight: FontWeight.w600,
                color: sub,
              ),
            ),
          ),
          Flexible(
            child: Text(
              pageTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                size: 14.5,
                weight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
