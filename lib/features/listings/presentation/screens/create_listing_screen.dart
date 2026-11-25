import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({Key? key}) : super(key: key);

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final ListingsController _listingsController = Get.find<ListingsController>();
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _picker = ImagePicker();

  int _step = 1;
  final int _totalSteps = 4;
  bool _isPublishing = false;
  String? _duplicateError;
  ListingModel? _editingListing;

  bool get _isEditing => _editingListing != null;

  // Photos (parallel lists: _uploadedPhotoUrls has URL for every photo; _previewBytes has bytes or null for network photos)
  final List<String> _uploadedPhotoUrls = [];
  final List<Uint8List?> _previewBytes = [];
  bool _isUploadingPhoto = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _wishController = TextEditingController();
  final _brandController = TextEditingController();

  String _selectedCategory = 'Vêtements';
  String _selectedCondition = 'tres_bon';
  String _selectedCity = 'Meknès';

  final List<String> _categories = const [
    'Vêtements',
    'Électronique',
    'Maison',
    'Véhicules',
    'Sport',
    'Livres',
    'Bricolage',
  ];

  final List<Map<String, String>> _conditionOptions = const [
    {
      'key': 'neuf',
      'label': 'Neuf',
      'desc': 'Jamais utilisé, encore dans son emballage ou avec étiquette',
    },
    {
      'key': 'comme_neuf',
      'label': 'Comme neuf',
      'desc': 'Utilisé quelques fois, aucune trace visible',
    },
    {
      'key': 'tres_bon',
      'label': 'Très bon état',
      'desc': 'Légères traces d\'usage, fonctionne parfaitement',
    },
    {
      'key': 'bon',
      'label': 'Bon état',
      'desc': 'Signes d\'utilisation normaux, entièrement fonctionnel',
    },
    {
      'key': 'use',
      'label': 'Usé',
      'desc': 'Marques visibles ou petits défauts à préciser',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = _authController.selectedCity.value.isNotEmpty
        ? _authController.selectedCity.value
        : _listingsController.selectedCity.value;

    if (Get.arguments is ListingModel) {
      final item = Get.arguments as ListingModel;
      _editingListing = item;
      _titleController.text = item.title;
      _descController.text = item.description;
      if (_categories.contains(item.category)) {
        _selectedCategory = item.category;
      }
      if (_conditionOptions.any((c) => c['key'] == item.condition)) {
        _selectedCondition = item.condition;
      }
      if (item.city.isNotEmpty) {
        _selectedCity = item.city;
      }
      final brand = item.attributes['marque']?.toString() ?? '';
      _brandController.text = brand;
      if (item.wishes.isNotEmpty &&
          item.wishSummary.toLowerCase() != 'échange ouvert' &&
          item.wishSummary.toLowerCase() != 'ouvert aux propositions') {
        _wishController.text = item.wishes.join(', ');
      }
      for (final url in item.photos) {
        _uploadedPhotoUrls.add(url);
        _previewBytes.add(null);
      }
    }

    if (_listingsController.cities.isEmpty) {
      _listingsController.fetchCities();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _wishController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  String _conditionLabel(String key) {
    final found = _conditionOptions.firstWhere(
      (c) => c['key'] == key,
      orElse: () => {'label': key},
    );
    return found['label'] ?? key;
  }

  Future<void> _pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    if (_uploadedPhotoUrls.length >= 5) {
      Get.snackbar('Limite atteinte', 'Maximum 5 photos par annonce.');
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _isUploadingPhoto = true);
        final bytes = await picked.readAsBytes();
        final url = await _listingsController.uploadImage(picked);
        if (url != null) {
          setState(() {
            _uploadedPhotoUrls.add(url);
            _previewBytes.add(bytes);
          });
        } else {
          Get.snackbar(
            'Échec de l\'envoi',
            _listingsController.errorMessage.value.isNotEmpty
                ? _listingsController.errorMessage.value
                : 'Impossible d\'envoyer la photo.',
          );
        }
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Sélection impossible : $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _uploadedPhotoUrls.removeAt(index);
      if (index < _previewBytes.length) _previewBytes.removeAt(index);
    });
  }

  void _nextStep() {
    if (_step == 2 && _titleController.text.trim().length < 3) {
      setState(() => _duplicateError = 'Indiquez un titre d\'au moins 3 caractères.');
      return;
    }
    setState(() => _duplicateError = null);
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Get.back();
    }
  }

  Future<void> _publish() async {
    if (_isPublishing) return;

    final token = _authController.authToken.value;
    if (token.isEmpty) {
      Get.snackbar('Connexion requise', 'Connectez-vous pour publier une annonce.');
      Get.toNamed('/login');
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final attrs = <String, dynamic>{};
      if (_brandController.text.trim().isNotEmpty) {
        attrs['marque'] = _brandController.text.trim();
      }

      final success = _isEditing
          ? await _listingsController.updateListing(
              listingId: _editingListing!.id,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory,
              condition: _selectedCondition,
              city: _selectedCity,
              photos: _uploadedPhotoUrls,
              attributes: attrs,
              wishes: _wishController.text.trim().isNotEmpty
                  ? _wishController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList()
                  : ['Ouvert aux propositions'],
            )
          : await _listingsController.publishListingEnhanced(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory,
              condition: _selectedCondition,
              estimatedValue: 0.0,
              city: _selectedCity,
              photos: _uploadedPhotoUrls,
              attributes: attrs,
              wishes: _wishController.text.trim().isNotEmpty
                  ? _wishController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList()
                  : ['Ouvert aux propositions'],
            );
      if (success && mounted) {
        Get.offNamed('/my-listings', arguments: {
          'justPublished': true,
          'isEdited': _isEditing,
          'city': _selectedCity,
          'title': _titleController.text.trim(),
        });
        Get.snackbar(
          _isEditing ? 'Annonce modifiée !' : 'Annonce publiée !',
          _isEditing
              ? 'Vos modifications sur "${_titleController.text.trim()}" ont été enregistrées.'
              : 'Votre annonce "${_titleController.text.trim()}" est maintenant visible à $_selectedCity.',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else if (mounted && _listingsController.errorMessage.value.isNotEmpty) {
        setState(() => _duplicateError = _listingsController.errorMessage.value);
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 2),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_step == 1 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _prevStep,
        ),
        title: TroclyAppBarTitle(pageTitle: 'Étape $_step/$_totalSteps'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _step / _totalSteps,
                minHeight: 4,
                backgroundColor: AppColors.line,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: _buildStep(),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: _step == _totalSteps
                    ? (_isEditing ? 'Enregistrer les modifications' : 'Publier l\'annonce')
                    : 'Continuer',
                isLoading: _isPublishing,
                onPressed: _isPublishing ? null : _nextStep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _step1Photos();
      case 2:
        return _step2CoreInfo();
      case 3:
        return _step3DetailsAndWish();
      default:
        return _step4Review();
    }
  }

  Widget _step1Photos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ajoutez des photos', style: AppTypography.serif(size: 26)),
        const SizedBox(height: 6),
        Text(
          'Des photos nettes à la lumière naturelle attirent davantage de propositions. Jusqu\'à 5 photos.',
          style: AppTypography.sans(size: 13, color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...List.generate(_uploadedPhotoUrls.length, (i) {
              final bytes = i < _previewBytes.length ? _previewBytes[i] : null;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: bytes != null
                        ? Image.memory(
                            bytes,
                            width: 98,
                            height: 98,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _uploadedPhotoUrls[i],
                            width: 98,
                            height: 98,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 98,
                              height: 98,
                              color: AppColors.imagePlaceholder,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Couverture',
                          style: AppTypography.sans(size: 9.5, weight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (_uploadedPhotoUrls.length < 5)
              InkWell(
                onTap: _isUploadingPhoto ? null : () => _pickAndUploadImage(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderStrong, width: 1.2),
                  ),
                  child: _isUploadingPhoto
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera_outlined, size: 24, color: AppColors.textSecondary),
                            const SizedBox(height: 6),
                            Text(
                              '${_uploadedPhotoUrls.length} / 5',
                              style: AppTypography.sans(size: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aucun prix n\'est affiché sur Trocly. Les échanges et soultes éventuelles se négocient dans les offres.',
                  style: AppTypography.sans(size: 12.5, color: AppColors.ink, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _step2CoreInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Décrivez votre objet', style: AppTypography.serif(size: 26)),
        const SizedBox(height: 6),
        Text(
          'Un titre précis et un état honnête évitent les mauvaises surprises lors du rendez-vous.',
          style: AppTypography.sans(size: 13, color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 22),
        _fieldLabel('Titre'),
        TextField(
          controller: _titleController,
          maxLength: 60,
          onChanged: (_) {
            if (_duplicateError != null) setState(() => _duplicateError = null);
          },
          decoration: InputDecoration(
            hintText: 'ex. VTT Btwin Rockrider 520, taille M',
            errorText: _duplicateError,
          ),
        ),
        const SizedBox(height: 14),
        _fieldLabel('Catégorie'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        _fieldLabel('État'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: List.generate(_conditionOptions.length, (i) {
              final opt = _conditionOptions[i];
              final selected = opt['key'] == _selectedCondition;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedCondition = opt['key']!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? AppColors.ink : AppColors.borderStrong,
                                width: selected ? 5.5 : 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['label']!,
                                  style: AppTypography.sans(
                                    size: 13.5,
                                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt['desc']!,
                                  style: AppTypography.sans(size: 11.5, color: AppColors.textHint),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < _conditionOptions.length - 1) const Divider(),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _step3DetailsAndWish() {
    final cityNames = _listingsController.cities.isNotEmpty
        ? _listingsController.cities.map((c) => c.name).toList()
        : const ['Meknès', 'Fès', 'Rabat', 'Casablanca', 'Marrakech', 'Tanger', 'Agadir'];
    if (!cityNames.contains(_selectedCity)) {
      _selectedCity = cityNames.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détails et souhait d\'échange', style: AppTypography.serif(size: 26)),
        const SizedBox(height: 20),
        _fieldLabel('Description'),
        TextField(
          controller: _descController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Taille, accessoires fournis, défauts éventuels, quartier…',
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Marque (facultatif)'),
        TextField(
          controller: _brandController,
          decoration: const InputDecoration(hintText: 'ex. Btwin, Sony, Apple…'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Ce que vous recherchez en échange'),
        TextField(
          controller: _wishController,
          decoration: const InputDecoration(
            hintText: 'ex. Console de jeux, appareil photo (séparés par des virgules)',
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Ville'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              items: cityNames
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCity = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _step4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vérifiez votre annonce', style: AppTypography.serif(size: 26)),
        const SizedBox(height: 6),
        Text(
          'Elle sera visible immédiatement dans le fil de $_selectedCity.',
          style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        if (_uploadedPhotoUrls.isNotEmpty) ...[
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedPhotoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final bytes = i < _previewBytes.length ? _previewBytes[i] : null;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: bytes != null
                      ? Image.memory(bytes, width: 84, height: 84, fit: BoxFit.cover)
                      : Image.network(
                          _uploadedPhotoUrls[i],
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 84,
                            height: 84,
                            color: AppColors.imagePlaceholder,
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
        const Divider(),
        _reviewRow('Titre', _titleController.text.trim()),
        const Divider(),
        _reviewRow('Catégorie', _selectedCategory),
        const Divider(),
        _reviewRow('État', _conditionLabel(_selectedCondition)),
        const Divider(),
        _reviewRow('Ville', _selectedCity),
        const Divider(),
        _reviewRow(
          'Recherche en échange',
          _wishController.text.trim().isNotEmpty
              ? _wishController.text.trim()
              : 'Ouvert aux propositions',
        ),
        const Divider(),
        _reviewRow('Photos', '${_uploadedPhotoUrls.length} ajoutée(s)'),
        const Divider(),
        if (_duplicateError != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annonce similaire détectée (Règle B2)',
                  style: AppTypography.sans(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _duplicateError!,
                  style: AppTypography.sans(size: 12.5, color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTypography.sans(
          size: 12.5,
          weight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(label, style: AppTypography.sans(size: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.sans(size: 13.5, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
