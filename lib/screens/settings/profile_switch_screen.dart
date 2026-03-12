import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profession.dart';
import '../../providers/profile_provider.dart';
import '../../repositories/settings_repository.dart';

class ProfileSwitchScreen extends ConsumerWidget {
  const ProfileSwitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesListProvider);
    final activeIdAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scegli profilo')),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nessun profilo salvato.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/profession_picker'),
                    child: const Text('Crea primo profilo'),
                  ),
                ],
              ),
            );
          }
          return activeIdAsync.when(
            data: (activeProfile) {
              final activeId = activeProfile?.id;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...profiles.map((p) {
                    final isActive = p.id == activeId;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
                      child: ListTile(
                        leading: Text(p.emoji, style: const TextStyle(fontSize: 32)),
                        title: Text(p.name),
                        subtitle: Text('${p.categories.length} categorie'),
                        trailing: isActive ? const Icon(Icons.check_circle) : null,
                        onTap: () async {
                          final repo = SettingsRepository();
                          await repo.setActiveProfileId(p.id);
                          if (context.mounted) {
                            ref.invalidate(activeProfileProvider);
                            ref.invalidate(profilesListProvider);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/profession_picker').then((_) {
                      ref.invalidate(profilesListProvider);
                      ref.invalidate(activeProfileProvider);
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi nuovo profilo'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}
