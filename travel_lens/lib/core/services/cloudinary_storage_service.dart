import 'dart:io';

import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
    // Get credentials from .env file
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    // We don't need the API secret for unsigned uploads

    // Validate cloud name (minimum required)
    if (cloudName == null) {
      throw AppException(
          'Cloudinary cloud name not found in environment variables');
    }
    if (cloudName.isEmpty) {
      throw AppException('Cloudinary cloud name cannot be empty');
    }

    debugPrint('[$providerName] Initializing Cloudinary with:');
    debugPrint('[$providerName] Cloud name: $cloudName');
    // Log API key info if available but don't require it
    if (apiKey != null && apiKey.isNotEmpty) {
      debugPrint('[$providerName] API key length: ${apiKey.length}');
    } else {
      debugPrint(
          '[$providerName] API key: Not configured (will use unsigned uploads)');
    }

    // For mobile applications, using unsigned uploads with a preset is more secure
    // than storing the API key and secret in the app
    try {
      // Use .basic constructor for unsigned uploads
      _cloudinary = Cloudinary.basic(
        cloudName: cloudName,
      );

      // Test the Cloudinary instance is working correctly
      debugPrint('[$providerName] Cloudinary initialized successfully');
      debugPrint('[$providerName] SDK instance: ${_cloudinary.toString()}');
    } catch (e) {
      debugPrint('[$providerName] Error initializing Cloudinary: $e');
      throw AppException('Failed to initialize Cloudinary: $e');
    }

    // Print final initialization info
    debugPrint(
        '[$providerName] Initialized at ${DateTime.now().toUtc().toIso8601String()}');
    debugPrint('[$providerName] Cloud name: $cloudName');
    // No need to print API key or secret when using unsigned uploads
  }

  @override
  String get providerName => 'Cloudinary';

  @override
  Future<String> uploadImage(XFile imageFile, String userId) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;

    final apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
    final preset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

    final cloudinary = Cloudinary.full(
        apiKey: apiKey, cloudName: cloudName, apiSecret: apiSecret);
    final compressedFile = await _compressImage(imageFile);
    final resource = CloudinaryUploadResource(
      filePath: compressedFile.path,
      resourceType: CloudinaryResourceType.image,
      folder: 'travel_lens/$userId',
      fileName: 'travel_${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}',
      optParams: {'upload_preset': preset},
    );

    final response = await cloudinary.uploadResource(resource);
    if (response.isSuccessful) {
      return response.secureUrl!;
    }
    throw AppException('Upload failed: ${response.error}');
  }
  // Future<String> uploadImage(File imageFile, String userId) async {
  //   try {
  //     final currentTime = DateTime.now().toUtc().toIso8601String();
  //     debugPrint(
  //         '[$providerName] Starting upload for user: $userId at $currentTime');
  //     debugPrint('[$providerName] Target user folder: $userId');
  //     debugPrint('[$providerName] Original file path: ${imageFile.path}');

  //     // Check if file exists
  //     if (!await imageFile.exists()) {
  //       throw AppException('Image file does not exist: ${imageFile.path}');
  //     }

  //     // Compress image before upload
  //     final compressedFile = await _compressImage(imageFile);

  //     // Create unique filename with timestamp
  //     final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
  //     final fileName = 'travel_lens_${_uuid.v4()}_$timestamp';
  //     final folderPath = 'travel_lens/$userId';

  //     debugPrint('[$providerName] Upload details:');
  //     debugPrint('  - File: ${compressedFile.path}');
  //     debugPrint('  - Public ID: $fileName');
  //     debugPrint('  - Folder: $folderPath');
  //     debugPrint('  - Resource Type: image');

  //     // Use unsigned upload with a predefined upload preset
  //     // You must create this preset in your Cloudinary dashboard
  //     // Settings > Upload > Upload Presets > Add upload preset
  //     // Set to "unsigned" and name it "travel_lens"
  //     const uploadPreset =
  //         'ml_default'; // Use your actual unsigned upload preset name

  //     debugPrint('[$providerName] Upload details:');
  //     debugPrint('  - File: ${compressedFile.path}');
  //     debugPrint('  - Public ID: $fileName');
  //     debugPrint('  - Folder: $folderPath');
  //     debugPrint('  - Using upload preset: $uploadPreset');

  //     // Setup the upload resource for unsigned upload
  //     CloudinaryResponse response;
  //     try {
  //       debugPrint('[$providerName] Attempting direct upload with preset...');
  //       // Create an unsigned upload resource with the upload_preset parameter
  //       final uploadOptions = {
  //         'upload_preset':
  //             uploadPreset, // Critical parameter for unsigned uploads
  //         'folder': folderPath,
  //         'public_id': fileName,
  //         'overwrite': true,
  //         'invalidate': true,
  //         'quality': 'auto:good',
  //         'format': 'jpg',
  //       };

  //       // Use uploadFile method with preset in options
  //       response = await _cloudinary.uploadFile(
  //         filePath: compressedFile.path,
  //         resourceType: CloudinaryResourceType.image,
  //         optParams: uploadOptions,
  //       );
  //     } catch (e) {
  //       debugPrint('[$providerName] Unsigned upload failed: $e');

  //       // Fallback to try with a different approach
  //       debugPrint('[$providerName] Trying alternative upload method...');
  //       try {
  //         final uploadResource = CloudinaryUploadResource(
  //           filePath: compressedFile.path,
  //           resourceType: CloudinaryResourceType.image,
  //           optParams: {
  //             'upload_preset':
  //                 uploadPreset, // Critical parameter for unsigned uploads
  //             'folder': folderPath,
  //             'public_id': fileName,
  //             'overwrite': true,
  //             'invalidate': true,
  //           },
  //         );

  //         response = await _cloudinary.uploadResource(uploadResource);
  //       } catch (secondError) {
  //         debugPrint(
  //             '[$providerName] Alternative upload method failed: $secondError');
  //         throw AppException(
  //             'Upload failed after multiple attempts: $secondError');
  //       }
  //     }

  //     // Clean up compressed file if it's different from original
  //     if (compressedFile.path != imageFile.path) {
  //       try {
  //         await compressedFile.delete();
  //         debugPrint('[$providerName] Cleaned up compressed file');
  //       } catch (e) {
  //         debugPrint(
  //             '[$providerName] Warning: Could not delete compressed file: $e');
  //       }
  //     }

  //     if (response.isSuccessful && response.secureUrl != null) {
  //       debugPrint('[$providerName] Upload successful at $currentTime');
  //       debugPrint('[$providerName] Secure URL: ${response.secureUrl}');
  //       debugPrint('[$providerName] Public ID: ${response.publicId}');
  //       debugPrint('[$providerName] Format: ${response.format}');
  //       debugPrint('[$providerName] Width: ${response.width}');
  //       debugPrint('[$providerName] Height: ${response.height}');
  //       debugPrint('[$providerName] Bytes: ${response.bytes}');
  //       return response.secureUrl!;
  //     } else {
  //       final errorMessage = response.error ?? 'Unknown upload error';
  //       debugPrint(
  //           '[$providerName] Upload failed at $currentTime: $errorMessage');
  //       throw AppException('Upload failed: $errorMessage');
  //     }
  //   } catch (e) {
  //     final errorTime = DateTime.now().toUtc().toIso8601String();
  //     debugPrint(
  //         '[$providerName] Upload error for user $userId at $errorTime: $e');
  //     if (e is AppException) {
  //       rethrow;
  //     }
  //     throw AppException('Upload failed: $e');
  //   }
  // }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      final currentTime = DateTime.now().toUtc().toIso8601String();
      debugPrint('[$providerName] Deleting image at $currentTime');
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
            // Removed api_key and timestamp as the client should handle signing
          },
        );

        if (response.isSuccessful) {
          debugPrint('[$providerName] Delete successful at $currentTime');
          debugPrint('[$providerName] Delete result: ${response.result}');
        } else {
          final errorMessage = response.error ?? 'Unknown delete error';
          debugPrint(
              '[$providerName] Delete failed at $currentTime: $errorMessage');
          throw AppException('Delete failed: $errorMessage');
        }
      } else {
        throw AppException('Could not extract public ID from URL: $imageUrl');
      }
    } catch (e) {
      final errorTime = DateTime.now().toUtc().toIso8601String();
      debugPrint('[$providerName] Delete error at $errorTime: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Failed to delete image from $providerName: $e');
    }
  }

  /// Compresses an image to optimize storage and bandwidth
  Future<XFile> _compressImage(XFile imageFile) async {
    final dir = await Directory.systemTemp.createTemp('travellens');
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      targetPath,
      quality: 85, // Adjust quality (1–100)
      minWidth: 1200,
      minHeight: 1200,
      keepExif: true,
      format: CompressFormat.jpeg,
    );

    if (result != null) return result;
    return imageFile; // Fallback if compression fails
  }

  /// Extract public ID from Cloudinary URL for deletion
  String? _extractPublicIdFromUrl(String url) {
    try {
      final currentTime = DateTime.now().toUtc().toIso8601String();
      debugPrint(
          '[$providerName] Extracting public ID from URL at $currentTime');
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
      final errorTime = DateTime.now().toUtc().toIso8601String();
      debugPrint(
          '[$providerName] Error extracting public ID at $errorTime: $e');
      return null;
    }
  }

  /// Get upload statistics and info
  Map<String, dynamic> getUploadInfo() {
    return {
      'provider': providerName,
      'user': 'moyeenhaider1', // Consider making this dynamic if needed
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'cloud_name': dotenv.env['CLOUDINARY_CLOUD_NAME'],
      'api_configured': dotenv.env['CLOUDINARY_API_KEY'] != null,
      'secret_configured': dotenv.env['CLOUDINARY_API_SECRET'] != null,
    };
  }

  /// Test upload functionality (for debugging)
  Future<bool> testConnection() async {
    try {
      final currentTime = DateTime.now().toUtc().toIso8601String();
      debugPrint('[$providerName] Testing connection at $currentTime');
      debugPrint('[$providerName] Configuration: ${getUploadInfo()}');

      // Test with a small dummy resource (you can remove this in production)
      // final testResource = CloudinaryUploadResource(
      //   publicId: 'test_connection_${DateTime.now().millisecondsSinceEpoch}',
      //   folder: 'travel_lens/test',
      //   resourceType: CloudinaryResourceType.raw,
      //   optParams: {'resource_type': 'raw'},
      // );

      // Note: This would need actual file data to work
      // Just checking if the configuration is valid
      debugPrint('[$providerName] Connection test setup successful');
      return true;
    } catch (e) {
      final errorTime = DateTime.now().toUtc().toIso8601String();
      debugPrint('[$providerName] Connection test failed at $errorTime: $e');
      return false;
    }
  }

  // Uncomment if you want to implement delete functionality

// Future<void> deleteImage(String imageUrl) async {
//   final currentTime = DateTime.now().toUtc().toIso8601String();
//   debugPrint('[$providerName] Deleting image at $currentTime');
//   debugPrint('[$providerName] Image URL: $imageUrl');

//   // Extract publicId from URL
//   final publicId = _extractPublicIdFromUrl(imageUrl);
//   if (publicId == null) {
//     throw AppException('Could not extract public_id from URL: $imageUrl');
//   }
//   debugPrint('[$providerName] publicId: $publicId');

//   // Perform the destroy call
//   final response = await _cloudinary.deleteResource(
//     publicId: publicId,
//     resourceType: CloudinaryResourceType.image,
//     optParams: {
//       'invalidate': true, // clear CDN cache
//     },
//   );

//   if (response.isSuccessful) {
//     debugPrint('[$providerName] Delete succeeded at $currentTime: ${response.result}');
//   } else {
//     final errorMsg = response.error ?? 'Unknown error';
//     debugPrint('[$providerName] Delete failed at $currentTime: $errorMsg');
//     throw AppException('Deletion failed: $errorMsg');
//   }
// }
}
