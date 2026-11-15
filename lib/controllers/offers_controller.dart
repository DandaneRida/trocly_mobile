import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String API_URL = 'http://localhost:3000';

// Models
class OfferItemModel {
  String id;
  String title;
  String category;
  double estimatedValue;

  OfferItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.estimatedValue,
  });

  factory OfferItemModel.fromJson(Map<String, dynamic> json) {
    return OfferItemModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      estimatedValue: double.parse(json['estimatedValue'].toString()),
    );
  }
}

class OfferModel {
  String id;
  String initiatorName;
  String initiatorId;
  String responderId;
  List<OfferItemModel> items;
  double? soulte;
  String message;
  String status;
  DateTime createdAt;

  OfferModel({
    required this.id,
    required this.initiatorName,
    required this.initiatorId,
    required this.responderId,
    required this.items,
    this.soulte,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      initiatorName: json['initiator']['displayName'] ?? 'Unknown',
      initiatorId: json['initiator']['id'],
      responderId: json['responder']['id'],
      items: (json['items'] as List)
          .map((item) => OfferItemModel.fromJson(item['listing']))
          .toList(),
      soulte: json['soulte'] != null ? double.parse(json['soulte'].toString()) : null,
      message: json['message'] ?? '',
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  double getTotalValue() {
    double total = items.fold(0, (sum, item) => sum + item.estimatedValue);
    if (soulte != null) total += soulte!;
    return total;
  }
}

class OffersController extends GetxController {
  var receivedOffers = <OfferModel>[].obs;
  var sentOffers = <OfferModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final client = http.Client();

  Future<void> fetchReceivedOffers(String userId) async {
    isLoading.value = true;
    try {
      final response = await client.get(
        Uri.parse('$API_URL/offers/user/received?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        receivedOffers.value = data.map((o) => OfferModel.fromJson(o)).toList();
      } else {
        errorMessage.value = 'Failed to load offers';
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSentOffers(String userId) async {
    isLoading.value = true;
    try {
      final response = await client.get(
        Uri.parse('$API_URL/offers/user/sent?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        sentOffers.value = data.map((o) => OfferModel.fromJson(o)).toList();
      } else {
        errorMessage.value = 'Failed to load offers';
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createOffer({
    required String initiatorId,
    required String responderId,
    required String targetListingId,
    required List<String> offeringListingIds,
    double? soulte,
    String? message,
  }) async {
    isLoading.value = true;
    try {
      final response = await client.post(
        Uri.parse('$API_URL/offers?initiatorId=$initiatorId&responderId=$responderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetListingId': targetListingId,
          'offeringListingIds': offeringListingIds,
          'soulte': soulte,
          'message': message,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar('Success', 'Offer sent!');
        Get.back();
        await fetchSentOffers(initiatorId);
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar('Error', error['message'] ?? 'Failed to send offer');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptOffer(String offerId, String userId) async {
    isLoading.value = true;
    try {
      final response = await client.patch(
        Uri.parse('$API_URL/offers/$offerId/accept?userId=$userId'),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Offer accepted!');
        await fetchReceivedOffers(userId);
      } else {
        Get.snackbar('Error', 'Failed to accept offer');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectOffer(String offerId, String userId) async {
    isLoading.value = true;
    try {
      final response = await client.patch(
        Uri.parse('$API_URL/offers/$offerId/reject?userId=$userId'),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Offer rejected');
        await fetchReceivedOffers(userId);
      } else {
        Get.snackbar('Error', 'Failed to reject offer');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

// Make Offer Screen
class MakeOfferScreen extends StatefulWidget {
  final dynamic listing; // ListingModel

  const MakeOfferScreen({required this.listing});

  @override
  _MakeOfferScreenState createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends State<MakeOfferScreen> {
  final OffersController controller = Get.find();
  final messageController = TextEditingController();
  final soulteController = TextEditingController();

  List<String> selectedMyListings = [];

  @override
  void dispose() {
    messageController.dispose();
    soulteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make an Offer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offering for: ${widget.listing.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Select your items to offer:'),
            const SizedBox(height: 10),
            // TODO: Implement multi-select for user's listings
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Select your listings here'),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: soulteController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Add soulte (optional, MAD)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message to seller',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        if (selectedMyListings.isEmpty) {
                          Get.snackbar('Error', 'Select at least one item');
                          return;
                        }

                        controller.createOffer(
                          initiatorId: 'current-user-id', // TODO: Get from auth
                          responderId: widget.listing.userId,
                          targetListingId: widget.listing.id,
                          offeringListingIds: selectedMyListings,
                          soulte: soulteController.text.isEmpty
                              ? null
                              : double.parse(soulteController.text),
                          message: messageController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Send Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Offer History Screen
class OfferHistoryScreen extends StatefulWidget {
  @override
  _OfferHistoryScreenState createState() => _OfferHistoryScreenState();
}

class _OfferHistoryScreenState extends State<OfferHistoryScreen> {
  final OffersController controller = Get.find();
  String _selectedTab = 'received'; // received, sent

  @override
  void initState() {
    super.initState();
    controller.fetchReceivedOffers('current-user-id'); // TODO: Get from auth
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 'received'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedTab == 'received' ? Colors.purple : Colors.grey,
                    ),
                    child: const Text('Received'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 'sent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 'sent' ? Colors.purple : Colors.grey,
                    ),
                    child: const Text('Sent'),
                  ),
                ),
              ],
            ),
          ),
          // Offers list
          Expanded(
            child: Obx(
              () {
                final offers = _selectedTab == 'received'
                    ? controller.receivedOffers
                    : controller.sentOffers;

                return controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : offers.isEmpty
                        ? const Center(child: Text('No offers'))
                        : ListView.builder(
                            itemCount: offers.length,
                            itemBuilder: (context, index) {
                              final offer = offers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text('From ${offer.initiatorName}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${offer.items.length} item(s)'),
                                      Text('Total: ${offer.getTotalValue()} MAD'),
                                      Text('Status: ${offer.status}'),
                                    ],
                                  ),
                                  trailing: _selectedTab == 'received' &&
                                          offer.status == 'pending'
                                      ? SizedBox(
                                          width: 100,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.check,
                                                    color: Colors.green),
                                                onPressed: () =>
                                                    controller.acceptOffer(
                                                        offer.id,
                                                        'current-user-id'),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    controller.rejectOffer(
                                                        offer.id,
                                                        'current-user-id'),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                  onTap: () => Get.to(
                                    () => OfferDetailScreen(offer: offer),
                                  ),
                                ),
                              );
                            },
                          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Offer Detail Screen
class OfferDetailScreen extends StatelessWidget {
  final OfferModel offer;

  const OfferDetailScreen({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From: ${offer.initiatorName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Status: ${offer.status.toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: offer.status == 'accepted' ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Items Being Offered:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...offer.items.map((item) {
              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text('${item.category} - ${item.estimatedValue} MAD'),
                ),
              );
            }).toList(),
            if (offer.soulte != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Additional money: ${offer.soulte} MAD',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            if (offer.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Message: ${offer.message}'),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Total Value: ${offer.getTotalValue()} MAD',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
