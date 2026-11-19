import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../../core/widgets/primary_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ListingsController _listingsController = Get.find<ListingsController>();
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedCity;

  final List<String> _categories = const [
    'Tous',
    'Électronique',
    'Maison',
    'Véhicules',
    'Vêtements',
    'Sport',
    'Livres',
    'Bricolage',
  ];

  final List<String> _conditions = const [
    'neuf',
    'comme_neuf',
    'tres_bon',
    'bon',
    'use',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = _listingsController.selectedCity.value;
  }

  void _applyFilters() {
    int? cityId;
    if (_selectedCity != null) {
      final found = _listingsController.cities.firstWhereOrNull((c) => c.name == _selectedCity);
      if (found != null) cityId = found.id;
    }

    final double? minVal = double.tryParse(_minPriceController.text.trim());
    final double? maxVal = double.tryParse(_maxPriceController.text.trim());

    _listingsController.fetchListings(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      category: (_selectedCategory == null || _selectedCategory == 'Tous') ? null : _selectedCategory,
      condition: _selectedCondition,
      cityId: cityId,
      minValue: minVal,
      maxValue: maxVal,
    );
  }

  void _reset() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedCategory = null;
      _selectedCondition = null;
      _selectedCity = _listingsController.selectedCity.value;
    });
    _listingsController.fetchListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recherche & Filtres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('Effacer', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Box
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Que recherchez-vous ? (ex: iPhone, Vélo...)',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: _applyFilters,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 12),
                  // Filtres déroulants : Catégorie & Condition & Ville
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Dropdown Ville
                        Obx(() {
                          final cities = _listingsController.cities;
                          return DropdownButton<String>(
                            value: _selectedCity,
                            hint: const Text('Ville'),
                            underline: const SizedBox.shrink(),
                            items: cities.map((c) {
                              return DropdownMenuItem(value: c.name, child: Text(c.name));
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedCity = val);
                              _applyFilters();
                            },
                          );
                        }),
                        const SizedBox(width: 12),
                        // Dropdown Catégorie
                        DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Catégorie'),
                          underline: const SizedBox.shrink(),
                          items: _categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCategory = val);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 12),
                        // Dropdown Condition
                        DropdownButton<String>(
                          value: _selectedCondition,
                          hint: const Text('État'),
                          underline: const SizedBox.shrink(),
                          items: _conditions.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCondition = val);
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Résultats
            Expanded(
              child: Obx(() {
                if (_listingsController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (_listingsController.listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          'Aucun résultat pour cette recherche',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Essayez d\'ajuster vos critères ou mots-clés.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
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
                      relativeTime: 'Résultat',
                      photoUrl: item.photos.isNotEmpty ? item.photos.first : null,
                      onTap: () {
                        Get.toNamed('/listing/${item.id}', arguments: item);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
