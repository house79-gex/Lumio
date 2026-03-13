import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';
import '../cloud/cloud_settings_screen.dart';
import '../person/person_list_screen.dart';
import '../category/category_edit_screen.dart';
import 'api_key_setup_screen.dart';
import 'profile_switch_screen.dart';
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

  Future<String> _readFileAsString(String path) => File(path).readAsString();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Altro · Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Attivazione IA (consigliata)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Usa la procedura guidata per ottenere la tua chiave personale da Google e attivare l\'analisi IA.'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiKeySetupScreen()),
              );
              await _loadApiKey();
            },
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Configura IA in 1 minuto'),
          ),
          const SizedBox(height: 16),
          const Text('API Gemini (avanzato)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Inserisci manualmente la chiave API da aistudio.google.com/apikey se preferisci non usare la procedura guidata.'),
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
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Scansione e gruppi grezzi'),
            subtitle: const Text('Spostato nella scheda «Scansione» in basso'),
            enabled: false,
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSwitchScreen())),
            child: const Text('Cambia profilo / Aggiungi profilo'),
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
            title: const Text('Categorie profilo'),
            subtitle: const Text('Aggiungi o modifica categorie'),
            leading: const Icon(Icons.category),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryEditScreen())),
          ),
          ListTile(
            title: const Text('Persone'),
            leading: const Icon(Icons.people),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonListScreen())),
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Esporta profilo'),
            subtitle: const Text('Copia il profilo attivo negli appunti come JSON'),
            leading: const Icon(Icons.upload_file),
            onTap: () async {
              final json = await _settingsRepo.exportActiveProfileAsJson();
              if (!mounted) return;
              if (json == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun profilo attivo da esportare.')));
                return;
              }
              await Clipboard.setData(ClipboardData(text: json));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo copiato negli appunti. Incollalo in un file .json per salvare.')));
            },
          ),
          ListTile(
            title: const Text('Importa profilo'),
            subtitle: const Text('Carica un profilo da file JSON'),
            leading: const Icon(Icons.download),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
              if (!mounted || result == null || result.files.isEmpty) return;
              final file = result.files.single;
              String text;
              if (file.bytes != null) {
                text = utf8.decode(file.bytes!);
              } else if (file.path != null) {
                text = await _readFileAsString(file.path!);
              } else {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossibile leggere il file.')));
                return;
              }
              try {
                final profile = await _settingsRepo.importProfileFromJson(text);
                if (!mounted) return;
                ref.invalidate(activeProfileProvider);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profilo "${profile?.name}" importato e attivato.')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore importazione: $e')));
              }
            },
          ),
        ],
      ),
    );
  }
}
