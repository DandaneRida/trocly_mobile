import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'auth_controller.dart';
import 'offers_controller.dart';
import '../core/constants/api_constants.dart';

String get apiUrl => ApiConstants.baseUrl;

// Model City
class CityModel {
  final int id;
  final String name;

  CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
    );
  }
}

// Model Listing
class ListingModel {
  String id;
  String title;
  String description;
  String category;
  String condition;
  double estimatedValue;
  String city;
  int? cityId;
  List<String> photos;
  String status;
  String userId;
  String? userName;
  Map<String, dynamic> attributes;

  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.estimatedValue,
    required this.city,
    this.cityId,
    required this.photos,
    required this.status,
    required this.userId,
    this.userName,
    this.attributes = const {},
  });

  List<String> get wishes {
    final w = attributes['wishes'];
    if (w is List) {
      return w.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return const [];
  }

  String get wishSummary => wishes.isNotEmpty ? wishes.join(', ') : 'Ouvert aux propositions';

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = List<String>.from(json['photos'] ?? []);
    final fullPhotos = rawPhotos.map((url) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      return '$apiUrl$url';
    }).toList();

    final rawAttrs = json['attributes'];
    final parsedAttrs = rawAttrs is Map
        ? Map<String, dynamic>.from(rawAttrs)
        : <String, dynamic>{};

    return ListingModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      estimatedValue: json['estimatedValue'] != null
          ? double.tryParse(json['estimatedValue'].toString()) ?? 0.0
          : 0.0,
      city: json['city']?['name'] ?? 'Inconnue',
      cityId: json['city']?['id'] is int ? json['city']['id'] : null,
      photos: fullPhotos,
      status: json['status'] ?? 'active',
      userId: json['user']?['id']?.toString() ?? '',
      userName: json['user']?['displayName'],
      attributes: parsedAttrs,
    );
  }
}

class ListingsController extends GetxController {
  var listings = <ListingModel>[].obs;
  var myListings = <ListingModel>[].obs;
  var isLoading = false.obs;
  var isMyListingsLoading = false.obs;

  var selectedCity = 'Meknès'.obs;
  var selectedCityId = Rxn<int>(1);
  var selectedCategory = ''.obs;
  var categories = <String>[].obs;
  var conditions = <String>[].obs;
  var cities = <CityModel>[].obs;
  var errorMessage = ''.obs;

  final client = http.Client();

  Map<String, String> _getAuthHeaders() {
    final authController = Get.find<AuthController>();
    final token = authController.authToken.value;
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  void onInit() {
    super.onInit();
    fetchCities();
    fetchCategories();
    fetchConditions();
    fetchListings();
  }

  /// Upload une photo sélectionnée sur le backend
  Future<String?> uploadImage(XFile file) async {
    try {
      final authController = Get.find<AuthController>();
      final uri = Uri.parse('$apiUrl/upload/image');
      final request = http.MultipartRequest('POST', uri);

      if (authController.authToken.value.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${authController.authToken.value}';
      }

      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty ? file.name : 'photo.jpg';

      // Détecter le MediaType approprié
      MediaType contentType = MediaType('image', 'jpeg');
      if (name.toLowerCase().endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (name.toLowerCase().endsWith('.webp')) {
        contentType = MediaType('image', 'webp');
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final relativeUrl = data['data']?['url'];
        if (relativeUrl != null) {
          return relativeUrl.toString();
        }
      } else {
        debugPrint('Upload failed with status: ${response.statusCode}, body: ${response.body}');
        errorMessage.value = 'Erreur serveur (${response.statusCode}) : ${response.body}';
      }
    } catch (e) {
      debugPrint('Error uploadImage: $e');
      errorMessage.value = 'Erreur réseau: $e';
    }
    return null;
  }

  /// Récupération dynamique des villes (Story B5)
  Future<void> fetchCities() async {
    try {
      final response = await client.get(Uri.parse('$apiUrl/cities'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        cities.value = data.map((c) => CityModel.fromJson(c)).toList();
        if (cities.isNotEmpty) {
          final found = cities.firstWhereOrNull((c) => c.name == selectedCity.value);
          if (found != null) {
            selectedCityId.value = found.id;
          } else {
            selectedCity.value = cities.first.name;
            selectedCityId.value = cities.first.id;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    }
  }

  /// Récupération des catégories
  Future<void> fetchCategories() async {
    try {
      final response = await client.get(Uri.parse('$apiUrl/listings/meta/categories'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        categories.value = List<String>.from(data);
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  /// Récupération des conditions
  Future<void> fetchConditions() async {
    try {
      final response = await client.get(Uri.parse('$apiUrl/listings/meta/conditions'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        conditions.value = List<String>.from(data);
      }
    } catch (e) {
      debugPrint('Error fetching conditions: $e');
    }
  }

  /// Story A1 / B4 - Récupération filtrée du feed
  Future<void> fetchListings({
    int? cityId,
    bool allCities = false,
    String? category,
    String? condition,
    double? minValue,
    double? maxValue,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (!allCities) {
        final effectiveCityId = cityId ?? selectedCityId.value;
        if (effectiveCityId != null) {
          queryParams['cityId'] = effectiveCityId.toString();
        }
      }

      final effectiveCategory = category ?? (selectedCategory.value.isNotEmpty ? selectedCategory.value : null);
      if (effectiveCategory != null && effectiveCategory.isNotEmpty && effectiveCategory != 'Tous') {
        queryParams['category'] = effectiveCategory;
      }

      if (condition != null && condition.isNotEmpty) queryParams['condition'] = condition;
      if (minValue != null) queryParams['minValue'] = minValue.toString();
      if (maxValue != null) queryParams['maxValue'] = maxValue.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$apiUrl/listings').replace(queryParameters: queryParams);
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final listingsData = (data['listings'] as List?) ?? [];
        listings.value = listingsData.map((l) => ListingModel.fromJson(l)).toList();
      } else {
        errorMessage.value = 'Échec du chargement des annonces';
      }
    } catch (e) {
      errorMessage.value = 'Erreur réseau: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Story B5 - Changer de ville
  void changeCity(String cityName) {
    selectedCity.value = cityName;
    final found = cities.firstWhereOrNull((c) => c.name == cityName);
    if (found != null) {
      selectedCityId.value = found.id;
    }
    fetchListings(cityId: selectedCityId.value);
  }

  void filterByCity(String cityName) => changeCity(cityName);

  /// Filtrer par catégorie
  void filterByCategory(String cat) {
    selectedCategory.value = cat;
    fetchListings(
      cityId: selectedCityId.value,
      category: (cat.isEmpty || cat == 'Tous') ? null : cat,
    );
  }

  /// Recherche par mot clé
  Future<void> searchListings(String keyword) async {
    await fetchListings(
      cityId: selectedCityId.value,
      search: keyword.trim().isEmpty ? null : keyword.trim(),
    );
  }

  /// Story B1 & B2 - Publier une annonce
  Future<bool> createListing({
    required String title,
    required String description,
    required String category,
    required String condition,
    required double estimatedValue,
    required int cityId,
    List<String> photos = const [],
    Map<String, dynamic> attributes = const {},
  }) async {
    isLoading.value = true;

    try {
      final headers = _getAuthHeaders();
      final response = await client.post(
        Uri.parse('$apiUrl/listings'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'condition': condition,
          'estimatedValue': estimatedValue,
          'cityId': cityId,
          'photos': photos,
          'attributes': attributes,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar(
          'Succès',
          'Votre annonce a été publiée avec succès !',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchListings();
        return true;
      } else if (response.statusCode == 409) {
        final err = jsonDecode(response.body);
        Get.snackbar(
          'Annonce existante (Règle B2)',
          err['message'] ?? 'Vous avez déjà une annonce identique active.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return false;
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar(
          'Erreur',
          err['message'] ?? 'Impossible de publier l\'annonce',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Erreur réseau',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Story B3 - Récupérer mes propres annonces avec filtre de statut
  Future<void> fetchMyListings({String? status}) async {
    isMyListingsLoading.value = true;
    try {
      final headers = _getAuthHeaders();
      var url = '$apiUrl/listings/user/my-listings';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      final response = await client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        myListings.value = data.map((l) => ListingModel.fromJson(l)).toList();
      } else {
        myListings.clear();
      }
    } catch (e) {
      debugPrint('Error fetchMyListings: $e');
    } finally {
      isMyListingsLoading.value = false;
    }
  }

  /// Story B3 - Changer le statut d'une annonce (archiver / réactiver)
  Future<bool> changeListingStatus(String listingId, String newStatus) async {
    try {
      final headers = _getAuthHeaders();
      final response = await client.patch(
        Uri.parse('$apiUrl/listings/$listingId/status'),
        headers: headers,
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Succès', 'Statut de l\'annonce mis à jour ($newStatus)');
        await fetchMyListings();
        await fetchListings();
        return true;
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar('Erreur', err['message'] ?? 'Action impossible');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', e.toString());
      return false;
    }
  }

  /// Story B3 - Supprimer une annonce
  Future<bool> deleteListing(String listingId) async {
    try {
      final headers = _getAuthHeaders();
      final response = await client.delete(
        Uri.parse('$apiUrl/listings/$listingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        Get.snackbar('Succès', 'Annonce supprimée avec succès');
        await fetchMyListings();
        await fetchListings();
        return true;
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar('Erreur', err['message'] ?? 'Suppression impossible');
        return false;
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', e.toString());
      return false;
    }
  }

  /// Méthode helper appelée depuis create_listing_screen.dart
  Future<bool> publishListingEnhanced({
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
    int cityId = 1;
    final found = cities.firstWhereOrNull((c) => c.name == city);
    if (found != null) {
      cityId = found.id;
    }

    final combinedAttributes = Map<String, dynamic>.from(attributes);
    if (wishes.isNotEmpty) {
      combinedAttributes['wishes'] = wishes;
    }

    return await createListing(
      title: title,
      description: description,
      category: category,
      condition: condition,
      estimatedValue: estimatedValue,
      cityId: cityId,
      photos: photos,
      attributes: combinedAttributes,
    );
  }
}
