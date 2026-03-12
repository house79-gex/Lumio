import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/person.dart';
import '../../providers/person_provider.dart';
import '../../repositories/person_repository.dart';

class PersonListScreen extends ConsumerStatefulWidget {
  const PersonListScreen({super.key});

  @override
  ConsumerState<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends ConsumerState<PersonListScreen> {
  final _personRepo = PersonRepository();

  Future<void> _addPerson() async {
    final nameController = TextEditingController();
    final nicknameController = TextEditingController();
    final relationshipController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi persona'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Soprannome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relazione (es. Famiglia, Amico)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final name = nameController.text.trim();
    final nickname = nicknameController.text.trim().isEmpty ? null : nicknameController.text.trim();
    final relationship = relationshipController.text.trim().isEmpty ? null : relationshipController.text.trim();
    final person = Person(
      id: const Uuid().v4(),
      name: name,
      nickname: nickname,
      relationship: relationship,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _personRepo.insertPerson(person);
    if (mounted) {
      ref.invalidate(personsListProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" aggiunto.')));
    }
  }

  Future<void> _editOrDeletePerson(PersonWithCount pwc) async {
    final nameController = TextEditingController(text: pwc.person.name);
    final nicknameController = TextEditingController(text: pwc.person.nickname ?? '');
    final relationshipController = TextEditingController(text: pwc.person.relationship ?? '');
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pwc.person.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Soprannome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relazione',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('${pwc.photoCount} foto associate', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, 'save');
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (choice == 'cancel' || !mounted) return;
    if (choice == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminare persona?'),
          content: Text(
            'Vuoi eliminare "${pwc.person.name}"? Le associazioni con le foto verranno rimosse.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sì, elimina')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      await _personRepo.deletePerson(pwc.person.id);
      if (mounted) {
        ref.invalidate(personsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Persona eliminata.')));
      }
      return;
    }
    if (choice == 'save') {
      final updated = Person(
        id: pwc.person.id,
        name: nameController.text.trim(),
        nickname: nicknameController.text.trim().isEmpty ? null : nicknameController.text.trim(),
        relationship: relationshipController.text.trim().isEmpty ? null : relationshipController.text.trim(),
        profileImagePath: pwc.person.profileImagePath,
        albumId: pwc.person.albumId,
        folderPath: pwc.person.folderPath,
        createdAt: pwc.person.createdAt,
      );
      await _personRepo.updatePerson(updated);
      if (mounted) {
        ref.invalidate(personsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Persona aggiornata.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(personsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Persone')),
      body: personsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text(
                      'Nessuna persona.\nAggiungi persone per associarle alle foto (es. dopo il riconoscimento volti).',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final pwc = list[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(pwc.person.name.isNotEmpty ? pwc.person.name[0].toUpperCase() : '?'),
                ),
                title: Text(pwc.person.name),
                subtitle: Text(
                  [
                    if (pwc.person.nickname != null) pwc.person.nickname,
                    if (pwc.person.relationship != null) pwc.person.relationship,
                    '${pwc.photoCount} foto',
                  ].whereType<String>().join(' · '),
                ),
                onTap: () => _editOrDeletePerson(pwc),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        child: const Icon(Icons.add),
      ),
    );
  }
}
