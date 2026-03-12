import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profession.dart';
import '../../providers/profile_provider.dart';
import '../../repositories/settings_repository.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  const CategoryEditScreen({super.key});

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _settingsRepo = SettingsRepository();

  Future<void> _saveProfile(UserProfile profile) async {
    await _settingsRepo.saveProfile(profile);
    ref.invalidate(activeProfileProvider);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo aggiornato')));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorie del profilo')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Nessun profilo attivo'));
          final categories = List<ProfessionCategory>.from(profile.categories);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length + 1,
            itemBuilder: (context, i) {
              if (i == categories.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddCategory(context, profile, categories),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi categoria'),
                  ),
                );
              }
              final cat = categories[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(cat.name),
                  subtitle: Text(cat.folderName),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') _showEditCategory(context, profile, categories, i);
                      else if (v == 'delete') {
                        categories.removeAt(i);
                        await _saveProfile(profile.copyWith(categories: categories));
                        setState(() {});
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                      const PopupMenuItem(value: 'delete', child: Text('Elimina')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }

  Future<void> _showAddCategory(BuildContext context, UserProfile profile, List<ProfessionCategory> categories) async {
    final nameC = TextEditingController();
    final emojiC = TextEditingController(text: '📁');
    final folderC = TextEditingController();
    final descC = TextEditingController();
    bool splitByYear = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuova categoria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emojiC, decoration: const InputDecoration(labelText: 'Emoji')),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nome')),
                TextField(controller: folderC, decoration: const InputDecoration(labelText: 'Nome cartella')),
                TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrizione per AI'), maxLines: 2),
                CheckboxListTile(
                  value: splitByYear,
                  onChanged: (v) => setDialogState(() => splitByYear = v ?? false),
                  title: const Text('Suddividi per anno'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                final name = nameC.text.trim();
                final folder = folderC.text.trim().isEmpty ? name : folderC.text.trim();
                if (name.isEmpty) return;
                final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                categories.add(ProfessionCategory(
                  id: id,
                  name: name,
                  emoji: emojiC.text.trim().isEmpty ? '📁' : emojiC.text.trim(),
                  description: descC.text.trim(),
                  folderName: folder,
                  splitByYear: splitByYear,
                  isCustom: true,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
    if (categories.length > profile.categories.length) {
      await _saveProfile(profile.copyWith(categories: categories));
      setState(() {});
    }
  }

  Future<void> _showEditCategory(BuildContext context, UserProfile profile, List<ProfessionCategory> categories, int index) async {
    final cat = categories[index];
    final nameC = TextEditingController(text: cat.name);
    final emojiC = TextEditingController(text: cat.emoji);
    final folderC = TextEditingController(text: cat.folderName);
    final descC = TextEditingController(text: cat.description);
    bool splitByYear = cat.splitByYear;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Modifica categoria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emojiC, decoration: const InputDecoration(labelText: 'Emoji')),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nome')),
                TextField(controller: folderC, decoration: const InputDecoration(labelText: 'Nome cartella')),
                TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrizione per AI'), maxLines: 2),
                CheckboxListTile(
                  value: splitByYear,
                  onChanged: (v) => setDialogState(() => splitByYear = v ?? false),
                  title: const Text('Suddividi per anno'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                final name = nameC.text.trim();
                final folder = folderC.text.trim().isEmpty ? name : folderC.text.trim();
                if (name.isEmpty) return;
                categories[index] = ProfessionCategory(
                  id: cat.id,
                  name: name,
                  emoji: emojiC.text.trim().isEmpty ? '📁' : emojiC.text.trim(),
                  description: descC.text.trim(),
                  folderName: folder,
                  splitByYear: splitByYear,
                  isCustom: cat.isCustom,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
    await _saveProfile(profile.copyWith(categories: categories));
    setState(() {});
  }
}
