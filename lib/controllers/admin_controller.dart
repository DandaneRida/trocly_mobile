import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiUrl = 'http://localhost:3000';

// Report Controller
class ReportController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final client = http.Client();

  /// E2 - Report a user or listing
  Future<void> reportContent({
    required String reporterId,
    String? reportedUserId,
    String? reportedListingId,
    required String reportType,
    String? description,
  }) async {
    isLoading.value = true;
    try {
      final response = await client.post(
        Uri.parse('$apiUrl/reports?reporterId=$reporterId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reportedUserId': reportedUserId,
          'reportedListingId': reportedListingId,
          'reportType': reportType,
          'description': description,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar('Success', 'Report submitted. Thank you!');
        Get.back();
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar('Error', error['message'] ?? 'Failed to submit report');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

// Report Screen
class ReportScreen extends StatefulWidget {
  final String? reportedUserId;
  final String? reportedListingId;
  final String? reportedItemTitle;

  const ReportScreen({
    Key? key,
    this.reportedUserId,
    this.reportedListingId,
    this.reportedItemTitle,
  }) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportController controller = Get.find();
  final descriptionController = TextEditingController();
  String selectedReason = 'Abusive Content';

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Content')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Why are you reporting this?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: selectedReason,
              onChanged: (newVal) => setState(() => selectedReason = newVal ?? ''),
              items: [
                'Abusive Content',
                'Fraud',
                'Inappropriate Images',
                'Spam',
                'Other',
              ]
                  .map((reason) =>
                      DropdownMenuItem(value: reason, child: Text(reason)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Additional details (optional)',
                hintText: 'Explain why you\'re reporting this...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        controller.reportContent(
                          reporterId: 'current-user-id',
                          reportedUserId: widget.reportedUserId,
                          reportedListingId: widget.reportedListingId,
                          reportType: selectedReason.toLowerCase().replaceAll(' ', '_'),
                          description: descriptionController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Submit Report'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Your report will be reviewed by our moderation team. We take all reports seriously and will take action if needed.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Admin Dashboard Controller
class AdminController extends GetxController {
  var dashboardStats = Rx<Map<String, dynamic>?>(null);
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final client = http.Client();

  /// E4 - Fetch admin dashboard stats
  Future<void> fetchDashboardStats() async {
    isLoading.value = true;
    try {
      final response = await client.get(
        Uri.parse('$apiUrl/admin/dashboard'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        dashboardStats.value = data;
      } else {
        errorMessage.value = 'Failed to load dashboard';
      }
    } catch (e) {
      errorMessage.value = 'Network error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch pending reports
  Future<List<dynamic>> fetchPendingReports() async {
    try {
      final response = await client.get(
        Uri.parse('$apiUrl/admin/pending-reports'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminController controller = Get.find();

  @override
  void initState() {
    super.initState();
    controller.fetchDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.dashboardStats.value == null
                ? const Center(child: Text('No data'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatCard(
                          'Users',
                          controller.dashboardStats.value!['users']['total'].toString(),
                          Icons.person,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Active Listings',
                          controller.dashboardStats.value!['listings']['active'].toString(),
                          Icons.list,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Pending Offers',
                          controller.dashboardStats.value!['offers']['pending'].toString(),
                          Icons.handshake,
                          Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Validated Meetings',
                          controller.dashboardStats.value!['meetings']['validated'].toString(),
                          Icons.check_circle,
                          Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Pending Reports',
                          controller.dashboardStats.value!['reports']['pending'].toString(),
                          Icons.flag,
                          Colors.red,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.yellow[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 40),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Average Rating',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    controller.dashboardStats.value!['reviews']['averageRating']
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Get.to(() => const PendingReportsScreen()),
                          icon: const Icon(Icons.flag),
                          label: const Text('Review Pending Reports'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Pending Reports Screen
class PendingReportsScreen extends StatefulWidget {
  const PendingReportsScreen({Key? key}) : super(key: key);

  @override
  State<PendingReportsScreen> createState() => _PendingReportsScreenState();
}

class _PendingReportsScreenState extends State<PendingReportsScreen> {
  final AdminController controller = Get.find();
  late Future<List<dynamic>> reportsFuture;

  @override
  void initState() {
    super.initState();
    reportsFuture = controller.fetchPendingReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Reports')),
      body: FutureBuilder<List<dynamic>>(
        future: reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending reports'));
          }

          final reports = snapshot.data!;
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Report #${report['id'].substring(0, 8)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${report['reportType']}'),
                      Text('By: ${report['reporter']['displayName']}'),
                      if (report['description'].isNotEmpty)
                        Text('Description: ${report['description']}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(report['status'].toUpperCase()),
                    backgroundColor: report['status'] == 'pending'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
