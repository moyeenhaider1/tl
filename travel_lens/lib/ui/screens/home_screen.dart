import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';
import 'package:travel_lens/data/providers/detection_provider.dart';
import 'package:travel_lens/ui/screens/camera_screen.dart';
import 'package:travel_lens/ui/widgets/auth_status_widget.dart';
import 'package:travel_lens/ui/widgets/processing_view.dart';
import 'package:travel_lens/ui/widgets/result_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userDisplayName = authProvider.user?.displayName ??
        authProvider.user?.email?.split('@').first ??
        'Traveler';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelLens'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Hi, $userDisplayName',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, detectionProvider, _) {
          if (detectionProvider.capturedImage == null) {
            // Show welcome screen when no image
            return _buildWelcomeView(context);
          } else if (detectionProvider.isProcessing) {
            // Show processing screen during API calls
            return ProcessingView(
              provider: detectionProvider,
              onRetry: () => detectionProvider.retryProcessing(),
            );
          } else if (detectionProvider.status == ProcessingStatus.error) {
            // Show error state
            return ProcessingView(
              provider: detectionProvider,
              onRetry: () => detectionProvider.retryProcessing(),
            );
          } else {
            // Show results
            return _buildResultsView(context, detectionProvider);
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capture'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildWelcomeView(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Auth status widget at the top
              const AuthStatusWidget(),
              const SizedBox(height: 24),

              const Icon(
                Icons.travel_explore,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to TravelLens',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Point your camera at landmarks, signs, or menus to get instant information in your language.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              // Removed the duplicate "Start Exploring" button
              // Added extra space at bottom for FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView(BuildContext context, DetectionProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (provider.capturedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              provider.capturedImage!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 24),

        if (provider.detectedObject != null) ...[
          ResultCard(
            title: 'Detected',
            content: provider.detectedObject!,
            icon: Icons.visibility,
          ),
        ],

        if (provider.extractedText != null) ...[
          ResultCard(
            title: 'Extracted Text',
            content: provider.extractedText!,
            icon: Icons.text_fields,
            canSpeak: true,
          ),
        ],

        if (provider.translatedText != null) ...[
          ResultCard(
            title: 'Translation',
            content: provider.translatedText!,
            icon: Icons.translate,
            canSpeak: true,
          ),
        ],

        if (provider.summary != null) ...[
          ResultCard(
            title: 'Additional Information',
            content: provider.summary!,
            icon: Icons.info_outline,
            canSpeak: true,
          ),
        ],

        // Actions row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => provider.resetResults(),
                icon: const Icon(Icons.refresh),
                label: const Text('New Scan'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement share functionality
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ),

        // Add some space at the bottom for the FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String title, String content, IconData icon) {
    // Existing info card code...
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
