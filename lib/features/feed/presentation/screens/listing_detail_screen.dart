import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_guard_bottom_sheet.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({Key? key}) : super(key: key);

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final AuthController _authController = Get.find<AuthController>();
  ListingModel? _listing;
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (Get.arguments is ListingModel) {
      _listing = Get.arguments as ListingModel;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatCondition(String raw) {
    switch (raw) {
      case 'neuf':
        return 'Neuf';
      case 'comme_neuf':
        return 'Comme neuf';
      case 'tres_bon':
        return 'Très bon état';
      case 'bon':
        return 'Bon état';
      case 'use':
        return 'Usé';
      default:
        return raw;
    }
  }

  Future<void> _onProposeTroc() async {
    final ok = await AuthGuardBottomSheet.checkAuthOrShow(
      context,
      isLoggedIn: _authController.authToken.value.isNotEmpty,
    );
    if (!ok) return;
    if (_listing != null) {
      Get.toNamed('/propose-offer/${_listing!.id}', arguments: _listing);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_listing == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        bottomNavigationBar: const TroclyBottomNav(currentIndex: 0),
        appBar: AppBar(title: const TroclyAppBarTitle(pageTitle: 'Détails')),
        body: const Center(child: Text('Annonce introuvable')),
      );
    }

    final item = _listing!;
    final photos = item.photos;
    final specs = Map<String, dynamic>.from(item.attributes)
      ..remove('wishes')
      ..removeWhere((_, v) => v == null || v.toString().trim().isEmpty);

    final sellerName =
        (item.userName != null && item.userName!.trim().isNotEmpty)
            ? item.userName!.trim()
            : 'Membre Trocly';
    final initials = sellerName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 0),
      appBar: AppBar(
        backgroundColor: AppColors.paper,
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
        centerTitle: true,
        title: const TroclyAppBarTitle(pageTitle: 'Détails'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TroclyCircleIconBtn(
                icon: Icons.ios_share_rounded,
                onTap: () {
                  Get.snackbar('Partage', 'Lien de l\'annonce copié');
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo encadrée arrondie 24px (style carte produit moderne)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 290,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.imagePlaceholder,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: photos.isEmpty
                              ? const Center(
                                  child: Icon(Icons.photo_outlined,
                                      size: 48, color: AppColors.textSecondary),
                                )
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: photos.length,
                                  onPageChanged: (idx) =>
                                      setState(() => _currentPhotoIndex = idx),
                                  itemBuilder: (_, i) => Image.network(
                                    photos[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          size: 44,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Pilule flottante en bas à droite de la photo
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppColors.pillShadow,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Troc',
                                    style: AppTypography.sans(
                                      size: 12,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppColors.pillShadow,
                              ),
                              child: Text(
                                _formatCondition(item.condition),
                                style: AppTypography.sans(
                                  size: 11.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Indicateurs pagination photo
                  if (photos.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentPhotoIndex ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _currentPhotoIndex
                                ? AppColors.accent
                                : AppColors.borderStrong,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Titre & métadonnées en pilules
                  Text(item.title, style: AppTypography.serif(size: 23)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoPill(Icons.category_outlined, item.category),
                      _infoPill(Icons.location_on_outlined, item.city),
                      _infoPill(Icons.verified_outlined,
                          _formatCondition(item.condition)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Carte souhait d'échange (pêche doux + icône corail)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECHERCHE EN ÉCHANGE',
                                style: AppTypography.eyebrow(
                                    color: AppColors.accent),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.wishSummary,
                                style: AppTypography.sans(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Carte description + spécifications
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description',
                            style: AppTypography.sans(
                                size: 15, weight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          item.description.isNotEmpty
                              ? item.description
                              : 'Aucune description supplémentaire.',
                          style: AppTypography.sans(
                            size: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        if (specs.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Divider(),
                          ...specs.entries.map((e) => _specRow(
                                e.key[0].toUpperCase() + e.key.substring(1),
                                e.value.toString(),
                              )),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Carte vendeur blanche moderne
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: AppColors.accentLight,
                          child: Text(
                            initials.isEmpty ? 'T' : initials,
                            style: AppTypography.sans(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      sellerName,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.sans(
                                        size: 14.5,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded,
                                      size: 16, color: AppColors.success),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Téléphone vérifié · ${item.city}',
                                style: AppTypography.sans(
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.toNamed('/report', arguments: {
                          'listingId': item.id,
                          'userId': item.userId,
                        });
                      },
                      icon: const Icon(Icons.flag_outlined,
                          size: 15, color: AppColors.textHint),
                      label: Text(
                        'Signaler cette annonce',
                        style: AppTypography.sans(
                            size: 12.5, color: AppColors.textHint),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barre CTA collée au-dessus de la bottom nav
          Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Obx(() {
              final isOwner = _authController.userId.value.isNotEmpty &&
                  item.userId.isNotEmpty &&
                  item.userId == _authController.userId.value;
              if (isOwner) {
                return PrimaryButton(
                  label: 'Gérer mon annonce',
                  icon: Icons.edit_outlined,
                  isOutlined: true,
                  onPressed: () => Get.toNamed('/my-listings'),
                );
              }
              return Row(
                children: [
                  SizedBox(
                    width: 118,
                    child: PrimaryButton(
                      label: 'Message',
                      isOutlined: true,
                      onPressed: _onProposeTroc,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Proposer un troc',
                      icon: Icons.swap_horiz_rounded,
                      onPressed: _onProposeTroc,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.pillShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.sans(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.sans(
                  size: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.sans(size: 13, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
