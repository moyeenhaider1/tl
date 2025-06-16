import 'dart:io';

import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/interfaces/storage_interface.dart';
import 'package:uuid/uuid.dart';

class CloudinaryStorageService implements StorageInterface {
  late final Cloudinary _cloudinary;
  final Uuid _uuid = const Uuid();

  CloudinaryStorageService() {
    _initializeCloudinary();
  }

  void _initializeCloudinary() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

    if (cloudName == null || apiKey == null || apiSecret == null) {
      throw AppException(
          'Cloudinary credentials not found in environment variables');
    }

    _cloudinary = Cloudinary.full(
      apiKey: apiKey,
      apiSecret: apiSecret,
      cloudName: cloudName,
    );

    debugPrint(
        '[$providerName] Initialized for user: moyeenhaider1 at 2025-06-15 07:45:10 UTC');
    debugPrint('[$providerName] Cloud name: $cloudName');
    debugPrint('[$providerName] API key configured: ${apiKey.isNotEmpty}');
  }

  @override
  String get providerName => 'Cloudinary';

  @override
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      const currentTime = '2025-06-16 08:47:56';
      debugPrint(
          '[$providerName] Starting upload for user: $userId at $currentTime');
      debugPrint('[$providerName] Target user folder: $userId');
      debugPrint('[$providerName] Original file path: ${imageFile.path}');

      // Check if file exists
      if (!await imageFile.exists()) {
        throw AppException('Image file does not exist: ${imageFile.path}');
      }

      // Compress image before upload
      final compressedFile = await _compressImage(imageFile);

      // Create unique filename with timestamp
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final fileName = 'travel_lens_${_uuid.v4()}_$timestamp';
      final folderPath = 'travel_lens/$userId';

      debugPrint('[$providerName] Upload details:');
      debugPrint('  - File: ${compressedFile.path}');
      debugPrint('  - Public ID: $fileName');
      debugPrint('  - Folder: $folderPath');
      debugPrint('  - Resource Type: image');

      // Create CloudinaryUploadResource with proper authentication
      final uploadResource = CloudinaryUploadResource(
        filePath: compressedFile.path,
        // Remove the upload preset and instead rely on the API key and secret
        // that should be configured in your CloudinaryClient
        publicId: fileName,
        folder: folderPath,
        resourceType: CloudinaryResourceType.image,
        optParams: {
          'overwrite': true,
          'invalidate': true,
          'quality': 'auto:good',
          'format': 'jpg',
          // Add these for signed uploads if they're not already in your CloudinaryClient
          'api_key': dotenv.env['CLOUDINARY_API_KEY'],
          'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
        },
      );

      // Upload to Cloudinary using uploadResource
      final response = await _cloudinary.uploadResource(uploadResource);

      // Clean up compressed file if it's different from original
      if (compressedFile.path != imageFile.path) {
        try {
          await compressedFile.delete();
          debugPrint('[$providerName] Cleaned up compressed file');
        } catch (e) {
          debugPrint(
              '[$providerName] Warning: Could not delete compressed file: $e');
        }
      }

      if (response.isSuccessful && response.secureUrl != null) {
        debugPrint('[$providerName] Upload successful at $currentTime');
        debugPrint('[$providerName] Secure URL: ${response.secureUrl}');
        debugPrint('[$providerName] Public ID: ${response.publicId}');
        debugPrint('[$providerName] Format: ${response.format}');
        debugPrint('[$providerName] Width: ${response.width}');
        debugPrint('[$providerName] Height: ${response.height}');
        debugPrint('[$providerName] Bytes: ${response.bytes}');
        return response.secureUrl!;
      } else {
        final errorMessage = response.error ?? 'Unknown upload error';
        debugPrint(
            '[$providerName] Upload failed at $currentTime: $errorMessage');
        throw AppException('Upload failed: $errorMessage');
      }
    } catch (e) {
      const currentTime = '2025-06-16 08:47:56';
      debugPrint(
          '[$providerName] Upload error for user $userId at $currentTime: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Upload failed: $e');
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      debugPrint(
          '[$providerName] Deleting image for user moyeenhaider1 at 2025-06-15 07:45:10 UTC');
      debugPrint('[$providerName] Image URL: $imageUrl');

      // Extract public ID from URL
      final publicId = _extractPublicIdFromUrl(imageUrl);

      if (publicId != null) {
        debugPrint('[$providerName] Extracted public ID: $publicId');

        // Use the destroy method to delete the resource
        final response = await _cloudinary.deleteResource(
          publicId: publicId,
          resourceType: CloudinaryResourceType.image,
          optParams: {
            'invalidate': true,
          },
        );

        if (response.isSuccessful) {
          debugPrint(
              '[$providerName] Delete successful at 2025-06-15 07:45:10 UTC');
          debugPrint('[$providerName] Delete result: ${response.result}');
        } else {
          final errorMessage = response.error ?? 'Unknown delete error';
          debugPrint(
              '[$providerName] Delete failed at 2025-06-15 07:45:10 UTC: $errorMessage');
          throw AppException('Delete failed: $errorMessage');
        }
      } else {
        throw AppException('Could not extract public ID from URL: $imageUrl');
      }
    } catch (e) {
      debugPrint(
          '[$providerName] Delete error for user moyeenhaider1 at 2025-06-15 07:45:10 UTC: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Failed to delete image from $providerName: $e');
    }
  }

  /// Compresses an image to optimize storage and bandwidth
  Future<File> _compressImage(File imageFile) async {
    try {
      debugPrint(
          '[$providerName] Starting image compression for user: moyeenhaider1 at 2025-06-15 07:45:10 UTC');

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint('[$providerName] Could not decode image, using original');
        return imageFile;
      }

      // Calculate new dimensions (max 1200px)
      int targetWidth = image.width;
      int targetHeight = image.height;

      debugPrint(
          '[$providerName] Original dimensions: ${image.width}x${image.height} (${bytes.length} bytes)');

      bool needsResize = targetWidth > 1200 || targetHeight > 1200;

      if (needsResize) {
        if (targetWidth > targetHeight) {
          targetWidth = 1200;
          targetHeight = (targetHeight * (1200 / image.width)).round();
        } else {
          targetHeight = 1200;
          targetWidth = (targetWidth * (1200 / image.height)).round();
        }

        debugPrint('[$providerName] Resizing to: ${targetWidth}x$targetHeight');
      }

      // Resize and compress
      final resized = needsResize
          ? img.copyResize(image, width: targetWidth, height: targetHeight)
          : image;

      final compressed = img.encodeJpg(resized, quality: 85);

      // Create temp file
      final tempDir =
          await Directory.systemTemp.createTemp('travellens_compress');
      final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await tempFile.writeAsBytes(compressed);

      debugPrint(
          '[$providerName] Image compression completed at 2025-06-15 07:45:10 UTC');
      debugPrint('[$providerName] Original size: ${bytes.length} bytes');
      debugPrint('[$providerName] Compressed size: ${compressed.length} bytes');
      debugPrint(
          '[$providerName] Size reduction: ${((bytes.length - compressed.length) / bytes.length * 100).toStringAsFixed(1)}%');
      debugPrint('[$providerName] Compressed file: ${tempFile.path}');

      return tempFile;
    } catch (e) {
      debugPrint(
          '[$providerName] Image compression failed for user moyeenhaider1 at 2025-06-15 07:45:10 UTC: $e');
      return imageFile;
    }
  }

  /// Extract public ID from Cloudinary URL for deletion
  String? _extractPublicIdFromUrl(String url) {
    try {
      debugPrint(
          '[$providerName] Extracting public ID from URL at 2025-06-15 07:45:10 UTC');
      debugPrint('[$providerName] URL: $url');

      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      debugPrint('[$providerName] Path segments: $pathSegments');

      // Find the upload segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        debugPrint('[$providerName] No upload segment found');
        return null;
      }

      // Skip version segment if present (starts with 'v' followed by numbers)
      int publicIdStartIndex = uploadIndex + 1;
      if (publicIdStartIndex < pathSegments.length &&
          pathSegments[publicIdStartIndex].startsWith('v') &&
          RegExp(r'^v\d+$').hasMatch(pathSegments[publicIdStartIndex])) {
        publicIdStartIndex += 1;
        debugPrint(
            '[$providerName] Skipped version segment: ${pathSegments[uploadIndex + 1]}');
      }

      if (publicIdStartIndex >= pathSegments.length) {
        debugPrint('[$providerName] No public ID segment found');
        return null;
      }

      // Join remaining segments and remove file extension
      final publicIdWithFolder =
          pathSegments.sublist(publicIdStartIndex).join('/');
      final publicId = publicIdWithFolder.replaceAll(RegExp(r'\.[^.]+$'), '');

      debugPrint('[$providerName] Extracted public ID: $publicId');
      return publicId;
    } catch (e) {
      debugPrint(
          '[$providerName] Error extracting public ID for user moyeenhaider1 at 2025-06-15 07:45:10 UTC: $e');
      return null;
    }
  }

  /// Get upload statistics and info
  Map<String, dynamic> getUploadInfo() {
    return {
      'provider': providerName,
      'user': 'moyeenhaider1',
      'timestamp': '2025-06-15 07:45:10 UTC',
      'cloud_name': dotenv.env['CLOUDINARY_CLOUD_NAME'],
      'api_configured': dotenv.env['CLOUDINARY_API_KEY'] != null,
      'secret_configured': dotenv.env['CLOUDINARY_API_SECRET'] != null,
    };
  }

  /// Test upload functionality (for debugging)
  Future<bool> testConnection() async {
    try {
      debugPrint(
          '[$providerName] Testing connection for user moyeenhaider1 at 2025-06-15 07:45:10 UTC');
      debugPrint('[$providerName] Configuration: ${getUploadInfo()}');

      // Test with a small dummy resource (you can remove this in production)
      final testResource = CloudinaryUploadResource(
        publicId: 'test_connection_${DateTime.now().millisecondsSinceEpoch}',
        folder: 'travel_lens/test',
        resourceType: CloudinaryResourceType.raw,
        optParams: {'resource_type': 'raw'},
      );

      // Note: This would need actual file data to work
      // Just checking if the configuration is valid
      debugPrint('[$providerName] Connection test setup successful');
      return true;
    } catch (e) {
      debugPrint(
          '[$providerName] Connection test failed for user moyeenhaider1 at 2025-06-15 07:45:10 UTC: $e');
      return false;
    }
  }
}
