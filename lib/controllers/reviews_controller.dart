import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_constants.dart';

String get API_URL => ApiConstants.baseUrl;

// Models
class ReviewModel {
  String id;
  String reviewerName;
  int rating;
  String comment;
  DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      reviewerName: json['reviewer']['displayName'] ?? 'Unknown',
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class UserStatsModel {
  String userId;
  double averageRating;
  int totalReviews;
  List<ReviewModel> reviews;

  UserStatsModel({
    required this.userId,
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      userId: json['userId'],
      averageRating: double.parse(json['averageRating'].toString()),
      totalReviews: json['totalReviews'],
      reviews: (json['reviews'] as List).map((r) => ReviewModel.fromJson(r)).toList(),
    );
  }
}

class ReviewsController extends GetxController {
  var userStats = Rx<UserStatsModel?>(null);
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final client = http.Client();

  // Alias used by review_screen.dart
  Future<void> submitReview({
    required String meetingId,
    required int rating,
    required String comment,
  }) async {
    await postReview(
      meetingId: meetingId,
      reviewerId: '', // AuthController would supply this
      rating: rating,
      comment: comment,
    );
  }

  // D5 - Post review after meeting validation
  Future<void> postReview({
    required String meetingId,
    required String reviewerId,
    required int rating,
    required String comment,
  }) async {
    isLoading.value = true;
    try {
      final response = await client.post(
        Uri.parse('$API_URL/reviews?reviewerId=$reviewerId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'meetingId': meetingId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar('Success', 'Review posted!');
        Get.back();
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar('Error', error['message'] ?? 'Failed to post review');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // E1 - Get user stats
  Future<void> fetchUserStats(String userId) async {
    isLoading.value = true;
    try {
      final response = await client.get(
        Uri.parse('$API_URL/reviews/user/$userId/stats'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userStats.value = UserStatsModel.fromJson(data);
      } else {
        errorMessage.value = 'Failed to load stats';
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
    } finally {
      isLoading.value = false;
    }
  }
}

// Review Screen (after meeting validated)
class ReviewScreen extends StatefulWidget {
  final String meetingId;
  final String revieweeId;
  final String revieweeName;

  const ReviewScreen({
    required this.meetingId,
    required this.revieweeId,
    required this.revieweeName,
  });

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewsController controller = Get.find();
  final commentController = TextEditingController();
  int selectedRating = 5;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Exchange')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star, size: 60, color: Colors.purple),
            const SizedBox(height: 20),
            Text(
              'How was your exchange with ${widget.revieweeName}?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Star rating selector
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedRating = index + 1),
                      child: Icon(
                        Icons.star,
                        size: 40,
                        color: index < selectedRating ? Colors.orange : Colors.grey,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 30),
            // Comment text field
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Add a comment (optional)',
                hintText: 'Share your experience...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 30),
            // Submit button
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        controller.postReview(
                          meetingId: widget.meetingId,
                          reviewerId: 'current-user-id', // TODO: Get from auth
                          rating: selectedRating,
                          comment: commentController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// User Profile / Stats Screen
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ReviewsController controller = Get.find();

  @override
  void initState() {
    super.initState();
    controller.fetchUserStats(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.userStats.value == null
                ? const Center(child: Text('User not found'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Trust Score Card
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Trust Score',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${controller.userStats.value!.averageRating}',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      children: [
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              Icons.star,
                                              color: index <
                                                      controller.userStats.value!.averageRating
                                                          .toInt()
                                                  ? Colors.orange
                                                  : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${controller.userStats.value!.totalReviews} reviews',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Reviews section
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        controller.userStats.value!.reviews.isEmpty
                            ? const Text('No reviews yet')
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.userStats.value!.reviews.length,
                                itemBuilder: (context, index) {
                                  final review =
                                      controller.userStats.value!.reviews[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      title: Text(review.reviewerName),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                Icons.star,
                                                size: 16,
                                                color: i < review.rating
                                                    ? Colors.orange
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          if (review.comment.isNotEmpty)
                                            Text(review.comment),
                                        ],
                                      ),
                                      trailing: Text(
                                        review.createdAt.toString().split(' ')[0],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
