import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class _SafeZoneSpot {
  final String name;
  final String city;
  final LatLng coords;

  const _SafeZoneSpot({
    required this.name,
    required this.city,
    required this.coords,
  });
}

/// Phase 2.2 — Proposer un rendez-vous avec carte interactive OpenStreetMap 100 % gratuite (Safe Zones)
class ProposeMeetingScreen extends StatefulWidget {
  const ProposeMeetingScreen({Key? key}) : super(key: key);

  @override
  State<ProposeMeetingScreen> createState() => _ProposeMeetingScreenState();
}

class _ProposeMeetingScreenState extends State<ProposeMeetingScreen> {
  final MeetingController _meetingController = Get.find<MeetingController>();
  final _customPlaceController = TextEditingController();
  final MapController _mapController = MapController();

  String? _offerId;
  String? _responderId;
  String _selectedPlace = 'Place El Hedim, Meknès';
  LatLng _selectedCoords = const LatLng(33.8935, -5.5656);
  int _selectedHour = 15;
  int _selectedMinute = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final List<_SafeZoneSpot> _safeZones = const [
    _SafeZoneSpot(
      name: 'Place El Hedim, Meknès',
      city: 'Meknès',
      coords: LatLng(33.8935, -5.5656),
    ),
    _SafeZoneSpot(
      name: 'Gare Al Amir Abdelkader, Meknès',
      city: 'Meknès',
      coords: LatLng(33.8979, -5.5319),
    ),
    _SafeZoneSpot(
      name: 'Campus ENSAM Meknès (Marjane)',
      city: 'Meknès',
      coords: LatLng(33.8581, -5.5702),
    ),
    _SafeZoneSpot(
      name: 'Bab Boujloud, Fès',
      city: 'Fès',
      coords: LatLng(34.0617, -4.9846),
    ),
    _SafeZoneSpot(
      name: 'Gare Rabat Agdal',
      city: 'Rabat',
      coords: LatLng(34.0018, -6.8562),
    ),
    _SafeZoneSpot(
      name: 'Gare Casa Voyageurs',
      city: 'Casablanca',
      coords: LatLng(33.5898, -7.5908),
    ),
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

  void _selectSafeZone(_SafeZoneSpot spot) {
    setState(() {
      _selectedPlace = spot.name;
      _selectedCoords = spot.coords;
      _customPlaceController.clear();
    });
    try {
      _mapController.move(spot.coords, 14.5);
    } catch (_) {}
  }

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choisissez une Safe Zone',
                      style: AppTypography.serif(size: 23)),
                  const SizedBox(height: 5),
                  Text(
                    'Privilégiez un lieu public fréquenté. Touchez un repère sur la carte OpenStreetMap ou une pastille ci-dessous.',
                    style: AppTypography.sans(
                      size: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Carte interactive OpenStreetMap 100 % gratuite
                  Container(
                    height: 185,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedCoords,
                          initialZoom: 13.8,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ensam.trocly',
                          ),
                          MarkerLayer(
                            markers: _safeZones.map((spot) {
                              final selected = spot.name == _selectedPlace;
                              return Marker(
                                point: spot.coords,
                                width: selected ? 44 : 36,
                                height: selected ? 44 : 36,
                                child: GestureDetector(
                                  onTap: () => _selectSafeZone(spot),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.accent
                                          : AppColors.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: AppColors.pillShadow,
                                      border: Border.all(
                                        color: AppColors.accent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      size: selected ? 22 : 18,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.accent,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('SAFE ZONES VÉRIFIÉES', style: AppTypography.eyebrow()),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _safeZones.map((spot) {
                      final active = _selectedPlace == spot.name &&
                          _customPlaceController.text.trim().isEmpty;
                      return GestureDetector(
                        onTap: () => _selectSafeZone(spot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: active
                                ? AppColors.coralShadow
                                : AppColors.pillShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: active ? Colors.white : AppColors.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                spot.name,
                                style: AppTypography.sans(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: active ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ],
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
                      hintText: 'Ou précisez un autre lieu public (café, gare…)',
                      prefixIcon: Icon(Icons.edit_location_alt_outlined,
                          size: 19, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text('DATE DU RENDEZ-VOUS', style: AppTypography.eyebrow()),
                  const SizedBox(height: 10),
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
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Text(
                                '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                style: AppTypography.sans(
                                    size: 14.5, weight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Text(
                            'Modifier',
                            style: AppTypography.sans(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('CRÉNEAU HORAIRE', style: AppTypography.eyebrow()),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((s) {
                      final active =
                          _selectedHour == s[0] && _selectedMinute == s[1];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedHour = s[0];
                            _selectedMinute = s[1];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: active
                                ? AppColors.coralShadow
                                : AppColors.pillShadow,
                          ),
                          child: Text(
                            _formatSlot(s[0], s[1]),
                            style: AppTypography.sans(
                              size: 13,
                              weight: FontWeight.w700,
                              color: active ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Expiration automatique à ${_formatSlot(expires.hour, expires.minute)} (+2h après le créneau).',
                            style: AppTypography.sans(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
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
            child: Obx(
              () => PrimaryButton(
                label: 'Envoyer l\'invitation de RDV',
                icon: Icons.send_rounded,
                isLoading: _meetingController.isLoading.value,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
