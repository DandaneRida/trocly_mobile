import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../controllers/meeting_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({Key? key}) : super(key: key);

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MeetingController _meetingController = Get.find<MeetingController>();
  MobileScannerController? _cameraController;
  final _manualController = TextEditingController();

  String? _meetingId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _meetingId = Get.parameters['meetingId'];
    if (!kIsWeb) {
      _cameraController = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handlePayload(String code) async {
    if (_isProcessing || code.trim().isEmpty) return;
    setState(() => _isProcessing = true);
    _cameraController?.stop();

    final meeting = await _meetingController.validateQRScan(scannedData: code);
    if (!mounted) return;

    if (meeting != null) {
      if (meeting.status == 'validated' || meeting.status == 'completed') {
        Get.offNamed('/review/${meeting.id}', arguments: meeting);
      } else {
        Get.back(result: true);
      }
    } else {
      setState(() => _isProcessing = false);
      _cameraController?.start();
    }
  }

  void _showManualInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saisir le code QR manuellement', style: AppTypography.serif(size: 21)),
            const SizedBox(height: 6),
            Text(
              'Utile sur navigateur ou si la caméra est indisponible. Collez le code affiché sur le téléphone du partenaire.',
              style: AppTypography.sans(size: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _manualController,
              decoration: const InputDecoration(hintText: 'Coller le payload QR signé…'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Valider le scan',
              isLoading: _isProcessing,
              onPressed: () {
                Navigator.pop(ctx);
                _handlePayload(_manualController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const TroclyAppBarTitle(
          pageTitle: 'Scanner',
          darkBackground: true,
        ),
        centerTitle: false,
        actions: [
          if (_cameraController != null)
            IconButton(
              icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
              onPressed: () => _cameraController?.toggleTorch(),
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_outlined, color: Colors.white),
            tooltip: 'Saisie manuelle',
            onPressed: _showManualInput,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_cameraController != null)
            MobileScanner(
              controller: _cameraController!,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) {
                    _handlePayload(barcode.rawValue!);
                    break;
                  }
                }
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 52, color: Colors.white70),
                    const SizedBox(height: 16),
                    Text(
                      'Scanner caméra disponible sur mobile',
                      textAlign: TextAlign.center,
                      style: AppTypography.serif(size: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sur navigateur web, utilisez la saisie manuelle du payload QR pour tester le double scan.',
                      textAlign: TextAlign.center,
                      style: AppTypography.sans(size: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Coller le code QR du partenaire',
                      backgroundColor: AppColors.accent,
                      onPressed: _showManualInput,
                    ),
                  ],
                ),
              ),
            ),
          if (_cameraController != null)
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          if (_cameraController != null)
            Positioned(
              bottom: 36,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Text(
                    'Placez le QR code du partenaire dans le cadre',
                    textAlign: TextAlign.center,
                    style: AppTypography.sans(size: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _showManualInput,
                    child: Text(
                      'Saisir le code manuellement',
                      style: AppTypography.sans(
                        size: 12.5,
                        color: Colors.white70,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
