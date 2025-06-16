import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/services/storage_service.dart';
import 'package:travel_lens/data/models/detection_result.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';

class HistoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  List<DetectionResult> _historyItems = [];
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false;

  // Getters
  List<DetectionResult> get historyItems => _historyItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasInitialized => _hasInitialized;

  HistoryProvider({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  /// Initialize provider without triggering notifications during build
  void initialize() {
    if (_hasInitialized) return;

    _hasInitialized = true;
    debugPrint('=== HistoryProvider Initialized ===');
    debugPrint('Current user: moyeenhaider1');
    debugPrint('Current time: 2025-06-15 08:03:56 UTC');
    debugPrint('Storage provider: ${_storageService.providerName}');
    debugPrint('==================================');
  }

  Future<void> fetchUserHistory(AuthProvider authProvider) async {
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _error = 'User not authenticated';
        notifyListeners();
      });
      return;
    }

    await fetchHistory(authProvider.user!.uid);
  }

  Future<void> fetchHistory(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _historyItems = snapshot.docs
          .map((doc) => DetectionResult.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _error = 'Error fetching history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveResult(
      DetectionResult result, AuthProvider authProvider) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Only save if user is authenticated
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        throw AppException('User not authenticated');
      }

      final userId = authProvider.user!.uid;
      String? imageUrl;

      debugPrint('=== Saving Result ===');
      debugPrint('Current user: moyeenhaider1');
      debugPrint('Target user: $userId');
      debugPrint('Time: 2025-06-15 08:03:56 UTC');
      debugPrint('Storage provider: ${_storageService.providerName}');
      debugPrint('Provider info: ${StorageService.getProviderInfo()}');

      // Upload image using the current storage provider
      final file = File(result.imagePath);
      if (await file.exists()) {
        debugPrint('Uploading image with ${_storageService.providerName}...');
        imageUrl = await _storageService.uploadImage(file, userId);
        debugPrint('Image uploaded successfully: $imageUrl');
      } else {
        debugPrint(
            'Warning: Local image file does not exist: ${result.imagePath}');
      }

      // Create updated result with storage URL
      final updatedResult = result.copyWith(
        userId: userId,
        imagePath: imageUrl,
        timestamp: DateTime.now().toUtc(),
      );

      // Save to Firestore
      await _firestore
          .collection('history')
          .doc(updatedResult.id)
          .set(updatedResult.toMap());

      // Use post frame callback to update UI state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Update local list
        _historyItems = [updatedResult, ..._historyItems];
        _isLoading = false;
        _error = null;
        notifyListeners();

        debugPrint('Result saved successfully at 2025-06-15 08:03:56 UTC');
        debugPrint('Storage provider: ${_storageService.providerName}');
        debugPrint('==================');
      });
    } catch (e) {
      debugPrint('Save result error at 2025-06-15 08:03:56 UTC: $e');

      // Use post frame callback to update error state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _error = 'Error saving result: $e';
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> deleteHistoryItem(String itemId) async {
    try {
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = true;
        notifyListeners();
      });

      // Find the item
      final itemIndex = _historyItems.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        throw AppException('Item not found: $itemId');
      }

      final item = _historyItems[itemIndex];

      debugPrint('=== Deleting Item ===');
      debugPrint('Current user: moyeenhaider1');
      debugPrint('Item ID: $itemId');
      debugPrint('Time: 2025-06-15 08:03:56 UTC');
      debugPrint('Storage provider: ${_storageService.providerName}');

      // Delete image from storage if exists
      if (item.imagePath.isNotEmpty) {
        try {
          debugPrint('Deleting image with ${_storageService.providerName}...');
          await _storageService.deleteImage(item.imagePath);
          debugPrint('Image deleted successfully');
        } catch (e) {
          debugPrint('Warning: Could not delete image ${item.imagePath}: $e');
          // Continue with Firestore deletion even if image deletion fails
        }
      }

      // Delete from Firestore
      await _firestore.collection('history').doc(itemId).delete();

      // Use post frame callback to update UI state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Remove from local list
        _historyItems.removeWhere((item) => item.id == itemId);
        _isLoading = false;
        _error = null;
        notifyListeners();

        debugPrint('Item deleted successfully at 2025-06-15 08:03:56 UTC');
        debugPrint('Storage provider: ${_storageService.providerName}');
        debugPrint('==================');
      });
    } catch (e) {
      debugPrint('Delete item error at 2025-06-15 08:03:56 UTC: $e');

      // Use post frame callback to update error state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _error = 'Error deleting item: $e';
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> clearHistory(String userId) async {
    try {
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = true;
        notifyListeners();
      });

      debugPrint('=== Clearing History ===');
      debugPrint('Current user: moyeenhaider1');
      debugPrint('Target user: $userId');
      debugPrint('Time: 2025-06-15 08:03:56 UTC');
      debugPrint('Storage provider: ${_storageService.providerName}');

      // Get all items for this user
      final snapshot = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('Found ${snapshot.docs.length} items to delete');

      // Delete images from storage (do this in parallel for better performance)
      final deleteTasks = <Future>[];
      for (var doc in snapshot.docs) {
        try {
          final item = DetectionResult.fromMap(doc.data());
          if (item.imagePath.isNotEmpty) {
            deleteTasks.add(
                _storageService.deleteImage(item.imagePath).catchError((e) {
              debugPrint('Failed to delete image ${item.imagePath}: $e');
              return; // Continue even if individual deletions fail
            }));
          }
        } catch (e) {
          debugPrint('Error parsing item for deletion ${doc.id}: $e');
        }
      }

      // Wait for all image deletions to complete
      if (deleteTasks.isNotEmpty) {
        await Future.wait(deleteTasks);
        debugPrint('Completed image deletion tasks');
      }

      // Delete all documents in a batch
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Use post frame callback to update UI state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clear local list
        _historyItems = [];
        _isLoading = false;
        _error = null;
        notifyListeners();

        debugPrint('History cleared successfully at 2025-06-15 08:03:56 UTC');
        debugPrint('Storage provider: ${_storageService.providerName}');
        debugPrint('=======================');
      });
    } catch (e) {
      debugPrint('Clear history error at 2025-06-15 08:03:56 UTC: $e');

      // Use post frame callback to update error state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _error = 'Error clearing history: $e';
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  /// Clear error state
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Refresh history data
  Future<void> refresh(AuthProvider authProvider) async {
    debugPrint(
        'Refreshing history for moyeenhaider1 at 2025-06-15 08:03:56 UTC');

    if (authProvider.isAuthenticated && authProvider.user != null) {
      await fetchHistory(authProvider.user!.uid);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _historyItems = [];
        _error = 'Please sign in to view history';
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(String resultId) async {
    try {
      final index = _historyItems.indexWhere((item) => item.id == resultId);
      if (index == -1) return;

      final oldResult = _historyItems[index];
      final newResult = oldResult.copyWith(isFavorite: !oldResult.isFavorite);

      // Update Firestore
      await _firestore
          .collection('history')
          .doc(resultId)
          .update({'isFavorite': newResult.isFavorite});

      // Update local list
      _historyItems[index] = newResult;
      notifyListeners();
    } catch (e) {
      _error = 'Error toggling favorite: $e';
      notifyListeners();
    }
  }
}
