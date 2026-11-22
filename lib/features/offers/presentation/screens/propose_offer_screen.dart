import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/offers_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
  final Set<String> _selectedIds = {};
  int _soulteMode = 0; // 0: Aucune, 1: Je verse, 2: Je reçois
  final _soulteController = TextEditingController();
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
    _soulteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  double get _soulteAmount {
    if (_soulteMode == 0) return 0;
    return double.tryParse(_soulteController.text.trim()) ?? 0;
  }

  String get _summaryLine {
    final myItems = _listingsController.myListings
        .where((l) => _selectedIds.contains(l.id))
        .map((l) => l.title)
        .toList();
    if (myItems.isEmpty) {
      return 'Sélectionnez au moins un objet ci-dessus';
    }
    final itemsStr = myItems.length == 1
        ? myItems.first
        : '${myItems.length} objets';
    final soulteStr = _soulteAmount > 0
        ? (_soulteMode == 1
            ? ' + ${_soulteAmount.toStringAsFixed(0)} DH'
            : ' (soulte demandée ${_soulteAmount.toStringAsFixed(0)} DH)')
        : '';
    return '$itemsStr$soulteStr contre ${_targetListing?.title ?? 'cet objet'}';
  }

  Future<void> _submit() async {
    if (_targetListing == null) return;
    if (_selectedIds.isEmpty) {
      Get.snackbar('Attention', 'Sélectionnez au moins un de vos objets.');
      return;
    }

    final offer = await _offersController.createOffer(
      targetListingId: _targetListing!.id,
      offeringListingIds: _selectedIds.toList(),
      soulte: _soulteAmount > 0 ? _soulteAmount : null,
      message: _messageController.text.trim(),
    );

    if (offer != null) {
      Get.offNamed('/chat/${offer.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Get.back(),
        ),
        title: Text('Votre proposition', style: AppTypography.sans(size: 16, weight: FontWeight.w600)),
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
                  // Target item row (matching Phone 4 of v3 mockup)
                  if (_targetListing != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 52,
                            height: 52,
                            color: AppColors.imagePlaceholder,
                            child: _targetListing!.photos.isNotEmpty
                                ? Image.network(_targetListing!.photos.first, fit: BoxFit.cover)
                                : const Icon(Icons.photo_outlined, color: AppColors.textHint),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vous souhaitez', style: AppTypography.sans(size: 11.5, color: AppColors.textHint)),
                              const SizedBox(height: 2),
                              Text(
                                _targetListing!.title,
                                style: AppTypography.sans(size: 14, weight: FontWeight.w600),
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

                  // Section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Ce que vous proposez', style: AppTypography.serif(size: 20)),
                      Text(
                        '${_selectedIds.length} sélectionné(s)',
                        style: AppTypography.sans(size: 11.5, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // My active listings checklist
                  Obx(() {
                    if (_listingsController.isMyListingsLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
                        ),
                      );
                    }
                    final myItems = _listingsController.myListings;
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
                              'Vous n\'avez aucune annonce active à proposer.',
                              style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () async {
                                final res = await Get.toNamed('/publish');
                                if (res == true) {
                                  _listingsController.fetchMyListings(status: 'active');
                                }
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
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.imagePlaceholder,
                                        child: item.photos.isNotEmpty
                                            ? Image.network(item.photos.first, fit: BoxFit.cover)
                                            : const Icon(Icons.photo_outlined, size: 20, color: AppColors.textHint),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title,
                                              style: AppTypography.sans(size: 13.5, weight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.condition} · ${item.city}',
                                            style: AppTypography.sans(size: 11.5, color: AppColors.textHint),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: checked ? AppColors.ink : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: checked ? AppColors.ink : AppColors.borderStrong,
                                        ),
                                      ),
                                      child: checked
                                          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
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

                  // Soulte segmented control (matching Phone 4 of v3 mockup)
                  Text(
                    'Soulte (facultatif)',
                    style: AppTypography.sans(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.segmentedBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _segment('Aucune', 0),
                        _segment('Je verse', 1),
                        _segment('Je reçois', 2),
                      ],
                    ),
                  ),
                  if (_soulteMode != 0) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _soulteController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '200',
                        suffixText: 'DH',
                        suffixStyle: AppTypography.sans(size: 13, color: AppColors.textHint),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Text(
                    'Message (facultatif)',
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
                      hintText: 'Précisez l\'état de vos objets ou vos disponibilités…',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky summary + CTA
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
                    style: AppTypography.sans(size: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => PrimaryButton(
                        label: 'Envoyer la proposition',
                        isLoading: _offersController.isLoading.value,
                        onPressed: _submit,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, int mode) {
    final active = _soulteMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _soulteMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.sans(
              size: 12.5,
              weight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.ink : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
