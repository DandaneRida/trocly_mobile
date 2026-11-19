import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_controller.dart';
import '../core/constants/api_constants.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ??
              DateTime.now())
          : DateTime.now(),
    );
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}

class NotificationsController extends GetxController {
  final notifications = <NotificationItem>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  String get _apiUrl => ApiConstants.baseUrl;
  AuthController get _auth => Get.find<AuthController>();

  Map<String, String> _headers() {
    final token = _auth.authToken.value;
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchNotifications() async {
    if (_auth.authToken.value.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/notifications'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final List list = jsonDecode(resp.body);
        notifications.value =
            list.map((e) => NotificationItem.fromJson(e)).toList();
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('Error fetchNotifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    if (_auth.authToken.value.isEmpty) return;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/notifications/unread-count'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        unreadCount.value = data['unreadCount'] ?? 0;
      }
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    if (_auth.authToken.value.isEmpty) return;
    try {
      await http.patch(
        Uri.parse('$_apiUrl/notifications/$id/read'),
        headers: _headers(),
      );
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    if (_auth.authToken.value.isEmpty) return;
    try {
      await http.patch(
        Uri.parse('$_apiUrl/notifications/read-all'),
        headers: _headers(),
      );
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> registerDeviceToken(String fcmToken, {String platform = 'android'}) async {
    if (_auth.authToken.value.isEmpty || fcmToken.isEmpty) return;
    try {
      await http.post(
        Uri.parse('$_apiUrl/notifications/device-token'),
        headers: _headers(),
        body: jsonEncode({'token': fcmToken, 'platform': platform}),
      );
    } catch (_) {}
  }
}
