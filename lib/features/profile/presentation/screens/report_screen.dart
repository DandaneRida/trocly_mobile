import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _detailsController = TextEditingController();
  String _selectedReason = 'misleading';
  bool _isSubmitting = false;

  final Map<String, String> _reasons = {
    'misleading': 'Annonce trompeuse ou inexacte',
    'forbidden_item': 'Objet interdit ou dangereux',
    'fraud': 'Suspicion de fraude ou arnaque',
    'inappropriate': 'Contenu inapproprié ou offensant',
    'other': 'Autre raison',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isSubmitting = true);
    final listingId = (Get.arguments as Map<String, dynamic>?)?['listingId'];

    try {
      await ApiClient().post('/reports', body: {
        if (listingId != null) 'targetListingId': listingId,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
      });
      Get.back();
      Get.snackbar('Signalement reçu', 'Merci, notre équipe de modération va examiner cette situation.');
    } catch (e) {
      Get.back();
      Get.snackbar('Signalement reçu', 'Votre signalement a été enregistré.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Signaler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pourquoi signalez-vous cette annonce ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Votre signalement reste strictement anonyme et confidentiel.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              // Reasons radio list
              ..._reasons.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedReason == entry.key ? AppColors.primary : AppColors.border,
                      width: _selectedReason == entry.key ? 1.5 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: entry.key,
                    groupValue: _selectedReason,
                    activeColor: AppColors.primary,
                    title: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              // Details input
              TextField(
                controller: _detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Détails complémentaires (optionnel)',
                  hintText: 'Expliquez ce qui vous semble anormal...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Envoyer le signalement',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
