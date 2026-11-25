import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_controller.dart';
import '../core/constants/api_constants.dart';

class OfferItemModel {
  final String id;
  final String title;
  final String category;
  final double estimatedValue;

  OfferItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.estimatedValue,
  });

  factory OfferItemModel.fromJson(Map<String, dynamic> json) {
    return OfferItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      estimatedValue:
          double.tryParse(json['estimatedValue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OfferModel {
  final String id;
  final String initiatorName;
  final String initiatorId;
  final String responderName;
  final String responderId;
  final List<OfferItemModel> items;
  final double? soulte;
  final String message;
  final String status;
  final DateTime createdAt;

  OfferModel({
    required this.id,
    required this.initiatorName,
    required this.initiatorId,
    this.responderName = 'Membre',
    required this.responderId,
    required this.items,
    this.soulte,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      initiatorName: json['initiator']?['displayName'] ?? 'Membre',
      initiatorId: json['initiator']?['id']?.toString() ?? '',
      responderName: json['responder']?['displayName'] ?? 'Membre',
      responderId: json['responder']?['id']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .where((item) => item['listing'] != null)
          .map((item) => OfferItemModel.fromJson(item['listing']))
          .toList(),
      soulte: json['soulte'] != null
          ? double.tryParse(json['soulte'].toString())
          : null,
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ??
              DateTime.now())
          : DateTime.now(),
    );
  }
}

class OffersController extends GetxController {
  final receivedOffers = <OfferModel>[].obs;
  final sentOffers = <OfferModel>[].obs;
  final isLoading = false.obs;
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

  Future<void> fetchReceivedOffers([String? _]) async {
    if (_auth.authToken.value.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/offers/user/received'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        receivedOffers.value = data.map((o) => OfferModel.fromJson(o)).toList();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSentOffers([String? _]) async {
    if (_auth.authToken.value.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/offers/user/sent'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        sentOffers.value = data.map((o) => OfferModel.fromJson(o)).toList();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch single offer details (status, initiator/responder roles)
  Future<OfferModel?> fetchOfferById(String offerId) async {
    if (_auth.authToken.value.isEmpty) return null;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/offers/$offerId'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        return OfferModel.fromJson(jsonDecode(resp.body));
      }
    } catch (_) {}
    return null;
  }

  /// C1 - Create multi-object offer (JWT authenticated, mandatory >= 1 item, soultePossible boolean)
  Future<OfferModel?> createOffer({
    required String targetListingId,
    required List<String> offeringListingIds,
    bool soultePossible = false,
    String? message,
  }) async {
    if (offeringListingIds.isEmpty) {
      errorMessage.value = 'Veuillez sélectionner au moins un objet à échanger.';
      Get.snackbar('Attention', errorMessage.value);
      return null;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/offers'),
        headers: _headers(),
        body: jsonEncode({
          'targetListingId': targetListingId,
          'offeringListingIds': offeringListingIds,
          'soultePossible': soultePossible,
          if (message != null && message.isNotEmpty) 'message': message,
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final offer = OfferModel.fromJson(jsonDecode(resp.body));
        return offer;
      } else {
        final err = jsonDecode(resp.body);
        errorMessage.value = err['message']?.toString() ?? 'Envoi impossible';
        Get.snackbar('Erreur', errorMessage.value);
        return null;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Erreur réseau', 'Impossible d\'envoyer la proposition.');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// C3 - Accept offer
  Future<bool> acceptOffer(String offerId, [String? _]) async {
    isLoading.value = true;
    try {
      final resp = await http.patch(
        Uri.parse('$_apiUrl/offers/$offerId/accept'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        Get.snackbar('Offre acceptée', 'Vous pouvez maintenant planifier le rendez-vous QR.');
        return true;
      } else {
        final err = jsonDecode(resp.body);
        Get.snackbar('Erreur', err['message']?.toString() ?? 'Action impossible');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// C3 - Reject offer
  Future<bool> rejectOffer(String offerId, [String? _]) async {
    isLoading.value = true;
    try {
      final resp = await http.patch(
        Uri.parse('$_apiUrl/offers/$offerId/reject'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        Get.snackbar('Offre refusée', 'La proposition a été déclinée.');
        return true;
      } else {
        final err = jsonDecode(resp.body);
        Get.snackbar('Erreur', err['message']?.toString() ?? 'Action impossible');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// C2 - Counter-offer (supports soultePossible toggle, zero fixed price)
  Future<OfferModel?> createCounterOffer({
    required String originalOfferId,
    required List<String> counterListingIds,
    double? counterSoulte,
    bool soultePossible = false,
    String? message,
  }) async {
    isLoading.value = true;
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/offers/$originalOfferId/counter'),
        headers: _headers(),
        body: jsonEncode({
          'counterListingIds': counterListingIds,
          'soultePossible': soultePossible,
          if (counterSoulte != null && counterSoulte > 0)
            'counterSoulte': counterSoulte,
          if (message != null && message.isNotEmpty) 'message': message,
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final offer = OfferModel.fromJson(jsonDecode(resp.body));
        Get.snackbar('Contre-offre envoyée', 'Votre proposition modifiée a été transmise.');
        return offer;
      } else {
        final err = jsonDecode(resp.body);
        Get.snackbar('Erreur', err['message']?.toString() ?? 'Envoi impossible');
        return null;
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
