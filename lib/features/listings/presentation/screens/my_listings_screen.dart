import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  final ListingsController _listingsController = Get.find<ListingsController>();
  late TabController _tabController;

  final List<String> _statuses = ['active', 'archived', 'exchanged'];
  String? _publishedBannerText;

  @override
  void initState() {
    super.initState();
    if (Get.arguments is Map && (Get.arguments as Map)['justPublished'] == true) {
      final args = Get.arguments as Map;
      final city = args['city'] ?? 'votre ville';
      _publishedBannerText = 'Annonce publiée ! Visible à $city.';
    }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _listingsController.fetchMyListings(status: _statuses[_tabController.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listingsController.fetchMyListings(status: 'active');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'active':
        return 'Active';
      case 'archived':
        return 'Archivée';
      case 'exchanged':
        return 'Échangée';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 2),
      appBar: AppBar(
        title: const TroclyAppBarTitle(pageTitle: 'Mes annonces'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final res = await Get.toNamed('/publish');
              if (res == true) {
                _listingsController.fetchMyListings(status: _statuses[_tabController.index]);
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.accent),
            label: Text(
              'Publier',
              style: AppTypography.sans(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2.5,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.sans(size: 13.5, weight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.sans(size: 13.5, weight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Actives'),
                Tab(text: 'Archivées'),
                Tab(text: 'Échangées'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_publishedBannerText != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _publishedBannerText!,
                      style: AppTypography.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListingsList('active'),
                _buildListingsList('archived'),
                _buildListingsList('exchanged'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsList(String statusFilter) {
    return Obx(() {
      if (_listingsController.isMyListingsLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
        );
      }

      final list = _listingsController.myListings;
      if (list.isEmpty) {
        return StatePage(
          type: StatePageType.emptyResults,
          customTitle: 'Aucune annonce ${_statusLabel(statusFilter).toLowerCase()}',
          customMessage: statusFilter == 'active'
              ? 'Publiez un objet pour commencer à recevoir des propositions d\'échange.'
              : 'Vos annonces ${_statusLabel(statusFilter).toLowerCase()}s apparaîtront ici.',
          actionLabel: statusFilter == 'active' ? 'Publier un objet' : null,
          onAction: statusFilter == 'active'
              ? () async {
                  final res = await Get.toNamed('/publish');
                  if (res == true) _listingsController.fetchMyListings(status: 'active');
                }
              : null,
        );
      }

      return RefreshIndicator(
        onRefresh: () => _listingsController.fetchMyListings(status: statusFilter),
        color: AppColors.ink,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, idx) {
            final item = list[idx];
            return InkWell(
              onTap: () => Get.toNamed('/listing/${item.id}', arguments: item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: AppColors.imagePlaceholder,
                        child: item.photos.isNotEmpty
                            ? Image.network(
                                item.photos.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.photo_outlined,
                                  color: AppColors.textHint,
                                ),
                              )
                            : const Icon(Icons.photo_outlined, color: AppColors.textHint),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sans(size: 14, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.category} · ${item.city}',
                            style: AppTypography.sans(size: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.status == 'active'
                                  ? AppColors.successLight
                                  : AppColors.bubble,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _statusLabel(item.status),
                              style: AppTypography.sans(
                                size: 11,
                                weight: FontWeight.w600,
                                color: item.status == 'active'
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                      color: AppColors.surface,
                      onSelected: (val) async {
                        if (val == 'archive') {
                          final ok = await _listingsController.changeListingStatus(item.id, 'archived');
                          if (ok) _listingsController.fetchMyListings(status: statusFilter);
                        } else if (val == 'reactivate') {
                          final ok = await _listingsController.changeListingStatus(item.id, 'active');
                          if (ok) _listingsController.fetchMyListings(status: statusFilter);
                        } else if (val == 'delete') {
                          final confirmed = await Get.dialog<bool>(
                            AlertDialog(
                              backgroundColor: AppColors.paper,
                              title: Text('Supprimer l\'annonce', style: AppTypography.serif(size: 20)),
                              content: Text(
                                'Voulez-vous supprimer « ${item.title} » ?',
                                style: AppTypography.sans(size: 13.5, color: AppColors.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: Text('Annuler', style: AppTypography.sans(color: AppColors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  child: Text(
                                    'Supprimer',
                                    style: AppTypography.sans(color: AppColors.error, weight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            final ok = await _listingsController.deleteListing(item.id);
                            if (ok) _listingsController.fetchMyListings(status: statusFilter);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        if (item.status == 'active')
                          const PopupMenuItem(value: 'archive', child: Text('Archiver')),
                        if (item.status == 'archived')
                          const PopupMenuItem(value: 'reactivate', child: Text('Réactiver')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
