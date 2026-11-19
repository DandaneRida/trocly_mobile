import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/listings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ListingsController _listingsController = Get.find<ListingsController>();
  final _nameController = TextEditingController();
  String _selectedCity = 'Meknès';

  final List<String> _fallbackCities = const [
    'Meknès',
    'Fès',
    'Rabat',
    'Casablanca',
    'Marrakech',
    'Tanger',
    'Agadir',
    'Oujda',
    'Kénitra',
    'Tétouan',
  ];

  @override
  void initState() {
    super.initState();
    if (_listingsController.cities.isEmpty) {
      _listingsController.fetchCities();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCityPicker() {
    final cityNames = _listingsController.cities.isNotEmpty
        ? _listingsController.cities.map((c) => c.name).toList()
        : _fallbackCities;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Votre ville', style: AppTypography.serif(size: 22)),
                const SizedBox(height: 10),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cityNames.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, idx) {
                      final city = cityNames[idx];
                      final isSelected = city == _selectedCity;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          city,
                          style: AppTypography.sans(
                            size: 14,
                            weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, size: 18, color: AppColors.accent)
                            : null,
                        onTap: () {
                          setState(() => _selectedCity = city);
                          _authController.selectedCity.value = city;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      Get.snackbar('Attention', 'Entrez un nom d\'affichage (au moins 2 caractères).');
      return;
    }
    _authController.userName.value = name;
    _authController.selectedCity.value = _selectedCity;
    _authController.completeProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Étape 3 sur 3',
          style: AppTypography.sans(size: 12.5, color: AppColors.textSecondary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 3,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                ),
              ),
              const SizedBox(height: 32),
              Text('Présentez-vous', style: AppTypography.serif(size: 28)),
              const SizedBox(height: 8),
              Text(
                'Ces informations apparaîtront sur vos annonces et dans vos conversations.',
                style: AppTypography.sans(size: 13.5, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 28),
              Text(
                'Nom d\'affichage',
                style: AppTypography.sans(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'ex. Salma El Idrissi'),
              ),
              const SizedBox(height: 18),
              Text(
                'Ville principale',
                style: AppTypography.sans(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showCityPicker,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedCity, style: AppTypography.sans(size: 14)),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Obx(
                () => PrimaryButton(
                  label: 'Commencer à échanger',
                  isLoading: _authController.isLoading.value,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
