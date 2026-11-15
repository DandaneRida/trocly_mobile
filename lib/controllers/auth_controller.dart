import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String API_URL = 'http://localhost:3000'; // Change to your backend URL

class AuthController extends GetxController {
  var isLoading = false.obs;
  var phone = ''.obs;
  var otp = ''.obs;
  var userName = ''.obs;
  var selectedCity = 'Meknès'.obs;
  var authToken = ''.obs;
  var refreshToken = ''.obs;
  var errorMessage = ''.obs;

  final storage = const FlutterSecureStorage();
  final client = http.Client();

  /// Format phone number to +212 format
  String formatPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.startsWith('0')) {
      return '+212${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('212')) {
      return '+212$cleaned';
    }
    return '+$cleaned';
  }

  /// Send OTP via WhatsApp (Twilio backend)
  Future<void> sendOTP(String phoneNumber) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final formattedPhone = formatPhone(phoneNumber);

      final response = await client.post(
        Uri.parse('$API_URL/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': formattedPhone}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        phone.value = formattedPhone;
        Get.snackbar('Success', 'OTP sent to your WhatsApp');
        Get.to(() => OTPVerificationScreen());
      } else {
        final error = jsonDecode(response.body);
        errorMessage.value = error['message'] ?? 'Failed to send OTP';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify OTP code
  Future<void> verifyOTP(String code) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await client.post(
        Uri.parse('$API_URL/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phone.value,
          'code': code,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store token securely
        authToken.value = data['accessToken'];
        await storage.write(key: 'accessToken', value: data['accessToken']);

        if (data['refreshToken'] != null) {
          refreshToken.value = data['refreshToken'];
          await storage.write(key: 'refreshToken', value: data['refreshToken']);
        }

        // Check if new user or existing
        if (data['isNewUser'] == true) {
          Get.to(() => ProfileCompletionScreen());
        } else {
          Get.offAllNamed('/feed');
        }
      } else {
        final error = jsonDecode(response.body);
        errorMessage.value = error['message'] ?? 'Invalid OTP';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete profile for new users
  Future<void> completeProfile() async {
    isLoading.value = true;
    errorMessage.value = '';

    if (userName.value.isEmpty) {
      errorMessage.value = 'Please enter your name';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return;
    }

    try {
      final cityMap = {
        'Meknès': 1,
        'Fès': 2,
        'Rabat': 3,
        'Casablanca': 4,
        'Marrakech': 5,
      };

      final response = await client.post(
        Uri.parse('$API_URL/auth/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authToken.value}',
        },
        body: jsonEncode({
          'displayName': userName.value,
          'cityId': cityMap[selectedCity.value] ?? 1,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update tokens
        authToken.value = data['accessToken'];
        await storage.write(key: 'accessToken', value: data['accessToken']);

        if (data['refreshToken'] != null) {
          refreshToken.value = data['refreshToken'];
          await storage.write(key: 'refreshToken', value: data['refreshToken']);
        }

        Get.snackbar('Success', 'Profile completed!');
        Get.offAllNamed('/feed');
      } else {
        final error = jsonDecode(response.body);
        errorMessage.value = error['message'] ?? 'Failed to complete profile';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    authToken.value = '';
    refreshToken.value = '';
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
    Get.offAllNamed('/login');
  }

  /// Load stored token on app start
  Future<void> loadStoredToken() async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token != null) {
        authToken.value = token;
        // Optionally verify token is still valid
      }
    } catch (e) {
      print('Error loading token: $e');
    }
  }
}

// ==================== OTP Verification Screen ====================

class OTPVerificationScreen extends StatefulWidget {
  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final AuthController authController = Get.find();
  final otpController = TextEditingController();
  int secondsRemaining = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message, size: 60, color: Colors.purple),
            const SizedBox(height: 20),
            Text(
              'Enter the 6-digit code sent to',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 5),
            Obx(
              () => Text(
                authController.phone.value,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Expires in: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () => authController.verifyOTP(otpController.text),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: authController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Use different number'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Profile Completion Screen ====================

class ProfileCompletionScreen extends StatefulWidget {
  @override
  _ProfileCompletionScreenState createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final AuthController authController = Get.find();
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 60, color: Colors.purple),
            const SizedBox(height: 20),
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Your name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => DropdownButtonFormField(
                value: authController.selectedCity.value,
                onChanged: (newVal) => authController.selectedCity.value = newVal ?? 'Meknès',
                items: ['Meknès', 'Fès', 'Rabat', 'Casablanca', 'Marrakech']
                    .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                decoration: InputDecoration(
                  labelText: 'Main City',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Obx(
              () => ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () {
                        authController.userName.value = nameController.text;
                        authController.completeProfile();
                      },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: authController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Continue to Trocly'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
