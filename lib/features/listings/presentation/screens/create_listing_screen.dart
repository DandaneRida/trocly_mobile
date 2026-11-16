import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  int _step = 1;
  final int _totalSteps = 6;

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
    _listingsController.publishListingEnhanced(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      condition: _selectedCondition,
      estimatedValue: 0.0, // aucun prix stocké / symbolique
      city: _selectedCity,
      photos: [],
      attributes: _attributes,
      wishes: _wishController.text.trim().isNotEmpty
          ? [_wishController.text.trim()]
          : ['Échange ouvert'],
    );
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
                      child: PrimaryButton(
                        label: 'Retour',
                        isOutlined: true,
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
        Row(
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text('Photo principale', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Text('+ Ajouter (max 5)', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
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
              Text('Conseils pour réussir votre troc :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 6),
              Text('• Utilisez la lumière naturelle\n• Montrez l\'objet sous plusieurs angles\n• Signalez honnêtement les petits défauts',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Infos (Titre, Description)
  Widget _step2Infos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Titre et description',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titre de l\'annonce *',
            hintText: 'ex. Appareil photo vintage 35mm',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description détaillée',
            hintText: 'Précisez l\'état, les accessoires fournis, son histoire...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          'Catégorie et état de l\'objet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 18),
        const Text('Catégorie :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = cat == _selectedCategory;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (val) {
                setState(() => _selectedCategory = cat);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('État général :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _conditions.map((cond) {
            final isSelected = cond == _selectedCondition;
            final label = cond.replaceAll('_', ' ');
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (val) {
                setState(() => _selectedCondition = cond);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 4. Caractéristiques variables (JSONB)
  Widget _step4Attributes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Caractéristiques spécifiques (JSONB)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Renseignez les attributs propres à $_selectedCategory.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: 'Marque',
            hintText: 'ex. Sony, Apple, Decathlon...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => _attributes['marque'] = val,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Modèle',
            hintText: 'ex. Alpha 7, iPhone 12...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => _attributes['modele'] = val,
        ),
      ],
    );
  }

  // 5. Liste de souhaits ("Je recherche")
  Widget _step5Wishes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ce que vous recherchez en échange',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Aidez les autres utilisateurs à vous proposer le bon objet.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _wishController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Liste de souhaits',
            hintText: 'ex. Je cherche un vélo de ville, une tablette ou une enceinte Bluetooth...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // 6. Ville & Récapitulatif
  Widget _step6Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Récapitulatif & Publication',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
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
