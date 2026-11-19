import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_guard_bottom_sheet.dart';
import '../../../../core/widgets/listing_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ListingsController _listingsController = Get.find<ListingsController>();
  final AuthController _authController = Get.find<AuthController>();

  int _selectedCategoryIndex = 0;
  final List<String> _categories = const [
    'Tous',
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
    });
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Obx(() {
          final cities = _listingsController.cities;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Changer de ville',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (cities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ...cities.map((city) {
                    final isSelected = city.name == _listingsController.selectedCity.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        _authController.selectedCity.value = city.name;
                        _listingsController.changeCity(city.name);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: InkWell(
          onTap: _showCityPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => Text('Trocly · ${_listingsController.selectedCity.value} ▾')),
            ],
          ),
        ),
        actions: [
          Obx(() {
            final loggedIn = _authController.authToken.value.isNotEmpty;
            if (!loggedIn) {
              return TextButton(
                onPressed: () => Get.toNamed('/login'),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => Get.toNamed('/notifications'),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final loggedIn = _authController.authToken.value.isNotEmpty;
        if (!loggedIn) {
          return const SizedBox.shrink();
        }
        return NavigationBar(
          selectedIndex: 0,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          onDestinationSelected: (index) {
            if (index == 1) Get.toNamed('/search');
            if (index == 2) Get.toNamed('/publish');
            if (index == 3) Get.toNamed('/messages');
            if (index == 4) Get.toNamed('/profile');
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppColors.primary),
              label: 'Recherche',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle, color: AppColors.primary),
              label: 'Publier',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
        );
      }),
      body: RefreshIndicator(
        onRefresh: () => _listingsController.fetchListings(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bannière
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF2C3E50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Donnez une seconde vie à vos objets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Échangez facilement et en toute sécurité par QR code.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_calls_rounded, size: 48, color: AppColors.accent),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Category ChoiceChips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return ChoiceChip(
                      label: Text(_categories[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.primary, width: 1),
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategoryIndex = index);
                        if (index == 0) {
                          _listingsController.filterByCategory('Tous');
                        } else {
                          _listingsController.filterByCategory(_categories[index]);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Filter chips (Catégorie, État, Ville)
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.filter_list, size: 16, color: AppColors.primary),
                    label: const Text('Filtres'),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () => Get.toNamed('/search'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.location_city, size: 16, color: AppColors.primary),
                    label: Obx(() => Text(_listingsController.selectedCity.value)),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: _showCityPicker,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Header title with count
              Obx(() {
                final count = _listingsController.listings.length;
                return Text(
                  'Annonces actives · $count objet${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                );
              }),
              const SizedBox(height: 12),
              // Listings Grid
              Obx(() {
                if (_listingsController.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (_listingsController.listings.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune annonce pour le moment',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Élargissez votre recherche aux autres villes marocaines ou publiez le premier objet !',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showCityPicker,
                          icon: const Icon(Icons.location_on),
                          label: const Text('Changer de ville'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _listingsController.listings.length,
                  itemBuilder: (context, index) {
                    final item = _listingsController.listings[index];
                    return ListingCard(
                      id: item.id,
                      title: item.title,
                      condition: item.condition,
                      cityName: item.city,
                      relativeTime: 'Actif',
                      photoUrl: item.photos.isNotEmpty ? item.photos.first : null,
                      onTap: () {
                        Get.toNamed('/listing/${item.id}', arguments: item);
                      },
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
