import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../controllers/reviews_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewsController _reviewsController = Get.find<ReviewsController>();
  final AuthController _authController = Get.find<AuthController>();
  final _commentController = TextEditingController();

  String? _meetingId;
  String _partnerName = 'votre partenaire';
  int _rating = 5;
  final Set<String> _selectedTags = {'Ponctuel', 'Objet conforme'};

  final List<String> _availableTags = const [
    'Ponctuel',
    'Objet conforme',
    'Aimable',
    'Réactif',
    'Bonne communication',
  ];

  @override
  void initState() {
    super.initState();
    _meetingId = Get.parameters['meetingId'];
    if (Get.arguments is MeetingModel) {
      final m = Get.arguments as MeetingModel;
      _partnerName = m.partnerName(_authController.userId.value);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Très bien';
      case 3:
        return 'Correct';
      case 2:
        return 'Moyen';
      default:
        return 'Décevant';
    }
  }

  Future<void> _submit() async {
    if (_meetingId == null) return;
    final ok = await _reviewsController.submitReview(
      meetingId: _meetingId!,
      rating: _rating,
      comment: _commentController.text.trim(),
      tags: _selectedTags.toList(),
    );
    if (ok) {
      Get.offAllNamed('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.offAllNamed('/feed'),
        ),
        title: const TroclyAppBarTitle(pageTitle: 'Avis'),
        actions: [
          TextButton(
            onPressed: () => Get.offAllNamed('/feed'),
            child: Text(
              'Plus tard',
              style: AppTypography.sans(size: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Validated badge row (Phone 7 of v3 mockup)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 5),
                            Text(
                              'Échange validé',
                              style: AppTypography.sans(
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Get.toNamed('/report'),
                        child: Text(
                          'Signaler un souci',
                          style: AppTypography.sans(size: 12, color: AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Comment s\'est passé l\'échange avec $_partnerName ?',
                    style: AppTypography.serif(size: 26, height: 1.2),
                  ),
                  const SizedBox(height: 20),

                  // Star rating (ink filled stars, matching v3)
                  Row(
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final active = star <= _rating;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = star),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(
                            active ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 36,
                            color: active ? AppColors.ink : AppColors.borderStrong,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabel,
                    style: AppTypography.sans(size: 14, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Qu\'avez-vous apprécié ?',
                    style: AppTypography.sans(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.ink : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? AppColors.ink : AppColors.line,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.sans(
                              size: 12.5,
                              weight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  Text(
                    'Commentaire',
                    style: AppTypography.sans(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Facultatif'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Votre avis sera publié dès que $_partnerName aura aussi donné le sien, ou automatiquement après 7 jours.',
                    style: AppTypography.sans(
                      size: 11.5,
                      color: AppColors.textHint,
                      height: 1.45,
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
              child: Obx(() => PrimaryButton(
                    label: 'Publier l\'avis',
                    isLoading: _reviewsController.isLoading.value,
                    onPressed: _submit,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
