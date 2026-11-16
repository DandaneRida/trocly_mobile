import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ListingCard extends StatelessWidget {
  final String id;
  final String title;
  final String? condition;
  final String? cityName;
  final String? relativeTime;
  final String? photoUrl;
  final VoidCallback onTap;

  const ListingCard({
    Key? key,
    required this.id,
    required this.title,
    this.condition,
    this.cityName,
    this.relativeTime,
    this.photoUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Placeholder container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(8),
                  image: photoUrl != null && photoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null || photoUrl!.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Condition · City
            Text(
              '${condition ?? 'Bon état'} · ${cityName ?? 'Meknès'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            if (relativeTime != null) ...[
              const SizedBox(height: 2),
              Text(
                relativeTime!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
