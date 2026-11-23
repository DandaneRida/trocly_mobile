import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class ProposeMeetingScreen extends StatefulWidget {
  const ProposeMeetingScreen({Key? key}) : super(key: key);

  @override
  State<ProposeMeetingScreen> createState() => _ProposeMeetingScreenState();
}

class _ProposeMeetingScreenState extends State<ProposeMeetingScreen> {
  final MeetingController _meetingController = Get.find<MeetingController>();
  final _customPlaceController = TextEditingController();

  String? _offerId;
  String? _responderId;
  String _selectedPlace = 'Place El Hedim, Meknès';
  int _selectedHour = 15;
  int _selectedMinute = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _suggestedPlaces = const [
    'Place El Hedim, Meknès',
    'Gare Al Amir Abdelkader, Meknès',
    'Marjane Meknès',
    'Bab Boujloud, Fès',
    'Gare Rabat Agdal',
    'Gare Casa Voyageurs',
  ];

  final List<List<int>> _slots = const [
    [10, 0],
    [11, 30],
    [14, 30],
    [15, 0],
    [17, 0],
    [18, 30],
  ];

  @override
  void initState() {
    super.initState();
    _offerId = Get.parameters['id'];
    if (Get.arguments is Map) {
      final args = Map<String, dynamic>.from(Get.arguments);
      _offerId ??= args['offerId']?.toString();
      _responderId = args['responderId']?.toString();
    }
  }

  @override
  void dispose() {
    _customPlaceController.dispose();
    super.dispose();
  }

  String _formatSlot(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  DateTime get _scheduledDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
        _selectedMinute,
      );

  Future<void> _submit() async {
    if (_offerId == null || _offerId!.isEmpty) {
      Get.snackbar('Erreur', 'Identifiant d\'offre manquant.');
      return;
    }
    final place = _customPlaceController.text.trim().isNotEmpty
        ? _customPlaceController.text.trim()
        : _selectedPlace;

    final meeting = await _meetingController.proposeMeeting(
      offerId: _offerId!,
      place: place,
      scheduledAt: _scheduledDateTime,
      responderId: _responderId,
    );
    if (meeting != null) {
      Get.offNamed('/my-qr/${meeting.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final expires = _scheduledDateTime.add(const Duration(hours: 2));

    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Get.back(),
        ),
        title: const TroclyAppBarTitle(pageTitle: 'Rendez-vous'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Un lieu public et un créneau', style: AppTypography.serif(size: 24)),
                  const SizedBox(height: 6),
                  Text(
                    'Une fois accepté par votre partenaire, vos deux codes QR seront générés. Le rendez-vous expire automatiquement 2 heures après le créneau.',
                    style: AppTypography.sans(
                      size: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text('LIEUX PUBLICS SUGGÉRÉS', style: AppTypography.eyebrow()),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedPlaces.map((place) {
                      final active = _selectedPlace == place &&
                          _customPlaceController.text.trim().isEmpty;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPlace = place;
                            _customPlaceController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppColors.ink : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: active ? AppColors.ink : AppColors.line,
                            ),
                          ),
                          child: Text(
                            place,
                            style: AppTypography.sans(
                              size: 12.5,
                              weight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _customPlaceController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Ou saisir un autre lieu public (café, place, gare…)',
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('DATE', style: AppTypography.eyebrow()),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
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
                          Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                            style: AppTypography.sans(size: 14, weight: FontWeight.w500),
                          ),
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text('CRÉNEAU', style: AppTypography.eyebrow()),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((s) {
                      final active = _selectedHour == s[0] && _selectedMinute == s[1];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedHour = s[0];
                            _selectedMinute = s[1];
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? AppColors.ink : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: active ? AppColors.ink : AppColors.line,
                            ),
                          ),
                          child: Text(
                            _formatSlot(s[0], s[1]),
                            style: AppTypography.sans(
                              size: 13,
                              weight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 17, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Expiration automatique à ${_formatSlot(expires.hour, expires.minute)} si le double scan n\'est pas effectué.',
                            style: AppTypography.sans(size: 12.5, color: AppColors.ink),
                          ),
                        ),
                      ],
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
                    label: 'Envoyer la proposition de RDV',
                    isLoading: _meetingController.isLoading.value,
                    onPressed: _submit,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
