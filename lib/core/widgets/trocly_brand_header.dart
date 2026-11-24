import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// En-tête de marque moderne : logo « trocly. » cliquable + titre de page
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
          child: AppTypography.wordmark(size: 21, color: fg),
        ),
        if (pageTitle != null && pageTitle!.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 9),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: sub.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
          ),
          Flexible(
            child: Text(
              pageTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                size: 15,
                weight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bouton icône circulaire blanc pur avec ombre douce (signature design moderne)
class TroclyCircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final int badgeCount;
  final String? tooltip;

  const TroclyCircleIconBtn({
    Key? key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.badgeCount = 0,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppColors.pillShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.ink),
            if (badgeCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
