import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../controllers/reviews_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthController _auth = Get.find<AuthController>();
  final ListingsController _listings = Get.find<ListingsController>();
  final ReviewsController _reviews = Get.find<ReviewsController>();
  final MeetingController _meetings = Get.find<MeetingController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.authToken.value.isNotEmpty) {
        _listings.fetchMyListings();
        _meetings.fetchMyMeetings();
        if (_auth.userId.value.isNotEmpty) {
          _reviews.fetchUserStats(_auth.userId.value);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Paramètres', style: AppTypography.serif(size: 22)),
              const SizedBox(height: 12),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined, color: AppColors.ink),
                title: Text('Gérer mes annonces', style: AppTypography.sans(size: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.toNamed('/my-listings');
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none_rounded, color: AppColors.ink),
                title: Text('Notifications', style: AppTypography.sans(size: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.toNamed('/notifications');
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(
                  'Se déconnecter',
                  style: AppTypography.sans(size: 14, color: AppColors.error, weight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _auth.logout();
                },
              ),
            ],
          ),
        ),
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
        title: Text('Profil', style: AppTypography.sans(size: 16, weight: FontWeight.w600)),
        actions: [
          Obx(() {
            if (_auth.authToken.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              onPressed: _showSettingsSheet,
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
                'Suivez votre score de confiance, vos annonces, vos rendez-vous QR et vos avis.',
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

        return Column(
          children: [
            // Identity header (matching Phone 8 of v3 mockup)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.bubble,
                    child: Text(
                      initials.isEmpty ? 'T' : initials,
                      style: AppTypography.serif(size: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: AppTypography.serif(size: 22)),
                        const SizedBox(height: 2),
                        Text(
                          '${_auth.selectedCity.value}${_auth.phone.value.isNotEmpty ? ' · ${_auth.phone.value}' : ''}',
                          style: AppTypography.sans(size: 12.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 5),
                            Text(
                              'Téléphone vérifié',
                              style: AppTypography.sans(
                                size: 11.5,
                                weight: FontWeight.w500,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3-column hairline stats strip (Confiance / Échanges / Avis)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  _statCell('$trustScore', 'Confiance'),
                  Container(width: 1, height: 34, color: AppColors.line),
                  _statCell('$exchanges', 'Échanges'),
                  Container(width: 1, height: 34, color: AppColors.line),
                  _statCell(
                    totalReviews > 0 ? avgRating.toStringAsFixed(1).replaceAll('.', ',') : '—',
                    '$totalReviews avis',
                  ),
                ],
              ),
            ),

            // Underlined tabs
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.ink,
                indicatorWeight: 2,
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.sans(size: 13, weight: FontWeight.w600),
                unselectedLabelStyle: AppTypography.sans(size: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Annonces · ${_listings.myListings.length}'),
                  Tab(text: 'Avis · $totalReviews'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: 3-column photo grid of my listings
                  _buildListingsGrid(),
                  // Tab 2: Received reviews
                  _buildReviewsList(stats?.reviews ?? const []),
                  // Tab 3: Meetings / exchanges history
                  _buildHistoryList(),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _statCell(String number, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(number, style: AppTypography.serif(size: 23)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.sans(size: 11.5, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildListingsGrid() {
    final items = _listings.myListings;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aucune annonce', style: AppTypography.serif(size: 19)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: PrimaryButton(
                  label: 'Publier un objet',
                  onPressed: () => Get.toNamed('/publish'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (_, idx) {
        final item = items[idx];
        final isExchanged = item.status == 'exchanged';
        return InkWell(
          onTap: () => Get.toNamed('/listing/${item.id}', arguments: item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: isExchanged ? 0.45 : 1.0,
                  child: Container(
                    color: AppColors.imagePlaceholder,
                    child: item.photos.isNotEmpty
                        ? Image.network(item.photos.first, fit: BoxFit.cover)
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                item.title,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sans(size: 10.5, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                  ),
                ),
                if (isExchanged)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.paper.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Échangé',
                        style: AppTypography.sans(size: 10, weight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return Center(
        child: Text(
          'Aucun avis publié pour l\'instant.',
          style: AppTypography.sans(size: 13, color: AppColors.textHint),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, idx) {
        final r = reviews[idx];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.reviewerName, style: AppTypography.sans(size: 13.5, weight: FontWeight.w600)),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14,
                        color: i < r.rating ? AppColors.ink : AppColors.borderStrong,
                      ),
                    ),
                  ),
                ],
              ),
              if (r.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: r.tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bubble,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(t, style: AppTypography.sans(size: 11)),
                          ))
                      .toList(),
                ),
              ],
              if (r.comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  r.comment,
                  style: AppTypography.sans(size: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    final list = _meetings.myMeetings;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Aucun rendez-vous enregistré.',
          style: AppTypography.sans(size: 13, color: AppColors.textHint),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, idx) {
        final m = list[idx];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(m.proposedLocation, style: AppTypography.sans(size: 13.5, weight: FontWeight.w500)),
          subtitle: Text(
            '${m.scheduledAt.day}/${m.scheduledAt.month}/${m.scheduledAt.year} · ${m.status}',
            style: AppTypography.sans(size: 12, color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          onTap: () => Get.toNamed('/my-qr/${m.id}'),
        );
      },
    );
  }
}
