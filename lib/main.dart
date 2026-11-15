import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/listings_controller.dart';
import 'controllers/meeting_controller.dart';

void main() {
  runApp(const TroclyApp());
}

class TroclyApp extends StatelessWidget {
  const TroclyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Trocly',
      theme: TroclyTheme.lightTheme(),
      home: LoginScreen(),
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/otp', page: () => OTPVerificationScreen()),
        GetPage(name: '/profile', page: () => ProfileCompletionScreen()),
        GetPage(name: '/feed', page: () => ListingsFeedScreen()),
        GetPage(name: '/qr-scan', page: () => QRScannerScreen()),
      ],
    );
  }
}

/// Login Screen - OTP Entry
class LoginScreen extends StatelessWidget {
  final phoneController = TextEditingController();
  final AuthController authController = Get.put(AuthController());
  final ListingsController listingsController = Get.put(ListingsController());
  final MeetingController meetingController = Get.put(MeetingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swap_horiz, size: 80, color: Colors.purple),
              const SizedBox(height: 20),
              const Text(
                'Trocly',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Trade items with your community',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixText: '+212 ',
                  hintText: '6 XX XX XX XX',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  label: const Text('Phone Number'),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => ElevatedButton(
                  onPressed: authController.isLoading.value
                      ? null
                      : () => authController.sendOTP('+212${phoneController.text}'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: authController.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Send OTP'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Get.snackbar('Info', 'Sign up via OTP'),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.to(() => ListingsFeedScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Browse as Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
