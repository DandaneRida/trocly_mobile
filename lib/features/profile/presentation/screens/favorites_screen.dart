import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/favorites_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesController _favs = Get.find<FavoritesController>();
  final ListingsController _listings = Get.find<ListingsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _favs.loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 4),
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: TroclyCircleIconBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Get.back(),
            ),
          ),
        ),
        title: TroclyAppBarTitle(pageTitle: 'favorites'.tr),
      ),
      body: Obx(() {
        if (_favs.isLoading.value && _favs.favoriteListings.isEmpty) {
          return const ListingGridSkeleton(count: 4);
        }

        // Merge server favoriteListings with any locally favorited items in public feed
        final items = <ListingModel>[..._favs.favoriteListings];
        for (final id in _favs.favoriteIds) {
          if (!items.any((e) => e.id == id)) {
            final found =
                _listings.listings.firstWhereOrNull((l) => l.id == id);
            if (found != null) items.add(found);
          }
        }

        if (items.isEmpty) {
          return StatePage(
            type: StatePageType.emptyResults,
            customTitle: 'Aucun favori enregistré',
            customMessage:
                'Appuyez sur le cœur d\'une annonce pour la retrouver rapidement ici.',
            actionLabel: 'Explorer les annonces',
            onAction: () => Get.offAllNamed('/feed'),
          );
        }

        return RefreshIndicator(
          onRefresh: _favs.loadFavorites,
          color: AppColors.accent,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 14,
              mainAxisSpacing: 20,
            ),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              return ListingCard(
                id: item.id,
                title: item.title,
                condition: item.condition,
                cityName: item.city,
                photoUrl: item.photos.isNotEmpty ? item.photos.first : null,
                wishLabel: item.wishSummary,
                listingModel: item,
                onTap: () =>
                    Get.toNamed('/listing/${item.id}', arguments: item),
              );
            },
          ),
        );
      }),
    );
  }
}
