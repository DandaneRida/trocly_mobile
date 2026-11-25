import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/favorites_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../controllers/reviews_controller.dart';
import '../../../../core/i18n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

/// Écran Profil moderne : avatar centré avec pastille corail, carte stats blanche,
/// onglets pilules corail et cartes blanches arrondies pour Mes annonces / Historique / Avis.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _auth = Get.find<AuthController>();
  final ListingsController _listings = Get.find<ListingsController>();
  final ReviewsController _reviews = Get.find<ReviewsController>();
  final MeetingController _meetings = Get.find<MeetingController>();

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfileData();
    });
  }

  Future<void> _refreshProfileData() async {
    if (_auth.authToken.value.isEmpty) return;
    await Future.wait([
      _listings.fetchMyListings(),
      _meetings.fetchMyMeetings(),
      if (_auth.userId.value.isNotEmpty)
        _reviews.fetchUserStats(_auth.userId.value),
    ]);
  }

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Se déconnecter ?', style: AppTypography.serif(size: 20)),
        content: Text(
          'Vous reviendrez en mode invité. Vous pourrez vous reconnecter à tout moment avec votre numéro WhatsApp.',
          style: AppTypography.sans(
              size: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler',
                style: AppTypography.sans(
                    color: AppColors.textSecondary, weight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _auth.logout();
            },
            child: Text(
              'Se déconnecter',
              style: AppTypography.sans(
                  color: AppColors.error, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const TroclyAppBarTitle(pageTitle: 'Profil'),
        actions: [
          Obx(() {
            if (_auth.authToken.value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  TroclyCircleIconBtn(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifications',
                    onTap: () => Get.toNamed('/notifications'),
                  ),
                  const SizedBox(width: 8),
                  TroclyCircleIconBtn(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    tooltip: 'Se déconnecter',
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_auth.authToken.value.isEmpty) {
          return StatePage(
            type: StatePageType.emptyResults,
            customTitle: 'Connectez-vous à votre profil',
            customMessage:
                'Consultez vos propres annonces, votre score de confiance, vos rendez-vous QR et vos avis.',
            actionLabel: 'Se connecter',
            onAction: () => Get.toNamed('/login'),
          );
        }

        final displayName = _auth.userName.value.isNotEmpty
            ? _auth.userName.value
            : 'Membre Trocly';
        final initials = displayName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();
        final stats = _reviews.userStats.value;
        final trustScore = stats?.trustScore ?? 75;
        final exchanges = stats?.completedExchanges ?? 0;
        final avgRating = stats?.averageRating ?? 0.0;
        final totalReviews = stats?.totalReviews ?? 0;

        return RefreshIndicator(
          onRefresh: _refreshProfileData,
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              // Avatar centré moderne (style Account du modèle)
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: AppColors.imagePlaceholder,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.surface, width: 4),
                            boxShadow: AppColors.cardShadow,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials.isEmpty ? 'T' : initials,
                            style: AppTypography.serif(
                              size: 28,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surface, width: 2.5),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(displayName, style: AppTypography.serif(size: 22)),
                    const SizedBox(height: 4),
                    Text(
                      '${_auth.selectedCity.value}${_auth.phone.value.isNotEmpty ? ' · ${_auth.phone.value}' : ''}',
                      style: AppTypography.sans(
                          size: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Carte blanche stats de confiance (3 colonnes)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    _statCell('$trustScore%', 'Confiance', highlight: true),
                    Container(width: 1, height: 34, color: AppColors.line),
                    _statCell('$exchanges', 'Échanges'),
                    Container(width: 1, height: 34, color: AppColors.line),
                    _statCell(
                      totalReviews > 0
                          ? avgRating.toStringAsFixed(1).replaceAll('.', ',')
                          : '—',
                      '$totalReviews avis',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Barre d'onglets pilules blanches + capsule corail active
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: AppColors.pillShadow,
                ),
                child: Row(
                  children: [
                    _pillTab(0, 'Annonces (${_listings.myListings.length})'),
                    _pillTab(1, 'RDV (${_meetings.myMeetings.length})'),
                    _pillTab(2, 'Avis ($totalReviews)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contenu de l'onglet sélectionné
              if (_selectedTab == 0) _buildMyListings(),
              if (_selectedTab == 1) _buildHistoryList(),
              if (_selectedTab == 2)
                _buildReviewsList(stats?.reviews ?? const []),

              const SizedBox(height: 18),

              // Raccourcis en cartes blanches (style menu Account)
              if (Get.isRegistered<FavoritesController>())
                Obx(() {
                  final favCount =
                      Get.find<FavoritesController>().favoriteIds.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _menuCardTile(
                      icon: Icons.favorite_border_rounded,
                      title: '${'favorites'.tr} ($favCount)',
                      onTap: () => Get.toNamed('/favorites'),
                    ),
                  );
                }),
              _menuCardTile(
                icon: Icons.add_box_outlined,
                title: 'publish_item'.tr,
                onTap: () => Get.toNamed('/publish'),
              ),
              const SizedBox(height: 10),
              _menuCardTile(
                icon: Icons.inventory_2_outlined,
                title: 'Gérer toutes mes annonces',
                onTap: () => Get.toNamed('/my-listings'),
              ),
              const SizedBox(height: 10),
              if (Get.isRegistered<LocaleController>())
                Obx(() {
                  final localeCtrl = Get.find<LocaleController>();
                  final isAr = localeCtrl.isArabic.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _menuCardTile(
                      icon: Icons.translate_rounded,
                      title: isAr
                          ? 'اللغة : Français (LTR)'
                          : 'Langue : العربية (RTL)',
                      onTap: localeCtrl.toggleLanguage,
                    ),
                  );
                }),
              _menuCardTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'admin_panel'.tr,
                onTap: () => Get.toNamed('/admin'),
              ),
              const SizedBox(height: 10),
              _menuCardTile(
                icon: Icons.logout_rounded,
                title: 'Se déconnecter',
                iconColor: AppColors.error,
                titleColor: AppColors.error,
                onTap: _confirmLogout,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _pillTab(int index, String label) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              size: 12.5,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCell(String number, String label, {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            number,
            style: AppTypography.serif(
              size: 20,
              color: highlight ? AppColors.accent : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  AppTypography.sans(size: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _menuCardTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.accent).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor ?? AppColors.accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: AppTypography.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: titleColor ?? AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: titleColor ?? AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildMyListings() {
    if (_listings.isMyListingsLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2.5),
        ),
      );
    }
    final items = _listings.myListings;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Text('Aucune annonce publiée',
                style: AppTypography.serif(size: 17)),
            const SizedBox(height: 6),
            Text(
              'Ajoutez un objet pour commencer à proposer des échanges.',
              textAlign: TextAlign.center,
              style:
                  AppTypography.sans(size: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 210),
              child: PrimaryButton(
                label: 'Publier un objet',
                height: 44,
                onPressed: () => Get.toNamed('/publish'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return GestureDetector(
          onTap: () => Get.toNamed('/listing/${item.id}', arguments: item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: AppColors.imagePlaceholder,
                    child: item.photos.isNotEmpty
                        ? Image.network(item.photos.first, fit: BoxFit.cover)
                        : const Icon(Icons.photo_outlined,
                            color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                              size: 14.5, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${item.condition} · ${item.city}',
                          style: AppTypography.sans(
                              size: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status == 'active'
                        ? AppColors.successLight
                        : AppColors.bubble,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.status == 'active' ? 'Active' : item.status,
                    style: AppTypography.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: item.status == 'active'
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryList() {
    final list = _meetings.myMeetings;
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Center(
          child: Text(
            'Aucun rendez-vous enregistré pour le moment.',
            style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: list.map((m) {
        final isCancelled = m.status == 'cancelled';
        final isExpired = m.status == 'expired';
        final isAccepted = m.status == 'accepted';
        final isValidated = m.status == 'validated' || m.status == 'completed';

        final Color badgeBg = (isAccepted || isValidated)
            ? AppColors.successLight
            : isCancelled
                ? AppColors.errorLight
                : isExpired
                    ? AppColors.bubble
                    : AppColors.accentLight;
        final Color badgeFg = (isAccepted || isValidated)
            ? AppColors.success
            : isCancelled
                ? AppColors.error
                : isExpired
                    ? AppColors.textSecondary
                    : AppColors.accent;

        return GestureDetector(
          onTap: () async {
            await Get.toNamed('/my-qr/${m.id}');
            _meetings.fetchMyMeetings();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.event_busy_rounded
                        : isValidated
                            ? Icons.verified_rounded
                            : Icons.qr_code_2_rounded,
                    size: 20,
                    color: badgeFg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.proposedLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w700,
                          color: isCancelled ? AppColors.textSecondary : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${m.scheduledAt.day.toString().padLeft(2, '0')}/${m.scheduledAt.month.toString().padLeft(2, '0')}/${m.scheduledAt.year}',
                        style: AppTypography.sans(
                            size: 12, color: AppColors.textSecondary),
                      ),
                      if (isCancelled &&
                          m.cancelReason != null &&
                          m.cancelReason!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          m.cancelReason!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    m.statusLabel,
                    style: AppTypography.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: badgeFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Center(
          child: Text(
            'Aucun avis reçu pour le moment.',
            style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: reviews.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.reviewerName,
                      style: AppTypography.sans(
                          size: 14, weight: FontWeight.w700)),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < r.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: i < r.rating
                            ? const Color(0xFFF5B400)
                            : AppColors.borderStrong,
                      ),
                    ),
                  ),
                ],
              ),
              if (r.comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(r.comment,
                    style: AppTypography.sans(
                        size: 13,
                        color: AppColors.textSecondary,
                        height: 1.45)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
