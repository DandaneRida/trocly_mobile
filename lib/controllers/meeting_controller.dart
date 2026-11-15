import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MeetingController extends GetxController {
  var isLoading = false.obs;
  var meetingId = ''.obs;
  var qrPayload = ''.obs;
  var scanResult = ''.obs;
  var validationSuccess = false.obs;

  /// SINGLE-SCAN: One QR scan validates the entire meeting
  Future<void> scanAndValidateQR(String payload, String userId) async {
    isLoading.value = true;
    try {
      // TODO: Call backend POST /meetings/qr/scan
      // with { payload, scannedByUserId: userId }
      // Response: Meeting with status = 'validated'
      
      qrPayload.value = payload;
      validationSuccess.value = true;
      Get.snackbar('Success', 'Meeting validated!');
      
      // Show success screen
      Future.delayed(Duration(seconds: 2), () {
        Get.to(() => MeetingSuccessScreen());
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to validate QR code');
    } finally {
      isLoading.value = false;
    }
  }
}

/// QR Code Scanner Screen - SINGLE SCAN VALIDATION
class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MeetingController controller = Get.find();
  late MobileScannerController scannerController;

  @override
  void initState() {
    super.initState();
    scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Meeting QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // One scan validates - no need for second scan
                  controller.scanAndValidateQR(barcode.rawValue!, 'current-user-id');
                  scannerController.stop();
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align QR code within frame',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success Screen after single QR scan
class MeetingSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Meeting Validated!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'The exchange has been confirmed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Get.offAllNamed('/feed'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
