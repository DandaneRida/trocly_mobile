import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/offers_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

/// Écran 13 — Proposer un troc (C1, EF-O01/O02)
/// Respecte strictement le wireframe :
/// - Résumé cible épinglé en haut
/// - Sélection obligatoire d'au moins 1 de MES propres annonces actives
/// - Interrupteur « Soulte possible » (aucun prix fixe affiché ni stocké)
class ProposeOfferScreen extends StatefulWidget {
  const ProposeOfferScreen({Key? key}) : super(key: key);

  @override
  State<ProposeOfferScreen> createState() => _ProposeOfferScreenState();
}

class _ProposeOfferScreenState extends State<ProposeOfferScreen> {
  final OffersController _offersController = Get.find<OffersController>();
  final ListingsController _listingsController = Get.find<ListingsController>();
  final AuthController _authController = Get.find<AuthController>();

  ListingModel? _targetListing;
  final Set<String> _selectedIds = {};
  bool _soultePossible = false;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetListing = Get.arguments as ListingModel?;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listingsController.fetchMyListings(status: 'active');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<ListingModel> get _eligibleMyListings {
    final targetId = _targetListing?.id;
    return _listingsController.myListings
        .where((l) => l.status == 'active' && l.id != targetId)
        .toList();
  }

  bool get _isSelfListing {
    final uid = _authController.userId.value;
    return _targetListing != null &&
        uid.isNotEmpty &&
        _targetListing!.userId == uid;
  }

  String get _summaryLine {
    if (_selectedIds.isEmpty) {
      return 'Sélectionnez au moins 1 objet obligatoire ci-dessus';
    }
    final picked = _eligibleMyListings
        .where((l) => _selectedIds.contains(l.id))
        .map((l) => l.title)
        .toList();
    final itemsStr = picked.length == 1
        ? picked.first
        : '${picked.length} objets sélectionnés';
    final soulteStr = _soultePossible ? ' (soulte possible)' : '';
    return '$itemsStr$soulteStr contre ${_targetListing?.title ?? 'cet objet'}';
  }

  Future<void> _submit() async {
    if (_targetListing == null) return;
    if (_isSelfListing) {
      Get.snackbar('Action impossible',
          'Vous ne pouvez pas proposer un échange sur votre propre annonce.');
      return;
    }
    if (_selectedIds.isEmpty) {
      Get.snackbar('Objet obligatoire',
          'Sélectionnez au moins un de vos objets actifs pour proposer un échange.');
      return;
    }

    final offer = await _offersController.createOffer(
      targetListingId: _targetListing!.id,
      offeringListingIds: _selectedIds.toList(),
      soultePossible: _soultePossible,
      message: _messageController.text.trim(),
    );

    if (offer != null && mounted) {
      Get.offNamed('/chat/${offer.id}');
      Get.snackbar(
        'Proposition envoyée',
        'Votre offre d\'échange a été transmise au propriétaire.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Get.back(),
        ),
        title: const TroclyAppBarTitle(pageTitle: 'Proposition'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_targetListing != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 54,
                            height: 54,
                            color: AppColors.imagePlaceholder,
                            child: _targetListing!.photos.isNotEmpty
                                ? Image.network(_targetListing!.photos.first,
                                    fit: BoxFit.cover)
                                : const Icon(Icons.photo_outlined,
                                    color: AppColors.textHint),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VOUS SOUHAITEZ',
                                  style: AppTypography.eyebrow()),
                              const SizedBox(height: 2),
                              Text(
                                _targetListing!.title,
                                style: AppTypography.sans(
                                    size: 14.5, weight: FontWeight.w600),
                              ),
                              Text(
                                '${_targetListing!.condition} · ${_targetListing!.city}',
                                style: AppTypography.sans(
                                    size: 11.5, color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  if (_isSelfListing)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        'Cette annonce vous appartient : vous ne pouvez pas vous proposer un échange à vous-même.',
                        style: AppTypography.sans(
                            size: 13,
                            color: AppColors.error,
                            weight: FontWeight.w500),
                      ),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('Sélectionnez vos objets *',
                            style: AppTypography.serif(size: 20)),
                        Text(
                          '${_selectedIds.length} sélectionné(s)',
                          style: AppTypography.sans(
                              size: 11.5, color: AppColors.textHint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choisissez au moins un de vos objets actifs (échange simple ou multi-objets).',
                      style: AppTypography.sans(
                          size: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    Obx(() {
                      if (_listingsController.isMyListingsLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.ink, strokeWidth: 2),
                          ),
                        );
                      }
                      final myItems = _eligibleMyListings;
                      if (myItems.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Vous devez avoir au moins une annonce active pour proposer un échange.',
                                textAlign: TextAlign.center,
                                style: AppTypography.sans(
                                    size: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () async {
                                  await Get.toNamed('/publish');
                                  _listingsController.fetchMyListings(
                                      status: 'active');
                                },
                                child: const Text('Publier un objet d\'abord'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: myItems.map((item) {
                          final checked = _selectedIds.contains(item.id);
                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (checked) {
                                      _selectedIds.remove(item.id);
                                    } else {
                                      _selectedIds.add(item.id);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          color: AppColors.imagePlaceholder,
                                          child: item.photos.isNotEmpty
                                              ? Image.network(item.photos.first,
                                                  fit: BoxFit.cover)
                                              : const Icon(Icons.photo_outlined,
                                                  size: 20,
                                                  color: AppColors.textHint),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title,
                                                style: AppTypography.sans(
                                                    size: 13.5,
                                                    weight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.condition} · ${item.city}',
                                              style: AppTypography.sans(
                                                  size: 11.5,
                                                  color: AppColors.textHint),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: checked
                                              ? AppColors.ink
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: checked
                                                ? AppColors.ink
                                                : AppColors.borderStrong,
                                          ),
                                        ),
                                        child: checked
                                            ? const Icon(Icons.check_rounded,
                                                size: 15, color: Colors.white)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(),
                            ],
                          );
                        }).toList(),
                      );
                    }),

                    const SizedBox(height: 18),

                    // Interrupteur « Soulte possible » (Wireframe Écran 13 — aucun prix affiché ni stocké)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Soulte possible',
                                    style: AppTypography.sans(
                                        size: 13.5, weight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  'Le montant sera discuté dans le chat (aucun prix affiché ni stocké).',
                                  style: AppTypography.sans(
                                      size: 11.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _soultePossible,
                            activeThumbColor: AppColors.surface,
                            activeTrackColor: AppColors.ink,
                            onChanged: (v) =>
                                setState(() => _soultePossible = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'Votre message (facultatif)',
                      style: AppTypography.sans(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Bonjour, votre annonce m\'intéresse. Seriez-vous d\'accord pour cet échange ?',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (!_isSelfListing)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _summaryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                          size: 12,
                          color: _selectedIds.isEmpty
                              ? AppColors.accent
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => PrimaryButton(
                          label: 'Envoyer la proposition',
                          isLoading: _offersController.isLoading.value,
                          onPressed: _selectedIds.isEmpty ? null : _submit,
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
