import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/data/providers/detection_provider.dart';
import 'package:travel_lens/ui/screens/camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelLens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, detectionProvider, _) {
          if (detectionProvider.capturedImage == null) {
            return _buildWelcomeView(context);
          } else {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Exploring'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
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
          _buildInfoCard(
              context, 'Detected', provider.detectedObject!, Icons.visibility),
          const SizedBox(height: 16),
        ],

        if (provider.extractedText != null) ...[
          _buildInfoCard(context, 'Extracted Text', provider.extractedText!,
              Icons.text_fields),
          const SizedBox(height: 16),
        ],

        if (provider.translatedText != null) ...[
          _buildInfoCard(context, 'Translation', provider.translatedText!,
              Icons.translate),
          const SizedBox(height: 16),
        ],

        if (provider.summary != null) ...[
          _buildInfoCard(
              context, 'Summary', provider.summary!, Icons.summarize),
          const SizedBox(height: 16),
        ],

        // Add some space at the bottom for the FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String title, String content, IconData icon) {
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
