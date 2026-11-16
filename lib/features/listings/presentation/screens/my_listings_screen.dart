import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/listing_card.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  final ListingsController _listingsController = Get.find<ListingsController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        onPressed: () => Get.toNamed('/publish'),
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
      final list = _listingsController.listings;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                'Aucune annonce $statusFilter',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
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
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'archive') {
                      Get.snackbar('Annonce', 'Annonce archivée');
                    } else if (val == 'delete') {
                      Get.snackbar('Annonce', 'Annonce supprimée');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(value: 'archive', child: Text('Archiver')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
