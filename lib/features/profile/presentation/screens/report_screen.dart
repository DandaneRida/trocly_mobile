import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../controllers/auth_controller.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _detailsController = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();
  String _selectedReason = 'fraud';
  bool _isSubmitting = false;

  final Map<String, String> _reasons = const {
    'fraud': 'Suspicion de fraude ou arnaque',
    'fake_listing': 'Annonce trompeuse ou inexacte',
    'inappropriate_content': 'Contenu inapproprié ou interdit',
    'harassment': 'Comportement abusif ou harcèlement',
    'no_show': 'Absence au rendez-vous convenu',
    'other': 'Autre raison',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final args = Get.arguments is Map ? Map<String, dynamic>.from(Get.arguments) : {};
    final listingId = args['listingId']?.toString();
    final userId = args['userId']?.toString();

    try {
      final resp = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/reports'),
        headers: {
          'Content-Type': 'application/json',
          if (_auth.authToken.value.isNotEmpty)
            'Authorization': 'Bearer ${_auth.authToken.value}',
        },
        body: jsonEncode({
          if (listingId != null && listingId.isNotEmpty) 'reportedListingId': listingId,
          if (userId != null && userId.isNotEmpty) 'reportedUserId': userId,
          'reportType': _selectedReason,
          'description': _detailsController.text.trim(),
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Get.back();
        Get.snackbar('Signalement envoyé', 'Merci, l\'équipe de modération va l\'examiner.');
      } else {
        final err = jsonDecode(resp.body);
        Get.snackbar('Erreur', err['message']?.toString() ?? 'Impossible d\'envoyer le signalement');
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', 'Impossible de contacter le serveur.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text('Signaler', style: AppTypography.sans(size: 16, weight: FontWeight.w600)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quel est le problème ?', style: AppTypography.serif(size: 25)),
                  const SizedBox(height: 6),
                  Text(
                    'Votre signalement est confidentiel et examiné par la modération.',
                    style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: _reasons.entries.map((entry) {
                        final selected = entry.key == _selectedReason;
                        final isLast = entry.key == _reasons.keys.last;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _selectedReason = entry.key),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                child: Row(
                                  children: [
                                    Container(
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
                                      child: Text(
                                        entry.value,
                                        style: AppTypography.sans(
                                          size: 13.5,
                                          weight: selected ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast) const Divider(),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Précisions (facultatif)',
                    style: AppTypography.sans(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _detailsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Décrivez brièvement la situation…',
                    ),
                  ),
                ],
              ),
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
                label: 'Envoyer le signalement',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
