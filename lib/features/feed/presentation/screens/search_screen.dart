import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ListingsController _listingsController = Get.find<ListingsController>();
  final _searchController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedCity;

  final List<String> _categories = const [
    'Tous',
    'Vêtements',
    'Électronique',
    'Maison',
    'Véhicules',
    'Sport',
    'Livres',
    'Bricolage',
  ];

  final Map<String, String> _conditionLabels = const {
    'neuf': 'Neuf',
    'comme_neuf': 'Comme neuf',
    'tres_bon': 'Très bon état',
    'bon': 'Bon état',
    'use': 'Usé',
  };

  @override
  void initState() {
    super.initState();
    _selectedCity = _listingsController.selectedCity.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listingsController.cities.isEmpty) {
        _listingsController.fetchCities();
      }
    });
  }

  void _applyFilters() {
    final allCities = _selectedCity == 'Toutes';
    int? cityId;
    if (!allCities && _selectedCity != null) {
      final found = _listingsController.cities.firstWhereOrNull((c) => c.name == _selectedCity);
      if (found != null) cityId = found.id;
    }

    _listingsController.fetchListings(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      category: (_selectedCategory == null || _selectedCategory == 'Tous') ? null : _selectedCategory,
      condition: _selectedCondition,
      cityId: cityId,
      allCities: allCities,
    );
  }

  void _reset() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedCondition = null;
      _selectedCity = _listingsController.selectedCity.value;
    });
    _listingsController.fetchListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 1),
      appBar: AppBar(
        title: const TroclyAppBarTitle(pageTitle: 'Explorer'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              'Réinitialiser',
              style: AppTypography.sans(size: 12.5, color: AppColors.accent, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un vélo, un livre, une console…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 19, color: AppColors.ink),
                      onPressed: _applyFilters,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Ville
                      Obx(() {
                        final cities = _listingsController.cities;
                        final cityNames = ['Toutes', ...cities.map((c) => c.name)];
                        final currentVal =
                            cityNames.contains(_selectedCity) ? _selectedCity : null;
                        return _filterDropdown<String>(
                          value: currentVal,
                          hint: 'Ville',
                          items: cityNames
                              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedCity = v);
                            if (v != null && v != 'Toutes') {
                              _listingsController.changeCity(v);
                            }
                            _applyFilters();
                          },
                        );
                      }),
                      const SizedBox(width: 8),
                      // Catégorie
                      _filterDropdown<String>(
                        value: _selectedCategory,
                        hint: 'Catégorie',
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedCategory = v);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      // État
                      _filterDropdown<String>(
                        value: _selectedCondition,
                        hint: 'État',
                        items: _conditionLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedCondition = v);
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Obx(() {
              if (_listingsController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
                );
              }
              if (_listingsController.listings.isEmpty) {
                return StatePage(
                  type: StatePageType.emptyResults,
                  actionLabel: 'Réinitialiser les filtres',
                  onAction: _reset,
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.67,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 20,
                ),
                itemCount: _listingsController.listings.length,
                itemBuilder: (_, index) {
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final active = value != null && value != 'Tous' && value != 'Toutes';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? AppColors.ink : AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: AppTypography.sans(size: 12.5, color: AppColors.textSecondary),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
          dropdownColor: AppColors.surface,
          style: AppTypography.sans(
            size: 12.5,
            weight: FontWeight.w500,
            color: AppColors.ink,
          ),
          selectedItemBuilder: (ctx) => items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: DefaultTextStyle(
                      style: AppTypography.sans(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: active ? Colors.white : AppColors.ink,
                      ),
                      child: item.child,
                    ),
                  ))
              .toList(),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
