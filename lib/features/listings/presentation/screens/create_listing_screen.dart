import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

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
  final int _totalSteps = 6;

  // Photos
  final List<String> _uploadedPhotoUrls = [];
  final List<Uint8List> _previewBytes = [];
  bool _isUploadingPhoto = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _wishController = TextEditingController();

  String _selectedCategory = 'Électronique';
  String _selectedCondition = 'bon';
  String _selectedCity = 'Meknès';

  // Dynamic attributes (JSONB)
  final Map<String, String> _attributes = {
    'marque': '',
    'modele': '',
  };

  final List<String> _categories = const [
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
    _selectedCity = _authController.selectedCity.value;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _wishController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    if (_uploadedPhotoUrls.length >= 5) {
      Get.snackbar('Limite atteinte', 'Vous pouvez ajouter 5 photos au maximum.');
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
          Get.snackbar('Photo ajoutée', 'Photo téléchargée avec succès');
        } else {
          Get.snackbar(
            'Erreur',
            _listingsController.errorMessage.value.isNotEmpty
                ? _listingsController.errorMessage.value
                : 'Échec du téléchargement de la photo (Assurez-vous que le backend tourne sur le port 3000)',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de sélectionner la photo: $e');
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _uploadedPhotoUrls.removeAt(index);
      if (index < _previewBytes.length) {
        _previewBytes.removeAt(index);
      }
    });
  }

  void _nextStep() {
    if (_step == 2 && _titleController.text.trim().isEmpty) {
      Get.snackbar('Attention', 'Veuillez saisir un titre pour votre annonce');
      return;
    }
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

  void _publish() async {
    final token = _authController.authToken.value;
    if (token.isEmpty) {
      Get.snackbar(
        'Connexion requise',
        'Veuillez vous connecter pour pouvoir publier une annonce',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      Get.toNamed('/login');
      return;
    }

    final success = await _listingsController.publishListingEnhanced(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      condition: _selectedCondition,
      estimatedValue: 0.0,
      city: _selectedCity,
      photos: _uploadedPhotoUrls,
      attributes: _attributes,
      wishes: _wishController.text.trim().isNotEmpty
          ? [_wishController.text.trim()]
          : ['Échange ouvert'],
    );
    if (success) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Nouvelle annonce · $_step/$_totalSteps'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: _step / _totalSteps,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: _buildStepContent(),
              ),
            ),
            // Bottom Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_step > 1) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Précédent'),
                        onPressed: _prevStep,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _step == _totalSteps ? 'Publier l\'annonce' : 'Continuer',
                      onPressed: _nextStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _step1Photos();
      case 2:
        return _step2Infos();
      case 3:
        return _step3Category();
      case 4:
        return _step4Attributes();
      case 5:
        return _step5Wishes();
      case 6:
        return _step6Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. Photos
  Widget _step1Photos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajoutez de belles photos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          '1 à 5 photos pour mettre en valeur votre objet.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Grille de photos affichées
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._uploadedPhotoUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final hasBytes = index < _previewBytes.length;
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      image: hasBytes
                          ? DecorationImage(
                              image: MemoryImage(_previewBytes[index]),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasBytes
                        ? const Center(child: Icon(Icons.image, color: AppColors.primary))
                        : null,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Principale', style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ),
                ],
              );
            }),

            // Bouton Ajouter
            if (_uploadedPhotoUrls.length < 5)
              GestureDetector(
                onTap: _isUploadingPhoto ? null : () => _pickAndUploadImage(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: _isUploadingPhoto
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.primary),
                            SizedBox(height: 6),
                            Text('+ Photo', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '💡 Conseils pour vos photos :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              SizedBox(height: 8),
              Text(
                '• Formats acceptés : JPEG, PNG, WebP (max 5 Mo)\n• Prenez l\'objet sous une bonne lumière naturelle\n• Montrez les détails et marques d\'usure',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Infos principales
  Widget _step2Infos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Décrivez votre objet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Donnez envie aux autres troqueurs.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titre de l\'annonce *',
            hintText: 'Ex: VTT Btwin Rockrider 520 taille M',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description détaillée',
            hintText: 'Précisez l\'état, les accessoires fournis, la raison de l\'échange...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'Ville où l\'objet est disponible *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _listingsController.cities.isNotEmpty
              ? _listingsController.cities
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList()
              : ['Meknès', 'Fès', 'Rabat', 'Casablanca', 'Marrakech']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCity = val);
          },
        ),
      ],
    );
  }

  // 3. Catégorie & État
  Widget _step3Category() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catégorie & État de l\'objet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Permet un classement optimal dans le feed.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        const Text(
          'Catégorie *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selectedCategory = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'État du produit *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _conditions.map((cond) {
            final isSelected = _selectedCondition == cond;
            return ChoiceChip(
              label: Text(cond.replaceAll('_', ' ')),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.accent,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selectedCondition = cond),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 4. Attributs dynamiques (JSONB)
  Widget _step4Attributes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Caractéristiques spécifiques',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Facultatif : Renseignez la marque ou le modèle si applicable.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: InputDecoration(
            labelText: 'Marque',
            hintText: 'Ex: Apple, Decathlon, Nike...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => _attributes['marque'] = val,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Modèle / Référence',
            hintText: 'Ex: iPhone 13, Rockrider 520...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => _attributes['modele'] = val,
        ),
      ],
    );
  }

  // 5. Ce que vous recherchez en échange
  Widget _step5Wishes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Que recherchez-vous en échange ?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Indiquez des idées ou laissez ouvert à toute proposition.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _wishController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Objets souhaités',
            hintText: 'Ex: Trottinette, jeux PS5, matériel de camping ou ouvert...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // 6. Récapitulatif
  Widget _step6Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vérifiez votre annonce',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Votre annonce sera visible instantanément par la communauté.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.isNotEmpty ? _titleController.text : 'Sans titre',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Catégorie : $_selectedCategory',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                'État : ${_selectedCondition.replaceAll('_', ' ')}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                'Ville : $_selectedCity',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                'Photos : ${_uploadedPhotoUrls.length} ajoutée(s)',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              if (_wishController.text.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  'Recherche : ${_wishController.text}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rappel Trocly : Aucun prix n\'est affiché ni stocké. Les propositions d\'échange et soultes éventuelles se négocient dans le chat.',
                  style: TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
