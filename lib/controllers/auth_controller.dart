import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';
import '../core/services/fcm_service.dart';

String get apiUrl => ApiConstants.baseUrl;

class AuthController extends GetxController {
  var isLoading = false.obs;
  var userId = ''.obs;
  var phone = ''.obs;
  var otp = ''.obs;
  var userName = ''.obs;
  var selectedCity = 'Meknès'.obs;
  var authToken = ''.obs;
  var refreshToken = ''.obs;
  var errorMessage = ''.obs;

  final storage = const FlutterSecureStorage();
  final client = http.Client();

  /// Decode JWT payload to populate userId (sub) without external dependencies
  void _hydrateFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is Map) {
        if (payload['sub'] != null && payload['pendingProfile'] != true) {
          userId.value = payload['sub'].toString();
        }
        if (payload['phone'] != null) {
          phone.value = payload['phone'].toString();
        }
      }
    } catch (e) {
      debugPrint('JWT decode warning: $e');
    }
  }

  /// Format phone number to +212 format
  String formatPhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      return '+212${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('212')) {
      return '+212$cleaned';
    }
    return '+$cleaned';
  }

  /// A2 - Send OTP via WhatsApp
  Future<void> sendOTP(String phoneNumber) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final formattedPhone = formatPhone(phoneNumber);
      final response = await client.post(
        Uri.parse('$apiUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': formattedPhone}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        phone.value = formattedPhone;
        Get.snackbar('Code envoyé', 'Vérifiez votre WhatsApp (ou les logs en mode dev).');
        Get.toNamed('/otp');
      } else {
        final error = jsonDecode(response.body);
        errorMessage.value = error['message']?.toString() ?? 'Échec d\'envoi du code';
        Get.snackbar('Erreur', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Erreur réseau : $e';
      Get.snackbar('Erreur', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// A2 & A4 - Verify OTP code and store JWT + refreshToken
  Future<void> verifyOTP(String code) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await client.post(
        Uri.parse('$apiUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phone.value,
          'code': code,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = (data['accessToken'] ?? data['tempToken'] ?? '').toString();
        authToken.value = token;
        if (token.isNotEmpty) {
          await storage.write(key: 'accessToken', value: token);
          _hydrateFromJwt(token);
        }

        if (data['refreshToken'] != null) {
          refreshToken.value = data['refreshToken'].toString();
          await storage.write(key: 'refreshToken', value: refreshToken.value);
        }

        if (data['user'] is Map) {
          final u = data['user'] as Map;
          if (u['id'] != null) userId.value = u['id'].toString();
          if (u['displayName'] != null) {
            userName.value = u['displayName'].toString();
            await storage.write(key: 'userName', value: userName.value);
          }
        }

        if (data['isNewUser'] == true || data['requiresProfile'] == true) {
          Get.toNamed('/complete-profile');
        } else {
          FcmService.initAndSyncToken();
          Get.offAllNamed('/feed');
        }
      } else {
        final error = jsonDecode(response.body);
        errorMessage.value = error['message']?.toString() ?? 'Code invalide';
        Get.snackbar('Erreur', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Erreur réseau : $e';
      Get.snackbar('Erreur', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// A3 - Complete profile for new users
  Future<void> completeProfile() async {
    isLoading.value = true;
    errorMessage.value = '';

    if (userName.value.trim().isEmpty) {
      errorMessage.value = 'Veuillez entrer votre nom d\'affichage';
      Get.snackbar('Attention', errorMessage.value);
      isLoading.value = false;
      return;
    }

    try {
      const cityMap = {
        'Meknès': 1,
        'Fès': 2,
        'Rabat': 3,
        'Casablanca': 4,
        'Marrakech': 5,
        'Tanger': 6,
        'Agadir': 7,
        'Oujda': 8,
        'Kénitra': 9,
        'Tétouan': 10,
      };

      final response = await client.post(
        Uri.parse('$apiUrl/auth/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authToken.value}',
        },
        body: jsonEncode({
          'displayName': userName.value.trim(),
          'cityId': cityMap[selectedCity.value] ?? 1,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        authToken.value = data['accessToken'].toString();
        await storage.write(key: 'accessToken', value: authToken.value);
        await storage.write(key: 'userName', value: userName.value.trim());
        _hydrateFromJwt(authToken.value);

        if (data['refreshToken'] != null) {
          refreshToken.value = data['refreshToken'].toString();
          await storage.write(key: 'refreshToken', value: refreshToken.value);
        }
        if (data['user'] is Map && data['user']['id'] != null) {
          userId.value = data['user']['id'].toString();
        }

        FcmService.initAndSyncToken();
        Get.snackbar('Bienvenue', 'Votre profil est prêt.');
        Get.offAllNamed('/feed');
      } else {
        final error = jsonDecode(response.body);
        errorMessage.value = error['message']?.toString() ?? 'Impossible de finaliser le profil';
        Get.snackbar('Erreur', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Erreur réseau : $e';
      Get.snackbar('Erreur', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// A5 - Logout (revoke refresh token on server + clear local secure storage)
  Future<void> logout() async {
    final rt = refreshToken.value;
    if (rt.isNotEmpty) {
      try {
        await client.post(
          Uri.parse('$apiUrl/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': rt}),
        );
      } catch (_) {}
    }

    authToken.value = '';
    refreshToken.value = '';
    userId.value = '';
    userName.value = '';
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'userName');
    Get.offAllNamed('/feed');
  }

  /// Phase 3.1 — Refresh short-lived JWT automatically via rotating Refresh Token
  Future<bool> refreshAccessToken() async {
    final rt = refreshToken.value;
    if (rt.isEmpty) return false;
    try {
      final resp = await client.post(
        Uri.parse('$apiUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        if (data['accessToken'] != null) {
          authToken.value = data['accessToken'].toString();
          await storage.write(key: 'accessToken', value: authToken.value);
          _hydrateFromJwt(authToken.value);
        }
        if (data['refreshToken'] != null) {
          refreshToken.value = data['refreshToken'].toString();
          await storage.write(key: 'refreshToken', value: refreshToken.value);
        }
        return true;
      }
    } catch (e) {
      debugPrint('refreshAccessToken warning: $e');
    }
    return false;
  }

  bool _isJwtExpiringSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (payload is Map && payload['exp'] is int) {
        final expMs = (payload['exp'] as int) * 1000;
        return DateTime.now().millisecondsSinceEpoch > (expMs - 90000);
      }
    } catch (_) {}
    return false;
  }

  /// Load stored token on app start (with automatic rotation if expiring)
  Future<void> loadStoredToken() async {
    try {
      final token = await storage.read(key: 'accessToken');
      final rt = await storage.read(key: 'refreshToken');
      final savedName = await storage.read(key: 'userName');
      if (rt != null && rt.isNotEmpty) {
        refreshToken.value = rt;
      }
      if (savedName != null && savedName.isNotEmpty) {
        userName.value = savedName;
      }
      if (token != null && token.isNotEmpty) {
        authToken.value = token;
        _hydrateFromJwt(token);
        if (_isJwtExpiringSoon(token) && refreshToken.value.isNotEmpty) {
          await refreshAccessToken();
        }
      }
    } catch (e) {
      debugPrint('Error loading token: $e');
    }
  }
}
