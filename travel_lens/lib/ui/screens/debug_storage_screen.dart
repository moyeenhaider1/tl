import 'package:flutter/material.dart';
import 'package:travel_lens/core/services/storage_service.dart';

class DebugStorageScreen extends StatefulWidget {
  const DebugStorageScreen({super.key});

  @override
  State<DebugStorageScreen> createState() => _DebugStorageScreenState();
}

class _DebugStorageScreenState extends State<DebugStorageScreen> {
  Map<String, dynamic> _providerInfo = StorageService.getProviderInfo();

  void _refreshInfo() {
    setState(() {
      _providerInfo = StorageService.getProviderInfo();
    });
  }

  void _switchToFirebase() {
    StorageService.switchToFirebase();
    _refreshInfo();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switched to Firebase Storage'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _switchToCloudinary() {
    StorageService.switchToCloudinary();
    _refreshInfo();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switched to Cloudinary'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Provider Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Current Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow(
                        'Provider', _providerInfo['current_provider']),
                    _buildInfoRow('Type', _providerInfo['provider_type']),
                    _buildInfoRow('User', _providerInfo['user']),
                    _buildInfoRow('Timestamp', _providerInfo['timestamp']),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          color: _providerInfo['firebase_enabled']
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            'Firebase: ${_providerInfo['firebase_enabled'] ? 'Enabled' : 'Disabled'}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.cloud,
                          color: _providerInfo['cloudinary_enabled']
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            'Cloudinary: ${_providerInfo['cloudinary_enabled'] ? 'Enabled' : 'Disabled'}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Provider Selection
            Text(
              'Switch Storage Provider:',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Firebase Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    StorageService.isUsingFirebase ? null : _switchToFirebase,
                icon: const Icon(Icons.storage),
                label: Text(StorageService.isUsingFirebase
                    ? 'Firebase Storage (Active)'
                    : 'Switch to Firebase Storage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StorageService.isUsingFirebase
                      ? Colors.orange[100]
                      : Colors.orange,
                  foregroundColor: StorageService.isUsingFirebase
                      ? Colors.orange[800]
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Cloudinary Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: StorageService.isUsingCloudinary
                    ? null
                    : _switchToCloudinary,
                icon: const Icon(Icons.cloud),
                label: Text(StorageService.isUsingCloudinary
                    ? 'Cloudinary (Active)'
                    : 'Switch to Cloudinary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StorageService.isUsingCloudinary
                      ? Colors.blue[100]
                      : Colors.blue,
                  foregroundColor: StorageService.isUsingCloudinary
                      ? Colors.blue[800]
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Benefits Card
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Architecture Benefits:',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Switch providers instantly with one line\n'
                      '• Environment variable configuration\n'
                      '• No UI changes required\n'
                      '• Perfect for A/B testing\n'
                      '• Easy to add new providers\n'
                      '• Centralized logging and monitoring',
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Refresh Button
            Center(
              child: TextButton.icon(
                onPressed: _refreshInfo,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
