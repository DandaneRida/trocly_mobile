import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_guard_bottom_sheet.dart';
import '../../../../core/widgets/primary_button.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({Key? key}) : super(key: key);

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  ListingModel? _listing;

  @override
  void initState() {
    super.initState();
    _listing = Get.arguments as ListingModel?;
  }

  void _onProposeTroc() async {
    final isLoggedIn = _authController.authToken.value.isNotEmpty;
    if (!isLoggedIn) {
      await AuthGuardBottomSheet.checkAuthOrShow(
        context,
        isLoggedIn: false,
      );
      return;
    }
    // Navigate to propose offer screen
    Get.toNamed('/propose-offer/${_listing?.id}', arguments: _listing);
  }

  @override
  Widget build(BuildContext context) {
    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail de l\'annonce')),
        body: const Center(child: Text('Annonce introuvable')),
      );
    }

    final item = _listing!;
    final photos = item.photos.isNotEmpty ? item.photos : <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail de l’annonce'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Get.snackbar('Partage', 'Lien de l\'annonce copié');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Carousel
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photos.isEmpty
                        ? const Center(
                            child: Icon(Icons.image_outlined, size: 64, color: AppColors.textSecondary),
                          )
                        : Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: photos.length,
                                onPageChanged: (idx) {
                                  setState(() => _currentPhotoIndex = idx);
                                },
                                itemBuilder: (ctx, i) {
                                  return Image.network(
                                    photos[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 48, color: AppColors.textHint),
                                    ),
                                  );
                                },
                              ),
                              if (photos.length > 1)
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_currentPhotoIndex + 1}/${photos.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Badges: Ville, Date, État
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _badge(item.city, Icons.location_on_outlined),
                      _badge(item.condition, Icons.verified_outlined),
                      _badge('Publié récemment', Icons.access_time_rounded),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description.isNotEmpty ? item.description : 'Aucune description fournie.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // "Je recherche en échange"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Je recherche en échange',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ouvert aux propositions équivalentes (smartphone, accessoires, vélo...).',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Seller Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Partenaire vérifié ✓',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Score 95 · 4,9 ★ · 12 avis',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Link Signaler
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.textHint),
                      label: const Text(
                        'Signaler cette annonce',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                      onPressed: () {
                        Get.toNamed('/report', arguments: {'listingId': item.id});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom CTA dock
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
            ),
            child: PrimaryButton(
              label: 'Proposer un troc',
              icon: Icons.swap_horiz_rounded,
              onPressed: _onProposeTroc,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
