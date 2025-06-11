import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';
import 'package:travel_lens/data/providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Language Settings
          const ListTile(
            title:
                Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Select your preferred language for translations'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Target Language',
              ),
              value: languageProvider.currentLanguage,
              items: languageProvider.supportedLanguages
                  .map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(languageProvider.getLanguageName(code)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  languageProvider.setLanguage(value);
                }
              },
            ),
          ),

          const Divider(height: 32),

          // Account Settings
          const ListTile(
            title:
                Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: Text(authProvider.userEmail ?? 'Not signed in'),
            onTap: () {
              // Navigate to profile screen
            },
          ),

          const Divider(height: 32),

          // App Settings
          const ListTile(
            title: Text('App Settings',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Save History'),
            subtitle: const Text('Store detection results in your account'),
            value: true, // Replace with actual setting
            onChanged: (value) {
              // Update setting
            },
          ),
          SwitchListTile(
            title: const Text('Auto Text-to-Speech'),
            subtitle: const Text('Automatically read translations aloud'),
            value: false, // Replace with actual setting
            onChanged: (value) {
              // Update setting
            },
          ),

          const Divider(height: 32),

          // About Section
          const ListTile(
            title: Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About TravelLens'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'TravelLens',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(),
                applicationLegalese: '© 2025 Your Name',
                children: const [
                  SizedBox(height: 16),
                  Text('Your AI-Powered Visual Travel Companion'),
                ],
              );
            },
          ),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                await authProvider.signOut();
                // Navigate to login screen after sign out
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}
