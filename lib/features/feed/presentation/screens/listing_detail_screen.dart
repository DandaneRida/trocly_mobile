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
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  ListingModel? _listing;

  @override
  void initState() {
    super.initState();
    _listing = Get.arguments as ListingModel?;
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
    final isLoggedIn = _authController.authToken.value.isNotEmpty;
    if (!isLoggedIn) {
      await AuthGuardBottomSheet.checkAuthOrShow(context, isLoggedIn: false);
      return;
    }
    Get.toNamed('/propose-offer/${_listing?.id}', arguments: _listing);
  }

  @override
  Widget build(BuildContext context) {
    if (_listing == null) {
      return Scaffold(
        bottomNavigationBar: const TroclyBottomNav(currentIndex: 0),
        appBar: AppBar(title: const TroclyAppBarTitle(pageTitle: 'Annonce')),
        body: const Center(child: Text('Annonce introuvable')),
      );
    }

    final item = _listing!;
    final photos = item.photos;
    final specs = Map<String, dynamic>.from(item.attributes)
      ..remove('wishes')
      ..removeWhere((_, v) => v == null || v.toString().trim().isEmpty);

    final sellerName = (item.userName != null && item.userName!.trim().isNotEmpty)
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edge-to-edge photo carousel
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        width: double.infinity,
                        color: AppColors.imagePlaceholder,
                        child: photos.isEmpty
                            ? const Center(
                                child: Icon(Icons.photo_outlined, size: 48, color: AppColors.textHint),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: photos.length,
                                onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
                                itemBuilder: (_, i) => Image.network(
                                  photos[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined, size: 44, color: AppColors.textHint),
                                  ),
                                ),
                              ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _circleBtn(Icons.arrow_back_ios_new_rounded, () => Get.back()),
                              GestureDetector(
                                onTap: () => Get.offAllNamed('/feed'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: AppTypography.wordmark(size: 18),
                                ),
                              ),
                              _circleBtn(Icons.ios_share_rounded, () {
                                Get.snackbar('Partage', 'Lien de l\'annonce copié');
                              }),
                            ],
                          ),
                        ),
                      ),
                      if (photos.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_currentPhotoIndex + 1} / ${photos.length}',
                              style: AppTypography.sans(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTypography.serif(size: 25)),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatCondition(item.condition)} · ${item.category} · ${item.city}',
                          style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 18),

                        // Exchange wish callout
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECHERCHE EN ÉCHANGE',
                                style: AppTypography.eyebrow(color: AppColors.accent),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.wishSummary,
                                style: AppTypography.sans(size: 13.5, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Description
                        Text(
                          item.description.isNotEmpty
                              ? item.description
                              : 'Aucune description supplémentaire.',
                          style: AppTypography.sans(
                            size: 14,
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Hairline specs table
                        const Divider(),
                        _specRow('Ville', item.city),
                        const Divider(),
                        _specRow('État', _formatCondition(item.condition)),
                        const Divider(),
                        ...specs.entries.expand((e) => [
                              _specRow(
                                e.key[0].toUpperCase() + e.key.substring(1),
                                e.value.toString(),
                              ),
                              const Divider(),
                            ]),
                        const SizedBox(height: 18),

                        // Seller row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 21,
                              backgroundColor: AppColors.bubble,
                              child: Text(
                                initials.isEmpty ? 'T' : initials,
                                style: AppTypography.sans(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: AppColors.ink,
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
                                      Text(
                                        sellerName,
                                        style: AppTypography.sans(
                                          size: 14,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_user_outlined,
                                          size: 15, color: AppColors.success),
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
                        const SizedBox(height: 20),

                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Get.toNamed('/report', arguments: {
                                'listingId': item.id,
                                'userId': item.userId,
                              });
                            },
                            icon: const Icon(Icons.flag_outlined, size: 15, color: AppColors.textHint),
                            label: Text(
                              'Signaler cette annonce',
                              style: AppTypography.sans(size: 12.5, color: AppColors.textHint),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky bottom bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(
              top: false,
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
                      width: 112,
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
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.sans(size: 13.5, color: AppColors.textSecondary)),
          Text(value, style: AppTypography.sans(size: 13.5, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}
