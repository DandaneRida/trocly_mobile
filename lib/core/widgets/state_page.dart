import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
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
        return Icons.schedule_rounded;
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
        return 'Rien dans cette ville pour l\'instant';
      case StatePageType.emptyResults:
        return 'Aucun résultat';
      case StatePageType.offerExpired:
        return 'Cette offre a expiré';
      case StatePageType.meetingExpired:
        return 'Rendez-vous expiré';
      case StatePageType.qrFailed:
        return 'Échec du scan';
      case StatePageType.loading:
        return 'Chargement…';
    }
  }

  String _message() {
    if (customMessage != null) return customMessage!;
    switch (type) {
      case StatePageType.offline:
        return 'Vérifiez votre connexion et réessayez.';
      case StatePageType.emptyCity:
        return 'Publiez le premier objet ou changez de ville pour élargir la recherche.';
      case StatePageType.emptyResults:
        return 'Essayez d\'assouplir vos filtres ou de chercher un autre terme.';
      case StatePageType.offerExpired:
        return 'Le délai de réponse est dépassé. Vous pouvez soumettre une nouvelle proposition.';
      case StatePageType.meetingExpired:
        return 'Le créneau est dépassé de plus de 2 heures sans double scan.';
      case StatePageType.qrFailed:
        return 'Le code scanné n\'a pas pu être validé. Réessayez face au code de l\'autre participant.';
      case StatePageType.loading:
        return 'Récupération des données en cours.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.bubble,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(_icon(), size: 28, color: AppColors.ink),
            ),
            const SizedBox(height: 18),
            Text(
              _title(),
              textAlign: TextAlign.center,
              style: AppTypography.serif(size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              _message(),
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                size: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: PrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
