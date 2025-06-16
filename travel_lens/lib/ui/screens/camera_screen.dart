import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/core/services/location_service.dart';
import 'package:travel_lens/data/models/detection_result.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';
import 'package:travel_lens/data/providers/detection_provider.dart';
import 'package:travel_lens/data/providers/history_provider.dart';
import 'package:travel_lens/ui/screens/auth/login_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker(); // Add this

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Check and request camera permissions
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found')),
          );
        }
        return;
      }

      controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isCapturing) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      setState(() {
        _isCapturing = true;
      });

      // Take picture
      final image = await controller!.takePicture();

      if (!mounted) return;

      // Process the captured image
      await _processImage(File(image.path), authProvider);
    } catch (e) {
      debugPrint('Error taking picture: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  // New method for picking image from gallery
  Future<void> _pickImageFromGallery() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Pick image
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        // User canceled selection
        return;
      }

      if (!mounted) return;

      // Process the selected image
      await _processImage(File(pickedFile.path), authProvider);
    } catch (e) {
      debugPrint('Error picking image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  // Common method to process images from both camera and gallery
  Future<void> _processImage(File imageFile, AuthProvider authProvider) async {
    setState(() {
      _isCapturing = true;
    });

    try {
      // Process with detection provider
      final detectionProvider =
          Provider.of<DetectionProvider>(context, listen: false);
      await detectionProvider.processImage(imageFile);

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
      } catch (e) {
        debugPrint('Could not get location: $e');
        // Continue without location
      }

      // Save to history if authenticated
      if (authProvider.isAuthenticated) {
        final historyProvider =
            Provider.of<HistoryProvider>(context, listen: false);

        final result = DetectionResult.create(
          userId: authProvider.user?.uid,
          image: imageFile,
        ).copyWith(
          detectedObject: detectionProvider.detectedObject,
          extractedText: detectionProvider.extractedText,
          translatedText: detectionProvider.translatedText,
          summary: detectionProvider.summary,
        );

        await historyProvider.saveResult(result, authProvider);
      } else {
        // Show login prompt for guest users
        if (mounted) {
          showDialog(
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

      // Navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error processing image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                // Camera preview
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: CameraPreview(controller!),
                ),

                // Capture buttons at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery button
                        FloatingActionButton(
                          heroTag: 'gallery',
                          onPressed:
                              _isCapturing ? null : _pickImageFromGallery,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          child: const Icon(Icons.photo_library),
                        ),

                        // Capture button
                        FloatingActionButton(
                          heroTag: 'camera',
                          onPressed: _isCapturing ? null : _takePicture,
                          backgroundColor: Colors.white,
                          child: _isCapturing
                              ? const CircularProgressIndicator()
                              : const Icon(Icons.camera_alt,
                                  color: Colors.black),
                        ),

                        // Flip camera button (placeholder for future feature)
                        FloatingActionButton(
                          heroTag: 'flip',
                          onPressed: () {
                            // TODO: Implement camera flip
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon!')),
                            );
                          },
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          child: const Icon(Icons.flip_camera_ios),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (_isCapturing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing camera...'),
                ],
              ),
            ),
    );
  }
}
