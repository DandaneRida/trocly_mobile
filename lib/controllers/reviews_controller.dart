import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_controller.dart';
import '../core/constants/api_constants.dart';

class ReviewModel {
  final String id;
  final String reviewerName;
  final int rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      reviewerName: json['reviewer']?['displayName'] ?? 'Membre',
      rating: json['rating'] is int ? json['rating'] : 5,
      comment: json['comment'] ?? '',
      tags: json['tags'] is List
          ? List<String>.from(json['tags'])
          : const [],
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ??
              DateTime.now())
          : DateTime.now(),
    );
  }
}

class UserStatsModel {
  final String userId;
  final double averageRating;
  final int totalReviews;
  final int completedExchanges;
  final int trustScore;
  final List<ReviewModel> reviews;

  UserStatsModel({
    required this.userId,
    required this.averageRating,
    required this.totalReviews,
    this.completedExchanges = 0,
    this.trustScore = 75,
    required this.reviews,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      userId: json['userId']?.toString() ?? '',
      averageRating: double.tryParse(json['averageRating'].toString()) ?? 0.0,
      totalReviews: json['totalReviews'] is int ? json['totalReviews'] : 0,
      completedExchanges:
          json['completedExchanges'] is int ? json['completedExchanges'] : 0,
      trustScore: json['trustScore'] is int ? json['trustScore'] : 75,
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => ReviewModel.fromJson(r))
          .toList(),
    );
  }
}

class ReviewsController extends GetxController {
  final userStats = Rxn<UserStatsModel>();
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

  /// D5 - Post a mutual review (JWT authenticated)
  Future<bool> submitReview({
    required String meetingId,
    required int rating,
    required String comment,
    List<String> tags = const [],
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await http.post(
        Uri.parse('$_apiUrl/reviews'),
        headers: _headers(),
        body: jsonEncode({
          'meetingId': meetingId,
          'rating': rating,
          'comment': comment,
          'tags': tags,
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Get.snackbar(
          'Avis publié',
          'Merci ! Il sera visible dès que votre partenaire aura aussi noté (ou sous 7 jours).',
        );
        return true;
      } else {
        final err = jsonDecode(resp.body);
        errorMessage.value = err['message']?.toString() ?? 'Envoi impossible';
        Get.snackbar('Erreur', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Erreur réseau', 'Impossible d\'envoyer votre avis.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// E1 - Fetch trust score and reviews for a user
  Future<void> fetchUserStats(String userId) async {
    if (userId.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/reviews/user/$userId/stats'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        userStats.value = UserStatsModel.fromJson(jsonDecode(resp.body));
      }
    } catch (e) {
      debugPrint('Error fetchUserStats: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
