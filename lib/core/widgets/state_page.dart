import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'primary_button.dart';

enum StatePageType {
  offline,
  emptyCity,
  emptyResults,
  offerExpired,
  meetingExpired,
  qrFailed,
  loading,
}

class StatePage extends StatelessWidget {
  final StatePageType type;
  final String? customTitle;
  final String? customMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StatePage({
    Key? key,
    required this.type,
    this.customTitle,
    this.customMessage,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  IconData _icon() {
    switch (type) {
      case StatePageType.offline:
        return Icons.wifi_off_rounded;
      case StatePageType.emptyCity:
      case StatePageType.emptyResults:
        return Icons.search_off_rounded;
      case StatePageType.offerExpired:
      case StatePageType.meetingExpired:
        return Icons.timer_off_outlined;
      case StatePageType.qrFailed:
        return Icons.qr_code_scanner_rounded;
      case StatePageType.loading:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _title() {
    if (customTitle != null) return customTitle!;
    switch (type) {
      case StatePageType.offline:
        return 'Aucune connexion internet';
      case StatePageType.emptyCity:
        return 'Aucune annonce dans cette ville';
      case StatePageType.emptyResults:
        return 'Aucun résultat trouvé';
      case StatePageType.offerExpired:
        return 'Cette offre a expiré';
      case StatePageType.meetingExpired:
        return 'Rendez-vous expiré (> 2 h)';
      case StatePageType.qrFailed:
        return 'Échec du scan QR';
      case StatePageType.loading:
        return 'Chargement en cours...';
    }
  }

  String _message() {
    if (customMessage != null) return customMessage!;
    switch (type) {
      case StatePageType.offline:
        return 'Vérifiez votre connexion Wi-Fi ou vos données mobiles et réessayez.';
      case StatePageType.emptyCity:
        return 'Soyez le premier à publier un objet ou élargissez votre recherche aux autres villes.';
      case StatePageType.emptyResults:
        return 'Essayez de modifier vos filtres ou vos critères de recherche.';
      case StatePageType.offerExpired:
        return 'Le délai de réponse est dépassé. Vous pouvez créer une nouvelle proposition.';
      case StatePageType.meetingExpired:
        return 'Le créneau de rencontre est dépassé de plus de 2 heures sans double scan.';
      case StatePageType.qrFailed:
        return 'Le QR code scanné n\'a pas pu être validé. Veuillez réessayer.';
      case StatePageType.loading:
        return 'Veuillez patienter pendant la récupération des données.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(), size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              _title(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
