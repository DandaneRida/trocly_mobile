import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/state_page.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({Key? key}) : super(key: key);

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final MeetingController _meetingController = Get.find<MeetingController>();
  final AuthController _authController = Get.find<AuthController>();
  String? _meetingId;

  static const _weekdays = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
  static const _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
  ];

  @override
  void initState() {
    super.initState();
    _meetingId = Get.parameters['meetingId'];
    if (_meetingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _meetingController.fetchMeeting(_meetingId!);
      });
    }
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _shortRef(String id) {
    final clean = id.replaceAll('-', '').toUpperCase();
    if (clean.length < 8) return 'TRC · $clean';
    return 'TRC · ${clean.substring(0, 4)} · ${clean.substring(4, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authController.userId.value;

    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Get.back(),
        ),
        title: const TroclyAppBarTitle(pageTitle: 'Rendez-vous'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              if (_meetingId != null) _meetingController.fetchMeeting(_meetingId!);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_meetingController.isLoading.value &&
            _meetingController.currentMeeting.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2),
          );
        }

        final meeting = _meetingController.currentMeeting.value;
        if (meeting == null) {
          return StatePage(
            type: StatePageType.emptyResults,
            customTitle: 'Rendez-vous introuvable',
            actionLabel: 'Retour',
            onAction: () => Get.back(),
          );
        }

        if (meeting.status == 'expired') {
          return StatePage(
            type: StatePageType.meetingExpired,
            actionLabel: 'Retour aux messages',
            onAction: () => Get.offAllNamed('/messages'),
          );
        }

        final dt = meeting.scheduledAt;
        final endSlot = dt.add(const Duration(minutes: 30));
        final partnerName = meeting.partnerName(uid);
        final myQr = meeting.myQrPayload(uid);
        final partnerScannedMe = meeting.partnerScannedMe(uid);
        final iScannedPartner = meeting.iScannedPartner(uid);
        final isValidated =
            meeting.status == 'validated' || meeting.status == 'completed';

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    // Cut-ticket card (matching Phone 6 of v3 mockup)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          // Top half: date + place + expiry
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(right: 16),
                                  decoration: const BoxDecoration(
                                    border: Border(right: BorderSide(color: AppColors.line)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _weekdays[(dt.weekday - 1) % 7].toUpperCase(),
                                        style: AppTypography.eyebrow(),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${dt.day}',
                                        style: AppTypography.serif(size: 38, height: 1.0),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _months[(dt.month - 1) % 12],
                                        style: AppTypography.sans(
                                          size: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_hhmm(dt)} – ${_hhmm(endSlot)}',
                                        style: AppTypography.sans(
                                          size: 15,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        meeting.proposedLocation,
                                        style: AppTypography.sans(
                                          size: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded,
                                              size: 14, color: AppColors.accent),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Expire à ${_hhmm(meeting.expiresAt)}',
                                            style: AppTypography.sans(
                                              size: 12,
                                              weight: FontWeight.w500,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Perforated divider with circular ticket cutouts
                          SizedBox(
                            height: 22,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final count = (constraints.maxWidth / 10).floor();
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        count,
                                        (_) => Container(
                                          width: 5,
                                          height: 1.2,
                                          color: AppColors.borderLight,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  left: -12,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppColors.paper,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.line),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -12,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppColors.paper,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.line),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom half: QR or pending acceptance
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                            child: meeting.status == 'proposed'
                                ? Column(
                                    children: [
                                      const Icon(Icons.hourglass_top_rounded,
                                          size: 36, color: AppColors.textSecondary),
                                      const SizedBox(height: 10),
                                      Text(
                                        'En attente d\'acceptation',
                                        style: AppTypography.serif(size: 20),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Une fois le rendez-vous accepté, vos deux codes QR personnels apparaîtront ici.',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.sans(
                                          size: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      PrimaryButton(
                                        label: 'Accepter et générer les QR',
                                        isLoading: _meetingController.isLoading.value,
                                        onPressed: () =>
                                            _meetingController.acceptMeeting(meeting.id),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      if (myQr != null && myQr.isNotEmpty)
                                        QrImageView(
                                          data: myQr,
                                          version: QrVersions.auto,
                                          size: 185,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: AppColors.ink,
                                          ),
                                          dataModuleStyle: const QrDataModuleStyle(
                                            dataModuleShape: QrDataModuleShape.square,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () {
                                          if (myQr != null) {
                                            Clipboard.setData(ClipboardData(text: myQr));
                                            Get.snackbar('Copié', 'Code QR copié dans le presse-papiers');
                                          }
                                        },
                                        child: Text(
                                          _shortRef(meeting.id),
                                          style: AppTypography.sans(
                                            size: 12,
                                            color: AppColors.textHint,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Double-scan checklist (D3)
                    if (meeting.status != 'proposed') ...[
                      _checkRow(
                        done: partnerScannedMe,
                        label: partnerScannedMe
                            ? '$partnerName a scanné votre code'
                            : 'En attente que $partnerName scanne votre code',
                      ),
                      const SizedBox(height: 10),
                      _checkRow(
                        done: iScannedPartner,
                        label: iScannedPartner
                            ? 'Vous avez scanné le code de $partnerName'
                            : 'Scannez le code de $partnerName',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Sticky bottom actions
            if (meeting.status != 'proposed')
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SafeArea(
                  top: false,
                  child: isValidated
                      ? PrimaryButton(
                          label: 'Laisser un avis à $partnerName',
                          icon: Icons.star_outline_rounded,
                          backgroundColor: AppColors.success,
                          onPressed: () => Get.toNamed('/review/${meeting.id}', arguments: meeting),
                        )
                      : PrimaryButton(
                          label: 'Scanner son code',
                          icon: Icons.qr_code_scanner_rounded,
                          onPressed: () async {
                            await Get.toNamed('/scan-qr/${meeting.id}');
                            _meetingController.fetchMeeting(meeting.id);
                          },
                        ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _checkRow({required bool done, required String label}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: done ? AppColors.success : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? AppColors.success : AppColors.borderStrong,
              width: 1.5,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.sans(
              size: 13.5,
              color: done ? AppColors.ink : AppColors.textSecondary,
              weight: done ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
