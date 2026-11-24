import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Carte d'annonce moderne (style carte blanche douce + photo arrondie sur fond bleu-gris
/// avec pilule flottante « Troc » corail — zéro prix affiché)
class ListingCard extends StatelessWidget {
  final String id;
  final String title;
  final String? condition;
  final String? cityName;
  final String? relativeTime;
  final String? photoUrl;
  final String? wishLabel;
  final VoidCallback onTap;

  const ListingCard({
    Key? key,
    required this.id,
    required this.title,
    this.condition,
    this.cityName,
    this.relativeTime,
    this.photoUrl,
    this.wishLabel,
    required this.onTap,
  }) : super(key: key);

  String _formatCondition(String? raw) {
    switch (raw) {
      case 'neuf':
        return 'Neuf';
      case 'comme_neuf':
        return 'Comme neuf';
      case 'tres_bon':
        return 'Très bon';
      case 'bon':
        return 'Bon état';
      case 'use':
        return 'Usé';
      default:
        return raw ?? 'Bon état';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final wish = (wishLabel != null && wishLabel!.trim().isNotEmpty)
        ? wishLabel!.trim()
        : 'Ouvert au troc';
    final isSpecificWish = wishLabel != null &&
        wishLabel!.trim().isNotEmpty &&
        wishLabel!.toLowerCase() != 'échange ouvert';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo arrondie 20px + pilule flottante Troc en bas
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholder,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: hasPhoto
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                // Badge ville discret en haut à gauche
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          cityName ?? 'Meknès',
                          style: AppTypography.sans(
                            size: 10.5,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pilule flottante « Troc » inspirée du design moderne
                Positioned(
                  bottom: -10,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
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
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _formatCondition(condition),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.sans(
                                    size: 10.5,
                                    weight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Titre gras moderne
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          // Souhait d'échange
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: isSpecificWish ? AppColors.accent : AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  wish,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    size: 11.5,
                    weight: isSpecificWish ? FontWeight.w600 : FontWeight.w400,
                    color: isSpecificWish
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.photo_outlined,
          color: AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}
