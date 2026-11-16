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

  String? _selectedCategory;
  String? _selectedCondition;

  final List<String> _categories = const [
    'Électronique',
    'Maison',
    'Véhicules',
    'Vêtements',
    'Sport',
    'Livres',
  ];

  final List<String> _conditions = const [
    'neuf',
    'comme_neuf',
    'tres_bon',
    'bon',
    'use',
  ];

  void _applyFilters() {
    _listingsController.searchListings(_searchController.text.trim());
    if (_selectedCategory != null) {
      _listingsController.filterByCategory(_selectedCategory!);
    }
  }

  void _reset() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedCondition = null;
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
            // Search Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Que recherchez-vous ? (ex. vélo, iPhone...)',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catégories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.primary, fontSize: 11),
                            onSelected: (val) {
                              setState(() => _selectedCategory = val ? cat : null);
                              _applyFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('État', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _conditions.map((cond) {
                        final isSel = cond == _selectedCondition;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(cond.replaceAll('_', ' ')),
                            selected: isSel,
                            selectedColor: AppColors.accent,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontSize: 11),
                            onSelected: (val) {
                              setState(() => _selectedCondition = val ? cond : null);
                              _applyFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Results list
            Expanded(
              child: Obx(() {
                final list = _listingsController.listings;
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Aucun résultat correspondant aux critères'),
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
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final item = list[i];
                    return ListingCard(
                      id: item.id,
                      title: item.title,
                      condition: item.condition,
                      cityName: item.city,
                      photoUrl: item.photos.isNotEmpty ? item.photos.first : null,
                      onTap: () => Get.toNamed('/listing/${item.id}', arguments: item),
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
