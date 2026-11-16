import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class ProposeMeetingScreen extends StatefulWidget {
  const ProposeMeetingScreen({Key? key}) : super(key: key);

  @override
  State<ProposeMeetingScreen> createState() => _ProposeMeetingScreenState();
}

class _ProposeMeetingScreenState extends State<ProposeMeetingScreen> {
  final MeetingController _meetingController = Get.find<MeetingController>();

  String? _offerId;
  String _selectedPlace = 'Place El Hedim, Meknès';
  String _selectedSlot = '15:30 - 16:00';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _suggestedPlaces = const [
    'Place El Hedim, Meknès',
    'Gare Al Amir Abdelkader',
    'Centre commercial Marjane',
    'Place Bab Boujloud, Fès',
    'Gare Casa Voyageurs',
    'Autre lieu public',
  ];

  final List<String> _slots = const [
    '10:00 - 10:30',
    '11:30 - 12:00',
    '14:30 - 15:00',
    '15:30 - 16:00',
    '17:00 - 17:30',
    '18:30 - 19:00',
  ];

  @override
  void initState() {
    super.initState();
    _offerId = Get.parameters['id'];
  }

  void _submit() {
    if (_offerId == null) {
      Get.snackbar('Erreur', 'Identifiant de l\'offre introuvable');
      return;
    }
    _meetingController.proposeMeeting(
      offerId: _offerId!,
      place: _selectedPlace,
      timeSlot: _selectedSlot,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Planifier le rendez-vous'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retrouvez-vous en toute sérénité',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choisissez un lieu public, éclairé et fréquenté pour valider l\'échange en sécurité.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    // Lieux sûrs suggestions
                    const Text('Lieu de rencontre suggéré :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedPlaces.map((place) {
                        final isSelected = place == _selectedPlace;
                        return ChoiceChip(
                          label: Text(place),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.primary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setState(() => _selectedPlace = place);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Date picker
                    const Text('Date :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Créneaux horaires
                    const Text('Créneau horaire :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots.map((slot) {
                        final isSelected = slot == _selectedSlot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSelected,
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setState(() => _selectedSlot = slot);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                label: 'Proposer le rendez-vous',
                icon: Icons.check_circle_outline,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
