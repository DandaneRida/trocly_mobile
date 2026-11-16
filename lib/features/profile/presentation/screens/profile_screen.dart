import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/reviews_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final ListingsController _listingsController = Get.find<ListingsController>();
  final ReviewsController _reviewsController = Get.find<ReviewsController>();
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

  void _confirmLogout() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 40, color: AppColors.primary),
              const SizedBox(height: 14),
              const Text(
                'Se déconnecter ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous reviendrez en mode invité. Vous pourrez vous reconnecter à tout moment avec votre numéro WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Se déconnecter',
                backgroundColor: AppColors.error,
                onPressed: () {
                  Get.back();
                  _authController.logout();
                  Get.offAllNamed('/feed');
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Get.toNamed('/notifications'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mes annonces'),
            Tab(text: 'Historique'),
            Tab(text: 'Avis reçus'),
          ],
        ),
      ),
      body: Column(
        children: [
          // User header card
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          _authController.userName.value.isNotEmpty
                              ? _authController.userName.value
                              : 'Utilisateur Trocly',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(
                        () => Text(
                          '${_authController.selectedCity.value} · ${_authController.phone.value}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text('4,9 / 5,0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(width: 10),
                          Text('12 échanges réussis', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Mes annonces
                Obx(() {
                  final list = _listingsController.listings;
                  if (list.isEmpty) {
                    return const Center(child: Text('Aucune annonce active'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final item = list[i];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${item.condition} · ${item.city}'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => Get.toNamed('/listing/${item.id}', arguments: item),
                      );
                    },
                  );
                }),
                // Tab 2: Historique
                const Center(
                  child: Text('Aucun échange archivé pour le moment', style: TextStyle(color: AppColors.textSecondary)),
                ),
                // Tab 3: Avis
                const Center(
                  child: Text('Aucun avis reçu pour le moment', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          // Logout / Delete account footer
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Se déconnecter',
                  isOutlined: true,
                  icon: Icons.logout,
                  onPressed: _confirmLogout,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Get.snackbar('Information', 'Demande de suppression prise en compte');
                  },
                  child: const Text(
                    'Supprimer mon compte définitivement',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
