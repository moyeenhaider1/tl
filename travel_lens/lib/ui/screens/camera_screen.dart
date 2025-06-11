import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/data/models/detection_result.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';
import 'package:travel_lens/data/providers/detection_provider.dart';
import 'package:travel_lens/data/providers/history_provider.dart';
import 'package:travel_lens/ui/screens/auth/login_screen.dart';
import 'package:travel_lens/ui/widgets/processing_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

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
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        // Handle no cameras available
        return;
      }

      final camera = cameras.first;
      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      // Handle camera initialization errors
      debugPrint('Camera initialization error: $e');
    }
  }

  // In the _takePicture method, add authentication check:

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      final image = await controller!.takePicture();

      if (!mounted) return;

      final detectionProvider =
          Provider.of<DetectionProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await detectionProvider.processImage(File(image.path));

      // Check if user is authenticated
      if (!authProvider.isAuthenticated) {
        // If not authenticated, show a dialog after processing
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
      } else {
        // User is authenticated, save to history
        final historyProvider =
            Provider.of<HistoryProvider>(context, listen: false);

        final result = DetectionResult.create(
          userId: authProvider.user?.uid,
          image: File(image.path),
        ).copyWith(
          detectedObject: detectionProvider.detectedObject,
          extractedText: detectionProvider.extractedText,
          translatedText: detectionProvider.translatedText,
          summary: detectionProvider.summary,
        );

        await historyProvider.saveResult(result, authProvider);
      }

      // Always navigate back to results screen, whether logged in or not
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
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
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Camera preview
          CameraPreview(controller!),

          // Capture button
          Positioned(
            bottom: 50,
            child: GestureDetector(
              onTap: _takePicture,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Processing overlay
          if (_isCapturing)
            const ProcessingOverlay(message: 'Processing image...'),
        ],
      ),
    );
  }
}
