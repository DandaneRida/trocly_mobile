import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  final ListingsController _listingsController = Get.find<ListingsController>();
  late TabController _tabController;

  final List<String> _statuses = ['active', 'archived', 'exchanged'];

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes annonces'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Actives'),
            Tab(text: 'Archivées'),
            Tab(text: 'Échangées'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvel objet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await Get.toNamed('/publish');
          if (res == true) {
            _listingsController.fetchMyListings(status: _statuses[_tabController.index]);
          }
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingsList('active'),
          _buildListingsList('archived'),
          _buildListingsList('exchanged'),
        ],
      ),
    );
  }

  Widget _buildListingsList(String statusFilter) {
    return Obx(() {
      if (_listingsController.isMyListingsLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      final list = _listingsController.myListings;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                'Aucune annonce ($statusFilter)',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _listingsController.fetchMyListings(status: statusFilter),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) {
            final item = list[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(8),
                      image: item.photos.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(item.photos.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.photos.isEmpty
                        ? const Icon(Icons.image_outlined, color: AppColors.textSecondary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.condition} · ${item.city}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Statut: ${item.status}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.status == 'active' ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                    onSelected: (val) async {
                      if (val == 'archive') {
                        final success = await _listingsController.changeListingStatus(item.id, 'archived');
                        if (success) {
                          _listingsController.fetchMyListings(status: statusFilter);
                        }
                      } else if (val == 'reactivate') {
                        final success = await _listingsController.changeListingStatus(item.id, 'active');
                        if (success) {
                          _listingsController.fetchMyListings(status: statusFilter);
                        }
                      } else if (val == 'delete') {
                        final confirmed = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Supprimer l\'annonce'),
                            content: Text('Voulez-vous vraiment supprimer "${item.title}" ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final success = await _listingsController.deleteListing(item.id);
                          if (success) {
                            _listingsController.fetchMyListings(status: statusFilter);
                          }
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
            );
          },
        ),
      );
    });
  }
}
