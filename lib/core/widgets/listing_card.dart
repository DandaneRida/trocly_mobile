import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Carte d'annonce éditoriale : photo plein bord sans boîte lourde, titre,
/// état/ville discret et désir d'échange en terre cuite.
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
        return 'Très bon état';
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
        : 'Ouvert aux propositions';
    final isSpecificWish = wishLabel != null &&
        wishLabel!.trim().isNotEmpty &&
        wishLabel!.toLowerCase() != 'échange ouvert';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo carrée plein bord
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                color: AppColors.imagePlaceholder,
                child: hasPhoto
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Titre
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              size: 13.5,
              weight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          // État · Ville
          Text(
            '${_formatCondition(condition)} · ${cityName ?? 'Meknès'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              size: 11.5,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          // Désir d'échange
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 13,
                color: isSpecificWish ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  wish,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    size: 11.5,
                    weight: isSpecificWish ? FontWeight.w500 : FontWeight.w400,
                    color: isSpecificWish ? AppColors.accent : AppColors.textSecondary,
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
    return const Center(
      child: Icon(
        Icons.photo_outlined,
        color: AppColors.textHint,
        size: 30,
      ),
    );
  }
}
