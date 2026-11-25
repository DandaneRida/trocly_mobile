import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart';
import 'dart:convert';
import '../core/constants/api_constants.dart';

String get apiUrl => ApiConstants.baseUrl;

/// Image model for preview
class ImagePreview {
  final File file;
  final String name;
  bool isUploading;

  ImagePreview({
    required this.file,
    required this.name,
    this.isUploading = false,
  });
}

/// Enhanced listings controller with image upload
class ListingsUploadController extends GetxController {
  var selectedImages = <ImagePreview>[].obs;
  var isCreatingListing = false.obs;
  var uploadProgress = 0.0.obs;
  var uploadingImageCount = 0.obs;
  var errorMessage = ''.obs;

  final ImagePicker imagePicker = ImagePicker();

  /// Pick images from gallery (multiple)
  Future<void> pickImagesFromGallery() async {
    try {
      final pickedFiles = await imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        // Max 10 images per listing
        if (selectedImages.length + pickedFiles.length > 10) {
          Get.snackbar(
            'Limit Reached',
            'Maximum 10 images per listing',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        for (final pickedFile in pickedFiles) {
          final file = File(pickedFile.path);
          final fileName = file.path.split('/').last;
          selectedImages.add(
            ImagePreview(file: file, name: fileName),
          );
        }

        Get.snackbar(
          'Success',
          'Added ${pickedFiles.length} image(s)',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images: $e');
    }
  }

  /// Capture image from camera
  Future<void> captureImageFromCamera() async {
    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        if (selectedImages.length >= 10) {
          Get.snackbar(
            'Limit Reached',
            'Maximum 10 images per listing',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        final file = File(pickedFile.path);
        final fileName = file.path.split('/').last;
        selectedImages.add(
          ImagePreview(file: file, name: fileName),
        );

        Get.snackbar('Success', 'Image captured');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image: $e');
    }
  }

  /// Remove image from selection
  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  /// Upload all selected images for a listing
  Future<List<String>> uploadListingImages(
    String listingId,
    String authToken,
  ) async {
    if (selectedImages.isEmpty) return [];

    final uploadedUrls = <String>[];

    try {
      for (int i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        image.isUploading = true;
        uploadingImageCount.value = i + 1;

        try {
          // Create multipart request
          final request = MultipartRequest(
            'POST',
            Uri.parse('$apiUrl/upload/listing/$listingId'),
          );

          request.headers['Authorization'] = 'Bearer $authToken';
          request.files.add(
            await MultipartFile.fromPath('images', image.file.path),
          );

          final response = await request.send();
          final responseBody = await response.stream.bytesToString();

          if (response.statusCode == 201 || response.statusCode == 200) {
            final data = jsonDecode(responseBody);
            if (data['data']['urls'] != null) {
              uploadedUrls.addAll(List<String>.from(data['data']['urls']));
            }
          } else {
            throw Exception('Upload failed: ${response.statusCode}');
          }
        } catch (e) {
          Get.snackbar('Upload Error', 'Failed to upload image ${i + 1}: $e');
        } finally {
          image.isUploading = false;
        }
      }

      uploadProgress.value = 0;
      uploadingImageCount.value = 0;
      return uploadedUrls;
    } catch (e) {
      errorMessage.value = 'Image upload failed: $e';
      Get.snackbar('Error', errorMessage.value);
      return uploadedUrls;
    }
  }

  /// Clear all selected images
  void clearImages() {
    selectedImages.clear();
  }
}

// ============================================================================
// UI: ENHANCED PUBLISH LISTING SCREEN WITH IMAGE UPLOAD
// ============================================================================

class PublishListingScreenEnhanced extends StatefulWidget {
  const PublishListingScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<PublishListingScreenEnhanced> createState() =>
      _PublishListingScreenEnhancedState();
}

class _PublishListingScreenEnhancedState
    extends State<PublishListingScreenEnhanced> {
  final ListingsUploadController uploadController = Get.put(ListingsUploadController());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Listing'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== PRODUCT IMAGES SECTION =====
            const Text(
              'Product Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Image count
                    Text(
                      '${uploadController.selectedImages.length}/10 images selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image grid preview
                    if (uploadController.selectedImages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: uploadController.selectedImages.length,
                        itemBuilder: (context, index) {
                          final image = uploadController.selectedImages[index];
                          return Stack(
                            children: [
                              // Image preview
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(image.file),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // Uploading indicator
                              if (image.isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.black54,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Delete button
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () =>
                                      uploadController.removeImage(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: 16),

                    // Add image buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                uploadController.selectedImages.length >= 10
                                    ? null
                                    : uploadController.captureImageFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                uploadController.selectedImages.length >= 10
                                    ? null
                                    : uploadController.pickImagesFromGallery,
                            icon: const Icon(Icons.image),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Help text
                    const SizedBox(height: 8),
                    const Text(
                      'Add at least 1 image. Max 10 images, optimized to 1200x1200px',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===== LISTING DETAILS FORM =====
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Product Title *',
                hintText: 'e.g., iPhone 14 Pro Max',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the condition and any defects...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedCategory,
              onChanged: (newVal) =>
                  setState(() => selectedCategory = newVal ?? 'Electronics'),
              items: [
                'Electronics',
                'Furniture',
                'Sports',
                'Clothing',
                'Books',
                'Home & Garden',
                'Toys',
                'Other',
              ]
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedCondition,
              onChanged: (newVal) =>
                  setState(() => selectedCondition = newVal ?? 'Good'),
              items: ['Like New', 'Good', 'Fair', 'Poor']
                  .map((cond) => DropdownMenuItem(value: cond, child: Text(cond)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Condition *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: estimatedValueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimated Value (MAD) *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedCity,
              onChanged: (newVal) =>
                  setState(() => selectedCity = newVal ?? 'Meknès'),
              items: ['Meknès', 'Fès', 'Rabat', 'Casablanca', 'Marrakech']
                  .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'City *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 24),

            // ===== PUBLISH BUTTON =====
            Obx(
              () => ElevatedButton(
                onPressed: uploadController.isCreatingListing.value ||
                        uploadController.selectedImages.isEmpty
                    ? null
                    : () async {
                        // Validate required fields
                        if (titleController.text.isEmpty ||
                            estimatedValueController.text.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please fill all required fields',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        uploadController.isCreatingListing.value = true;

                        try {
                          // TODO: Replace with actual API call
                          // 1. Create listing first
                          // 2. Upload images to /upload/listing/:listingId
                          // 3. Update listing with image URLs

                          Get.snackbar(
                            'Success',
                            'Listing published with ${uploadController.selectedImages.length} image(s)',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );

                          // Clear and go back
                          uploadController.clearImages();
                          titleController.clear();
                          descriptionController.clear();
                          estimatedValueController.clear();
                          Get.back();
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Failed to publish: $e',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } finally {
                          uploadController.isCreatingListing.value = false;
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: uploadController.isCreatingListing.value
                      ? Colors.grey
                      : Colors.green,
                ),
                child: uploadController.isCreatingListing.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Publish Listing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              '* Required fields',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
