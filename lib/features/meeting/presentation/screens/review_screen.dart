import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/reviews_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewsController _reviewsController = Get.find<ReviewsController>();
  final _commentController = TextEditingController();

  String? _meetingId;
  int _rating = 5;
  bool _confirmedExchange = false;

  @override
  void initState() {
    super.initState();
    _meetingId = Get.parameters['meetingId'];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_meetingId == null) return;
    _reviewsController.submitReview(
      meetingId: _meetingId!,
      rating: _rating,
      comment: _commentController.text.trim(),
    );
    Get.offAllNamed('/feed');
    Get.snackbar('Succès', 'Merci pour votre évaluation ! +1 échange réussi.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmation & Avis'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success badge icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              const Text(
                'Double scan effectué avec succès !',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Les deux participants ont validé leur présence physique au lieu convenu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              // Confirmation card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'L\'échange a-t-il été bien réalisé ?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Oui, échange réussi',
                            backgroundColor: _confirmedExchange ? AppColors.success : AppColors.primary,
                            onPressed: () {
                              setState(() => _confirmedExchange = true);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Get.toNamed('/report');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              foregroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Signaler un souci', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Rating stars
              const Text(
                'Comment s\'est passé l\'échange avec votre partenaire ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 36,
                    icon: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.warning,
                    ),
                    onPressed: () {
                      setState(() => _rating = starIndex);
                    },
                  );
                }),
              ),
              Text(
                _rating >= 4 ? 'Excellent !' : (_rating >= 3 ? 'Bien' : 'Mitigé'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              // Comment field
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Votre commentaire (optionnel)',
                  hintText: 'Ponctualité, état de l\'objet conforme, amabilité...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Soumettre l\'avis',
                onPressed: _submitReview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
