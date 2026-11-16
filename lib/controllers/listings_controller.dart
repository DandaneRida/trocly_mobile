import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'offers_controller.dart'; // Import MakeOfferScreen
import '../core/constants/api_constants.dart';

String get apiUrl => ApiConstants.baseUrl;

// Model
class ListingModel {
  String id;
  String title;
  String description;
  String category;
  String condition;
  double estimatedValue;
  String city;
  List<String> photos;
  String status;
  String userId;

  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.estimatedValue,
    required this.city,
    required this.photos,
    required this.status,
    required this.userId,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: json['category'],
      condition: json['condition'],
      estimatedValue: double.parse(json['estimatedValue'].toString()),
      city: json['city']?['name'] ?? 'Unknown',
      photos: List<String>.from(json['photos'] ?? []),
      status: json['status'],
      userId: json['user']['id'],
    );
  }
}

class ListingsController extends GetxController {
  var listings = <ListingModel>[].obs;
  var isLoading = false.obs;
  var selectedCity = 'Meknès'.obs;
  var selectedCategory = ''.obs;
  var categories = <String>[].obs;
  var conditions = <String>[].obs;
  var errorMessage = ''.obs;

  final client = http.Client();

  @override
  void onInit() {
    super.onInit();
    fetchListings();
    fetchCategories();
  }

  Future<void> fetchListings({
    int? cityId,
    String? category,
    String? condition,
    double? minValue,
    double? maxValue,
    int page = 1,
    int limit = 20,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      String query = '$apiUrl/listings?page=$page&limit=$limit';

      if (cityId != null) query += '&cityId=$cityId';
      if (category != null && category.isNotEmpty) query += '&category=$category';
      if (condition != null && condition.isNotEmpty) query += '&condition=$condition';
      if (minValue != null) query += '&minValue=$minValue';
      if (maxValue != null) query += '&maxValue=$maxValue';

      final response = await client.get(Uri.parse(query));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final listingsData = data['listings'] as List;
        listings.value = listingsData.map((l) => ListingModel.fromJson(l)).toList();
      } else {
        errorMessage.value = 'Failed to load listings';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await client.get(Uri.parse('$apiUrl/listings/meta/categories'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        categories.value = List<String>.from(data);
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchConditions() async {
    try {
      final response = await client.get(Uri.parse('$apiUrl/listings/meta/conditions'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        conditions.value = List<String>.from(data);
      }
    } catch (e) {
      print('Error fetching conditions: $e');
    }
  }

  void changeCity(String city) {
    selectedCity.value = city;
    final cityMap = {
      'Meknès': 1,
      'Fès': 2,
      'Rabat': 3,
      'Casablanca': 4,
      'Marrakech': 5,
    };
    fetchListings(cityId: cityMap[city] ?? 1);
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    final cityMap = {
      'Meknès': 1,
      'Fès': 2,
      'Rabat': 3,
      'Casablanca': 4,
      'Marrakech': 5,
    };
    fetchListings(
      cityId: cityMap[selectedCity.value] ?? 1,
      category: category.isEmpty ? null : category,
    );
  }

  Future<void> createListing(
    String userId, {
    required String title,
    required String description,
    required String category,
    required String condition,
    required double estimatedValue,
    required int cityId,
    List<String> photos = const [],
  }) async {
    isLoading.value = true;

    try {
      final response = await client.post(
        Uri.parse('$apiUrl/listings?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'condition': condition,
          'estimatedValue': estimatedValue,
          'cityId': cityId,
          'photos': photos,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar('Success', 'Listing published!');
        Get.back();
        await fetchListings();
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar('Error', error['message'] ?? 'Failed to create listing');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void filterByCity(String city) => changeCity(city);

  Future<void> searchListings(String keyword) async {
    isLoading.value = true;
    try {
      final response = await client.get(Uri.parse('$apiUrl/listings?search=$keyword'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['listings'] as List?) ?? [];
        listings.value = list.map((l) => ListingModel.fromJson(l)).toList();
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> publishListingEnhanced({
    required String title,
    required String description,
    required String category,
    required String condition,
    required double estimatedValue,
    required String city,
    required List<String> photos,
    required Map<String, dynamic> attributes,
    required List<String> wishes,
  }) async {
    final cityMap = {
      'Meknès': 1,
      'Fès': 2,
      'Rabat': 3,
      'Casablanca': 4,
      'Marrakech': 5,
    };
    await createListing(
      'current-user',
      title: title,
      description: description,
      category: category,
      condition: condition,
      estimatedValue: estimatedValue,
      cityId: cityMap[city] ?? 1,
      photos: photos,
    );
  }
}

// Listings Feed Screen
class ListingsFeedScreen extends StatelessWidget {
  final ListingsController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trocly Feed'),
        elevation: 0,
      ),
      body: Obx(
        () => Column(
          children: [
            // City Selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(
                () => DropdownButton(
                  isExpanded: true,
                  value: controller.selectedCity.value,
                  onChanged: (newVal) => controller.changeCity(newVal ?? 'Meknès'),
                  items: ['Meknès', 'Fès', 'Rabat', 'Casablanca', 'Marrakech']
                      .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                ),
              ),
            ),
            // Category Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => controller.categories.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Chip(
                              label: const Text('All'),
                              onDeleted:
                                  controller.selectedCategory.value.isEmpty ? null : () {},
                            ),
                            ...controller.categories.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => controller.filterByCategory(cat),
                                  child: Chip(
                                    label: Text(cat),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Listings Grid
            Expanded(
              child: controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.listings.isEmpty
                      ? const Center(
                          child: Text('No listings found'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: controller.listings.length,
                          itemBuilder: (context, index) {
                            final listing = controller.listings[index];
                            return GestureDetector(
                              onTap: () => Get.to(
                                () => ListingDetailScreen(listing: listing),
                              ),
                              child: Card(
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: Colors.grey[300],
                                        child: listing.photos.isNotEmpty
                                            ? Image.network(
                                                listing.photos.first,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image),
                                              )
                                            : const Icon(Icons.image, size: 80),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            listing.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${listing.estimatedValue} MAD',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            listing.condition,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => PublishListingScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Listing Detail Screen
class ListingDetailScreen extends StatelessWidget {
  final ListingModel listing;

  const ListingDetailScreen({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo carousel
            SizedBox(
              height: 250,
              child: listing.photos.isEmpty
                  ? Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.image, size: 100)),
                    )
                  : PageView(
                      children: listing.photos
                          .map(
                            (photo) => Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 100),
                                  ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${listing.estimatedValue} MAD',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    listing.description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Chip(label: Text(listing.category)),
                      const SizedBox(width: 10),
                      Chip(label: Text(listing.condition)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Get.to(
                      () => MakeOfferScreen(listing: listing),
                    ),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Make an Offer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Publish Listing Screen
class PublishListingScreen extends StatefulWidget {
  @override
  _PublishListingScreenState createState() => _PublishListingScreenState();
}

class _PublishListingScreenState extends State<PublishListingScreen> {
  final ListingsController controller = Get.find();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final estimatedValueController = TextEditingController();

  String selectedCategory = 'Electronics';
  String selectedCondition = 'Good';
  String selectedCity = 'Meknès';

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    estimatedValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cityMap = {
      'Meknès': 1,
      'Fès': 2,
      'Rabat': 3,
      'Casablanca': 4,
      'Marrakech': 5,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Publish Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: selectedCategory,
              onChanged: (newVal) => setState(() => selectedCategory = newVal ?? ''),
              items: ['Electronics', 'Furniture', 'Sports', 'Clothing', 'Books', 'Other']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: selectedCondition,
              onChanged: (newVal) => setState(() => selectedCondition = newVal ?? ''),
              items: ['Like New', 'Good', 'Fair', 'Poor']
                  .map((cond) => DropdownMenuItem(value: cond, child: Text(cond)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: estimatedValueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimated Value (MAD)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: selectedCity,
              onChanged: (newVal) => setState(() => selectedCity = newVal ?? ''),
              items: ['Meknès', 'Fès', 'Rabat', 'Casablanca', 'Marrakech']
                  .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        if (titleController.text.isEmpty ||
                            estimatedValueController.text.isEmpty) {
                          Get.snackbar('Error', 'Please fill all required fields');
                          return;
                        }

                        controller.createListing(
                          'current-user-id', // TODO: Get from auth
                          title: titleController.text,
                          description: descriptionController.text,
                          category: selectedCategory,
                          condition: selectedCondition,
                          estimatedValue: double.parse(estimatedValueController.text),
                          cityId: cityMap[selectedCity] ?? 1,
                        );
                      },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
