import 'package:flutter/material.dart';
import 'package:travel_lens/data/providers/detection_provider.dart';

class ProcessingView extends StatelessWidget {
  final DetectionProvider provider;
  final VoidCallback onRetry;

  const ProcessingView({
    super.key,
    required this.provider,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (provider.status == ProcessingStatus.error) {
      return _buildErrorView(context);
    }

    // Show processing state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress indicator
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: provider.progressValue,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Center(
                  child: Text(
                    '${(provider.progressValue * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Processing step text
          Text(
            _getStatusText(provider.status),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Processing description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _getStatusDescription(provider.status),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Error',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.detecting:
        return 'Detecting Objects...';
      case ProcessingStatus.extracting:
        return 'Extracting Text...';
      case ProcessingStatus.translating:
        return 'Translating Text...';
      case ProcessingStatus.summarizing:
        return 'Finding Information...';
      default:
        return 'Processing...';
    }
  }

  String _getStatusDescription(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.detecting:
        return 'Identifying objects and landmarks in your image';
      case ProcessingStatus.extracting:
        return 'Reading and extracting text from the image';
      case ProcessingStatus.translating:
        return 'Translating the extracted text to your language';
      case ProcessingStatus.summarizing:
        return 'Gathering additional information about what we found';
      default:
        return 'Processing your image with AI...';
    }
  }
}
