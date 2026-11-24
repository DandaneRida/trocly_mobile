import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/notifications_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ListingsController _listingsController = Get.find<ListingsController>();
  final AuthController _authController = Get.find<AuthController>();
  final NotificationsController _notifController = Get.find<NotificationsController>();

  int _selectedCategoryIndex = 0;
  final List<String> _categories = const [
    'Tout',
    'Vêtements',
    'Électronique',
    'Maison',
    'Véhicules',
    'Livres',
    'Sport',
    'Bricolage',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listingsController.fetchCities();
      _listingsController.fetchListings();
      _notifController.fetchUnreadCount();
    });
  }

  void _showCityPicker() {
    if (_listingsController.cities.isEmpty) {
      _listingsController.fetchCities();
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (ctx) {
        return SafeArea(
          child: Obx(() {
            final cities = _listingsController.cities;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Choisir une ville', style: AppTypography.serif(size: 21)),
                  const SizedBox(height: 4),
                  Text(
                    'Affichez les objets disponibles à l\'échange autour de vous.',
                    style: AppTypography.sans(size: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  if (cities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _listingsController.fetchCities(),
                              child: Text(
                                'Réessayer',
                                style: AppTypography.sans(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final city = cities[idx];
                          final isSelected = city.name == _listingsController.selectedCity.value;
                          return InkWell(
                            onTap: () {
                              _authController.selectedCity.value = city.name;
                              _listingsController.changeCity(city.name);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accentLight : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : AppColors.line,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    city.name,
                                    style: AppTypography.sans(
                                      size: 14.5,
                                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.accent : AppColors.ink,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                        size: 19, color: AppColors.accent),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _listingsController.fetchListings(),
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top header + pill search + hero banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo « trocly. » + boutons circulaires blancs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppTypography.wordmark(size: 27),
                          Obx(() {
                            final loggedIn = _authController.authToken.value.isNotEmpty;
                            if (!loggedIn) {
                              return Row(
                                children: [
                                  TroclyCircleIconBtn(
                                    icon: Icons.location_on_outlined,
                                    onTap: _showCityPicker,
                                    tooltip: 'Changer de ville',
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Get.toNamed('/login'),
                                    child: Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: AppColors.coralShadow,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Connexion',
                                        style: AppTypography.sans(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            final unreadNotifs = _notifController.unreadCount.value;
                            return Row(
                              children: [
                                TroclyCircleIconBtn(
                                  icon: Icons.notifications_none_rounded,
                                  badgeCount: unreadNotifs,
                                  tooltip: 'Notifications',
                                  onTap: () async {
                                    await Get.toNamed('/notifications');
                                    _notifController.fetchUnreadCount();
                                  },
                                ),
                                const SizedBox(width: 8),
                                TroclyCircleIconBtn(
                                  icon: Icons.inventory_2_outlined,
                                  tooltip: 'Mes annonces',
                                  onTap: () => Get.toNamed('/my-listings'),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pill search bar blanche avec icône filtre intégrée
                      GestureDetector(
                        onTap: () => Get.toNamed('/search'),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  size: 20, color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Vêtements, vélo, console…',
                                  style: AppTypography.sans(
                                    size: 13.5,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.paper,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.tune_rounded,
                                    size: 17, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sélecteur de ville moderne
                      GestureDetector(
                        onTap: _showCityPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 15, color: AppColors.accent),
                              const SizedBox(width: 5),
                              Obx(() => Text(
                                    _listingsController.selectedCity.value,
                                    style: AppTypography.sans(
                                      size: 12.5,
                                      weight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  )),
                              Text(
                                ' · changer',
                                style: AppTypography.sans(
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bannière héro moderne bleu-ciel doux + photo d'échange
                      Container(
                        height: 138,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [AppColors.bannerStart, AppColors.bannerEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Échangez malin,\nzéro frais !',
                                            style: AppTypography.serif(
                                              size: 18,
                                              color: Colors.white,
                                              height: 1.18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Troc sécurisé par double QR',
                                            style: AppTypography.sans(
                                              size: 11.5,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (_authController.authToken.value.isEmpty) {
                                            Get.toNamed('/login');
                                          } else {
                                            Get.toNamed('/publish');
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Publier un objet',
                                            style: AppTypography.sans(
                                              size: 11.5,
                                              weight: FontWeight.w700,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/images/welcome_exchange.jpg',
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pilules de catégories horizontales (Vêtements en 1ère catégorie)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 62,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 9),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategoryIndex = index);
                          _listingsController.filterByCategory(
                            index == 0 ? 'Tous' : _categories[index],
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent : AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? AppColors.coralShadow
                                : AppColors.pillShadow,
                          ),
                          child: Text(
                            _categories[index],
                            style: AppTypography.sans(
                              size: 13,
                              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Titre de section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nouveautés près de vous',
                          style: AppTypography.serif(size: 19)),
                      Obx(() {
                        final n = _listingsController.listings.length;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '$n annonce${n > 1 ? 's' : ''}',
                            style: AppTypography.sans(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Grille d'annonces / états vides
              Obx(() {
                if (_listingsController.isLoading.value) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2.5),
                    ),
                  );
                }

                if (_listingsController.listings.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: StatePage(
                      type: StatePageType.emptyCity,
                      actionLabel: 'Changer de ville',
                      onAction: _showCityPicker,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _listingsController.listings[index];
                        return ListingCard(
                          id: item.id,
                          title: item.title,
                          condition: item.condition,
                          cityName: item.city,
                          photoUrl: item.photos.isNotEmpty ? item.photos.first : null,
                          wishLabel: item.wishSummary,
                          onTap: () => Get.toNamed('/listing/${item.id}', arguments: item),
                        );
                      },
                      childCount: _listingsController.listings.length,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
