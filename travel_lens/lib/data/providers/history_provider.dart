import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:travel_lens/data/models/detection_result.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';

class HistoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DetectionResult> _historyItems = [];
  bool _isLoading = false;
  String? _error;

  List<DetectionResult> get historyItems => _historyItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user's history
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

  // Save detection result
  Future<void> saveResult(
      DetectionResult result, AuthProvider authProvider) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Only save if user is authenticated
      if (authProvider.isAuthenticated && authProvider.user != null) {
        final resultWithUserId =
            result.copyWith(userId: authProvider.user!.uid);

        // Save to Firestore
        await _firestore
            .collection('history')
            .doc(resultWithUserId.id)
            .set(resultWithUserId.toMap());

        // Update local list
        _historyItems = [resultWithUserId, ..._historyItems];
      }
    } catch (e) {
      _error = 'Error saving result: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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

  // Delete history item
  Future<void> deleteHistoryItem(String resultId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('history').doc(resultId).delete();

      // Remove from local list
      _historyItems.removeWhere((item) => item.id == resultId);
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting history item: $e';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Add this method to connect user ID with history items
  Future<void> fetchUserHistory(AuthProvider authProvider) async {
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    await fetchHistory(authProvider.user!.uid);
  }

// Also update the saveResult method to include the current user's ID
}
