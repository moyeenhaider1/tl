import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/core/services/location_service.dart';
import 'package:travel_lens/data/models/detection_result.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';
import 'package:travel_lens/data/providers/detection_provider.dart';
import 'package:travel_lens/data/providers/history_provider.dart';
import 'package:travel_lens/ui/screens/auth/login_screen.dart';

class ImageProcessingScreen extends StatefulWidget {
  final File imageFile;
  final AuthProvider authProvider;

  const ImageProcessingScreen({
    super.key,
    required this.imageFile,
    required this.authProvider,
  });

  @override
  State<ImageProcessingScreen> createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen> {
  final LocationService _locationService = LocationService();
  bool _isProcessing = true;
  String _processingStatus = 'Processing image...';
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    // Start processing after a brief preview
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showPreview = false;
        });
        _processImage();
      }
    });
  }

  Future<void> _processImage() async {
    if (!mounted) return;

    try {
      setState(() {
        _processingStatus = 'Analyzing image...';
      });

      // Process with detection provider
      final detectionProvider =
          Provider.of<DetectionProvider>(context, listen: false);
      await detectionProvider.processImage(widget.imageFile);

      if (!mounted) return;

      setState(() {
        _processingStatus = 'Getting location...';
      });

      // Get location if permission granted
      double? latitude;
      double? longitude;
      String? placeName;

      try {
        final position = await _locationService.getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
        placeName =
            await _locationService.getPlaceFromCoordinates(latitude, longitude);
        debugPrint('Location detected: $placeName ($latitude, $longitude)');
      } catch (e) {
        debugPrint('Could not get location: $e');
        // Continue without location
      }

      if (!mounted) return;

      setState(() {
        _processingStatus = 'Saving results...';
      });

      // Save to history if authenticated
      if (widget.authProvider.isAuthenticated) {
        if (!mounted) return;

        final historyProvider =
            Provider.of<HistoryProvider>(context, listen: false);

        final result = DetectionResult.create(
          userId: widget.authProvider.user?.uid,
          image: widget.imageFile,
        ).copyWith(
          detectedObject: detectionProvider.detectedObject,
          extractedText: detectionProvider.extractedText,
          translatedText: detectionProvider.translatedText,
          summary: detectionProvider.summary,
        );

        // Handle any errors during saving without crashing
        try {
          await historyProvider.saveResult(result, widget.authProvider);
        } catch (e) {
          debugPrint('Error saving result to history: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save to history: $e')),
            );
          }
        }
      } else {
        // Show login prompt for guest users
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign in to Save'),
              content: const Text(
                'This result will not be saved to your history. Sign in to save your discoveries.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Sign In'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          );
        }
      }

      // Processing complete
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = 'Complete!';
        });

        // Wait a moment to show completion, then navigate back
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = 'Error processing image';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );

        // Wait a moment then navigate back
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _showPreview ? _buildImagePreview() : _buildProcessingView(),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Preview text
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Great shot! Processing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Processing animation
          if (_isProcessing)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          else
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
          const SizedBox(height: 24),
          // Status text
          Text(
            _processingStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Processing steps
          if (_isProcessing)
            const Text(
              'This may take a few moments...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}
