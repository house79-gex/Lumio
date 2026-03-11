import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudSettingsScreen extends ConsumerWidget {
  const CloudSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup cloud')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Provider attivi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Text('📁', style: TextStyle(fontSize: 28)),
            title: const Text('Google Drive'),
            subtitle: const Text('Non configurato'),
            onTap: () {},
          ),
          ListTile(
            leading: const Text('📦', style: TextStyle(fontSize: 28)),
            title: const Text('Dropbox'),
            subtitle: const Text('Non configurato'),
            onTap: () {},
          ),
          ListTile(
            leading: const Text('☁️', style: TextStyle(fontSize: 28)),
            title: const Text('OneDrive'),
            subtitle: const Text('Non configurato'),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            'Inserisci le chiavi API e accedi dai provider per abilitare il backup. La sincronizzazione avverrà sulle cartelle create da PhotoAI.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
