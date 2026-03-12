import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/ai_provider.dart';
import '../../repositories/settings_repository.dart';

class ApiKeySetupScreen extends ConsumerStatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  ConsumerState<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<ApiKeySetupScreen> {
  final _settingsRepo = SettingsRepository();
  final _keyController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _openGooglePage() async {
    final uri = Uri.parse('https://aistudio.google.com/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire la pagina. Copia e incolla l\'indirizzo nel browser: aistudio.google.com/apikey')),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun testo negli appunti.')),
      );
      return;
    }
    setState(() {
      _keyController.text = text;
    });
  }

  bool _looksLikeApiKey(String value) {
    final v = value.trim();
    if (!v.startsWith('AIza')) return false;
    if (v.length < 30) return false;
    final regex = RegExp(r'^[A-Za-z0-9_\-]+$');
    return regex.hasMatch(v);
  }

  Future<void> _activateKey() async {
    final key = _keyController.text.trim();
    if (!_looksLikeApiKey(key)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La chiave non sembra valida. Controlla di aver copiato tutto, senza spazi.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _settingsRepo.setGeminiApiKey(key);
      final aiService = ref.read(aiServiceProvider);
      aiService.setApiKey(key);
      final ok = await aiService.testApiKey();
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IA attivata correttamente.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La chiave non sembra attiva o autorizzata. Riprova a crearla da Google AI Studio.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'attivazione: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attiva IA (guidata)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${AppConstants.appName} usa i servizi IA di Google per analizzare le foto.\n'
            'La chiave resta solo sul tuo dispositivo.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.looks_one, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Apri la pagina Google'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Ti porteremo alla pagina ufficiale Google per creare la tua chiave personale.'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _loading ? null : _openGooglePage,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Apri aistudio.google.com/apikey'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.looks_two, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Copia la chiave'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Nella pagina Google clicca "Create API key", poi copia il codice che inizia con "AIza".'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.looks_3, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Incolla e attiva'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    decoration: InputDecoration(
                      labelText: 'Chiave API Gemini',
                      hintText: 'AIza...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: _loading ? null : _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste),
                        tooltip: 'Incolla dagli appunti',
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loading ? null : _activateKey,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_loading ? 'Verifica in corso...' : 'Attiva IA'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

