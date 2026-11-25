import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_controller.dart';
import 'listings_controller.dart';
import '../core/constants/api_constants.dart';

/// Phase 1.3 — Contrôleur des Favoris (synchronisé PostgreSQL + cache local hors-ligne)
class FavoritesController extends GetxController {
  final favoriteIds = <String>{}.obs;
  final favoriteListings = <ListingModel>[].obs;
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

  bool isFavorite(String listingId) => favoriteIds.contains(listingId);

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('cached_fav_ids') ?? [];
      favoriteIds.addAll(cached);
    } catch (_) {}

    if (_auth.authToken.value.isEmpty) return;
    isLoading.value = true;
    try {
      final resp = await http.get(
        Uri.parse('$_apiUrl/favorites'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        final parsed = data.map((e) => ListingModel.fromJson(e)).toList();
        favoriteListings.value = parsed;
        favoriteIds
          ..clear()
          ..addAll(parsed.map((e) => e.id));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('cached_fav_ids', favoriteIds.toList());
      }
    } catch (e) {
      debugPrint('loadFavorites error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(ListingModel item) async {
    final exists = favoriteIds.contains(item.id);
    if (exists) {
      favoriteIds.remove(item.id);
      favoriteListings.removeWhere((l) => l.id == item.id);
    } else {
      favoriteIds.add(item.id);
      if (!favoriteListings.any((l) => l.id == item.id)) {
        favoriteListings.insert(0, item);
      }
    }
    favoriteIds.refresh();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_fav_ids', favoriteIds.toList());
    } catch (_) {}

    if (_auth.authToken.value.isEmpty) return;

    try {
      final uri = Uri.parse('$_apiUrl/favorites/${item.id}');
      if (exists) {
        await http.delete(uri, headers: _headers());
      } else {
        await http.post(uri, headers: _headers());
      }
    } catch (e) {
      debugPrint('toggleFavorite sync error: $e');
    }
  }
}
