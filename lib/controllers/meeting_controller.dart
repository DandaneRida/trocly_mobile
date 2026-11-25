import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_controller.dart';
import '../core/constants/api_constants.dart';

class MeetingModel {
  final String id;
  final String offerId;
  final String initiatorId;
  final String initiatorName;
  final String responderId;
  final String responderName;
  final String proposedLocation;
  final DateTime scheduledAt;
  final DateTime expiresAt;
  final String status;
  final String? qrPayloadInitiator;
  final String? qrPayloadResponder;
  final DateTime? initiatorScannedAt;
  final DateTime? responderScannedAt;
  final String? cancelReason;
  final String? cancelledById;

  MeetingModel({
    required this.id,
    required this.offerId,
    required this.initiatorId,
    required this.initiatorName,
    required this.responderId,
    required this.responderName,
    required this.proposedLocation,
    required this.scheduledAt,
    required this.expiresAt,
    required this.status,
    this.qrPayloadInitiator,
    this.qrPayloadResponder,
    this.initiatorScannedAt,
    this.responderScannedAt,
    this.cancelReason,
    this.cancelledById,
  });

  bool isInitiator(String uid) => initiatorId == uid;

  String get statusLabel {
    switch (status) {
      case 'proposed':
        return 'En attente';
      case 'accepted':
        return 'Confirmé';
      case 'validated':
      case 'completed':
        return 'Validé';
      case 'cancelled':
        return 'Annulé';
      case 'expired':
        return 'Expiré';
      default:
        return status;
    }
  }

  String partnerName(String uid) =>
      isInitiator(uid) ? responderName : initiatorName;

  String? myQrPayload(String uid) =>
      isInitiator(uid) ? qrPayloadInitiator : qrPayloadResponder;

  bool iScannedPartner(String uid) =>
      isInitiator(uid) ? initiatorScannedAt != null : responderScannedAt != null;

  bool partnerScannedMe(String uid) =>
      isInitiator(uid) ? responderScannedAt != null : initiatorScannedAt != null;

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    final scheduled = DateTime.tryParse(json['scheduledAt']?.toString() ?? '')
            ?.toLocal() ??
        DateTime.now();
    final expires = DateTime.tryParse(json['expiresAt']?.toString() ?? '')
            ?.toLocal() ??
        scheduled.add(const Duration(hours: 2));

    return MeetingModel(
      id: json['id']?.toString() ?? '',
      offerId: json['offerId']?.toString() ?? '',
      initiatorId: json['initiator']?['id']?.toString() ?? '',
      initiatorName: json['initiator']?['displayName'] ?? 'Partenaire',
      responderId: json['responder']?['id']?.toString() ?? '',
      responderName: json['responder']?['displayName'] ?? 'Partenaire',
      proposedLocation: json['proposedLocation'] ?? 'Lieu à définir',
      scheduledAt: scheduled,
      expiresAt: expires,
      status: json['status'] ?? 'proposed',
      qrPayloadInitiator: json['qrPayloadInitiator'],
      qrPayloadResponder: json['qrPayloadResponder'],
      initiatorScannedAt: json['initiatorScannedAt'] != null
          ? DateTime.tryParse(json['initiatorScannedAt'].toString())?.toLocal()
          : null,
      responderScannedAt: json['responderScannedAt'] != null
          ? DateTime.tryParse(json['responderScannedAt'].toString())?.toLocal()
          : null,
      cancelReason: json['cancelReason']?.toString(),
      cancelledById: json['cancelledById']?.toString(),
    );
  }
}

class MeetingController extends GetxController {
  final isLoading = false.obs;
  final currentMeeting = Rxn<MeetingModel>();
  final myMeetings = <MeetingModel>[].obs;
  final qrCodeData = ''.obs;
  final validationSuccess = false.obs;
  final errorMessage = ''.obs;

  String get _apiUrl => ApiConstants.baseUrl;
  AuthController get _auth => Get.find<AuthController>();

  Map<String, String> _headers() {
    final token = _auth.authToken.value;
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// D1 - Propose a meeting (place + scheduledAt)
  Future<MeetingModel?> proposeMeeting({
    required String offerId,
    required String place,
    required DateTime scheduledAt,
    String? responderId,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/meetings'),
        headers: _headers(),
        body: jsonEncode({
          'offerId': offerId,
          'proposedLocation': place,
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          if (responderId != null && responderId.isNotEmpty)
            'responderId': responderId,
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final meeting = MeetingModel.fromJson(jsonDecode(resp.body));
        currentMeeting.value = meeting;
        Get.snackbar('Rendez-vous proposé', 'Votre partenaire a été notifié.');
        return meeting;
      } else {
        final err = jsonDecode(resp.body);
        errorMessage.value = err['message']?.toString() ?? 'Erreur lors de la création';
        Get.snackbar('Erreur', errorMessage.value);
        return null;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Erreur réseau', 'Impossible de joindre le serveur.');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMyMeetings() async {
    if (_auth.authToken.value.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/meetings/my-meetings'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final List list = jsonDecode(resp.body);
        myMeetings.value = list.map((e) => MeetingModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchMyMeetings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<MeetingModel?> fetchMeeting(String meetingId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/meetings/$meetingId'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final meeting = MeetingModel.fromJson(jsonDecode(resp.body));
        currentMeeting.value = meeting;
        qrCodeData.value = meeting.myQrPayload(_auth.userId.value) ?? '';
        return meeting;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetchMeeting: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// D2 - Accept a proposed meeting and retrieve signed QR payloads
  Future<MeetingModel?> acceptMeeting(String meetingId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/meetings/$meetingId/accept'),
        headers: _headers(),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final meeting = MeetingModel.fromJson(jsonDecode(resp.body));
        currentMeeting.value = meeting;
        qrCodeData.value = meeting.myQrPayload(_auth.userId.value) ?? '';
        Get.snackbar('Rendez-vous accepté', 'Les codes QR sont prêts.');
        return meeting;
      } else {
        final err = jsonDecode(resp.body);
        errorMessage.value = err['message']?.toString() ?? 'Action impossible';
        Get.snackbar('Erreur', errorMessage.value);
        return null;
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancel a proposed or accepted meeting and notify the partner
  Future<MeetingModel?> cancelMeeting(String meetingId, {String? reason}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/meetings/$meetingId/cancel'),
        headers: _headers(),
        body: jsonEncode({
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final meeting = MeetingModel.fromJson(jsonDecode(resp.body));
        currentMeeting.value = meeting;
        qrCodeData.value = '';
        await fetchMyMeetings();
        Get.snackbar(
          'Rendez-vous annulé',
          'Votre partenaire a reçu une notification d\'annulation.',
        );
        return meeting;
      } else {
        final err = jsonDecode(resp.body);
        errorMessage.value = err['message']?.toString() ?? 'Annulation impossible';
        Get.snackbar('Erreur', errorMessage.value);
        return null;
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', 'Impossible d\'annuler le rendez-vous.');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// D3 - Submit scanned partner QR payload
  Future<MeetingModel?> validateQRScan({required String scannedData}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/meetings/qr/scan'),
        headers: _headers(),
        body: jsonEncode({'payload': scannedData.trim()}),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final meeting = MeetingModel.fromJson(jsonDecode(resp.body));
        currentMeeting.value = meeting;
        validationSuccess.value =
            meeting.status == 'validated' || meeting.status == 'completed';
        if (validationSuccess.value) {
          Get.snackbar('Échange validé', 'Double scan confirmé !');
        } else {
          Get.snackbar(
            'Scan enregistré (1/2)',
            'Demandez maintenant à votre partenaire de scanner votre QR.',
          );
        }
        return meeting;
      } else {
        final err = jsonDecode(resp.body);
        errorMessage.value = err['message']?.toString() ?? 'QR code invalide';
        Get.snackbar('Scan refusé', errorMessage.value);
        return null;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Erreur réseau', 'Impossible de valider le code QR.');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
