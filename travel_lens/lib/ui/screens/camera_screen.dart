import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';
import 'package:travel_lens/ui/screens/image_processing_screen.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    if (controller != null) {
      controller!.dispose();
      controller = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      if (controller == null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    try {
      // Dispose existing controller if any
      _disposeController();

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

      if (!mounted) return;

      cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found')),
          );
        }
        return;
      }

      if (!mounted) return;

      controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller!.initialize();

      if (mounted && controller != null && controller!.value.isInitialized) {
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
    if (!_isCameraInitialized || _isCapturing || !mounted || controller == null)
      return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      setState(() {
        _isCapturing = true;
      });

      // Take picture
      final image = await controller!.takePicture();

      if (!mounted) return;

      // Show image preview and processing view, then pop when done
      await _showImagePreviewAndProcess(File(image.path), authProvider);
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
    if (!mounted) return;

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

      // Show image preview and processing view, then pop when done
      await _showImagePreviewAndProcess(File(pickedFile.path), authProvider);
    } catch (e) {
      debugPrint('Error picking image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  // Show image preview and processing view, then pop when done
  Future<void> _showImagePreviewAndProcess(
      File imageFile, AuthProvider authProvider) async {
    if (!mounted) return;

    // Navigate to image preview and processing screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageProcessingScreen(
          imageFile: imageFile,
          authProvider: authProvider,
        ),
      ),
    );

    // After processing is complete and user returns, pop the camera screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildCameraPreview() {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    try {
      return CameraPreview(controller!);
    } catch (e) {
      debugPrint('Error building camera preview: $e');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Camera preview error'),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
      ),
      body: _isCameraInitialized && controller != null
          ? Stack(
              children: [
                // Camera preview
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: _buildCameraPreview(),
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
