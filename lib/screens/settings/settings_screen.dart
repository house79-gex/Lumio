import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../cloud/cloud_settings_screen.dart';
import '../person/person_list_screen.dart';
import '../../providers/profile_provider.dart';
import '../../providers/ai_provider.dart';
import '../../repositories/settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _settingsRepo = SettingsRepository();
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _settingsRepo.getGeminiApiKey();
    if (mounted) _apiKeyController.text = key ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('API Gemini', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Inserisci la chiave API da aistudio.google.com/apikey per abilitare l\'analisi IA.'),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'Chiave API Gemini',
              border: OutlineInputBorder(),
              hintText: 'AIza...',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await _settingsRepo.setGeminiApiKey(_apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim());
              ref.read(aiServiceProvider).setApiKey(_apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim());
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chiave salvata')));
            },
            child: const Text('Salva chiave API'),
          ),
          const Divider(height: 32),
          const Text('Profilo attivo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Text('Nessun profilo. Vai all\'onboarding.');
              }
              return ListTile(
                leading: Text(profile.emoji, style: const TextStyle(fontSize: 28)),
                title: Text(profile.name),
                subtitle: Text('${profile.categories.length} categorie'),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Errore: $e'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/profession_picker'),
            child: const Text('Cambia professione / profilo'),
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Informazioni'),
            subtitle: Text('${AppConstants.appName} - Catalogazione foto con IA'),
          ),
          ListTile(
            title: const Text('Backup cloud'),
            leading: const Icon(Icons.cloud),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloudSettingsScreen())),
          ),
          ListTile(
            title: const Text('Persone'),
            leading: const Icon(Icons.people),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonListScreen())),
          ),
        ],
      ),
    );
  }
}
