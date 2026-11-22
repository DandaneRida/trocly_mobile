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
    'Électronique',
    'Maison',
    'Véhicules',
    'Vêtements',
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
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Choisir une ville', style: AppTypography.serif(size: 22)),
                  const SizedBox(height: 4),
                  Text(
                    'Affichez les objets disponibles à l\'échange autour de vous.',
                    style: AppTypography.sans(size: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  if (cities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _listingsController.fetchCities(),
                              child: Text(
                                'Réessayer',
                                style: AppTypography.sans(
                                  size: 13,
                                  weight: FontWeight.w600,
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
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, idx) {
                          final city = cities[idx];
                          final isSelected = city.name == _listingsController.selectedCity.value;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 2),
                            title: Text(
                              city.name,
                              style: AppTypography.sans(
                                size: 14.5,
                                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: AppColors.ink,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded, size: 18, color: AppColors.accent)
                                : null,
                            onTap: () {
                              _authController.selectedCity.value = city.name;
                              _listingsController.changeCity(city.name);
                              Navigator.pop(ctx);
                            },
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
      bottomNavigationBar: Obx(() => _authController.authToken.value.isNotEmpty
          ? const TroclyBottomNav(currentIndex: 0)
          : const SizedBox.shrink()),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _listingsController.fetchListings(),
          color: AppColors.ink,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top brand header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppTypography.wordmark(size: 26),
                          Obx(() {
                            final loggedIn = _authController.authToken.value.isNotEmpty;
                            if (!loggedIn) {
                              return InkWell(
                                onTap: () => Get.toNamed('/login'),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.ink),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Connexion',
                                    style: AppTypography.sans(
                                      size: 12.5,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final unreadNotifs = _notifController.unreadCount.value;
                            return IconButton(
                              onPressed: () async {
                                await Get.toNamed('/notifications');
                                _notifController.fetchUnreadCount();
                              },
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.notifications_none_rounded, size: 23, color: AppColors.ink),
                                  if (unreadNotifs > 0)
                                    Positioned(
                                      top: 1,
                                      right: 1,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.paper, width: 1.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Search input + Filter icon
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Get.toNamed('/search'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 13),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, size: 19, color: AppColors.textHint),
                                    const SizedBox(width: 9),
                                    Text(
                                      'Vélo, livres, console…',
                                      style: AppTypography.sans(
                                        size: 13.5,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => Get.toNamed('/search'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: const Icon(Icons.tune_rounded, size: 19, color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      // City picker line
                      InkWell(
                        onTap: _showCityPicker,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 5),
                              Obx(() => Text(
                                    _listingsController.selectedCity.value,
                                    style: AppTypography.sans(
                                      size: 13,
                                      weight: FontWeight.w500,
                                      color: AppColors.ink,
                                    ),
                                  )),
                              Text(
                                ' · changer de ville',
                                style: AppTypography.sans(
                                  size: 12.5,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textHint),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Underlined category tabs
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 22),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategoryIndex = index);
                          _listingsController.filterByCategory(
                            index == 0 ? 'Tous' : _categories[index],
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? AppColors.ink : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            _categories[index],
                            style: AppTypography.sans(
                              size: 13.5,
                              weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? AppColors.ink : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Section heading
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nouveautés près de vous', style: AppTypography.serif(size: 21)),
                      Obx(() {
                        final n = _listingsController.listings.length;
                        return Text(
                          '$n annonce${n > 1 ? 's' : ''}',
                          style: AppTypography.sans(size: 12, color: AppColors.textHint),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Listings grid / states
              Obx(() {
                if (_listingsController.isLoading.value) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
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
                      childAspectRatio: 0.67,
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
