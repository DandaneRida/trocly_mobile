import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/offers_controller.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class ProposeOfferScreen extends StatefulWidget {
  const ProposeOfferScreen({Key? key}) : super(key: key);

  @override
  State<ProposeOfferScreen> createState() => _ProposeOfferScreenState();
}

class _ProposeOfferScreenState extends State<ProposeOfferScreen> {
  final OffersController _offersController = Get.find<OffersController>();
  final ListingsController _listingsController = Get.find<ListingsController>();

  ListingModel? _targetListing;
  final Set<String> _selectedMyListingIds = {};
  bool _soultePossible = false;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetListing = Get.arguments as ListingModel?;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitOffer() {
    if (_targetListing == null) return;
    if (_selectedMyListingIds.isEmpty) {
      Get.snackbar('Attention', 'Veuillez sélectionner au moins un de vos objets à échanger.');
      return;
    }

    final authController = Get.find<AuthController>();
    _offersController.createOffer(
      initiatorId: authController.phone.value,
      responderId: _targetListing!.userId,
      targetListingId: _targetListing!.id,
      offeringListingIds: _selectedMyListingIds.toList(),
      soulte: _soultePossible ? 1.0 : 0.0,
      message: _messageController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Votre proposition'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target item pinned card
                    if (_targetListing != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.swap_horizontal_circle, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'VOUS SOUHAITEZ OBTENIR',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _targetListing!.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${_targetListing!.condition} · ${_targetListing!.city}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // My Listings multi-selection
                    const Text(
                      'Sélectionnez vos objets à proposer en échange',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vous pouvez sélectionner un ou plusieurs objets (multi-objets).',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final myList = _listingsController.listings;
                      if (myList.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              const Text('Vous n\'avez pas encore d\'annonces actives.'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Get.toNamed('/publish'),
                                child: const Text('Publier un objet d\'abord'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final myItem = myList[idx];
                          final isChecked = _selectedMyListingIds.contains(myItem.id);
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChecked ? AppColors.primary : AppColors.border,
                                width: isChecked ? 1.5 : 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isChecked,
                              activeColor: AppColors.primary,
                              title: Text(myItem.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${myItem.condition} · ${myItem.city}', style: const TextStyle(fontSize: 11)),
                              secondary: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.image_outlined, size: 24, color: AppColors.textSecondary),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedMyListingIds.add(myItem.id);
                                  } else {
                                    _selectedMyListingIds.remove(myItem.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    // Soulte possible toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Soulte possible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(height: 2),
                                Text(
                                  'Si oui, le montant se discute dans le chat (aucun montant fixe stocké).',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _soultePossible,
                            activeColor: AppColors.accent,
                            onChanged: (val) {
                              setState(() => _soultePossible = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Message
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message pour le propriétaire',
                        hintText: 'Bonjour, votre annonce m\'intéresse. Seriez-vous d\'accord pour cet échange ?',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Obx(
                () => PrimaryButton(
                  label: 'Envoyer la proposition',
                  icon: Icons.send_rounded,
                  isLoading: _offersController.isLoading.value,
                  onPressed: _submitOffer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
