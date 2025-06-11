import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/data/providers/auth_provider.dart';
import 'package:travel_lens/data/providers/language_provider.dart';
import 'package:travel_lens/ui/screens/auth/login_screen.dart';

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

          // Authentication section - changes based on login state
          if (authProvider.isAuthenticated)
            _buildAuthenticatedAccountSection(context, authProvider)
          else
            _buildUnauthenticatedAccountSection(context),

          const Divider(height: 32),

          // App Settings (available to all users)
          const ListTile(
            title: Text('App Settings',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                applicationLegalese: '© 2025 TravelLens',
                children: const [
                  SizedBox(height: 16),
                  Text('Your AI-Powered Visual Travel Companion'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget for authenticated users
  Widget _buildAuthenticatedAccountSection(
      BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            authProvider.user?.displayName ??
                authProvider.user?.email?.split('@').first ??
                'User',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(authProvider.user?.email ?? ''),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () async {
              final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (shouldSignOut) {
                await authProvider.signOut();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  // Widget for non-authenticated users
  Widget _buildUnauthenticatedAccountSection(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.account_circle_outlined),
          title: Text('Not signed in'),
          subtitle: Text('Sign in to access your history and saved items'),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            icon: const Icon(Icons.login),
            label: const Text('Sign In'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextButton(
            onPressed: () {
              // You could directly navigate to register screen if you prefer
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('Create a new account'),
          ),
        ),
      ],
    );
  }
}
