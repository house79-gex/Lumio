import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/profession.dart';
import '../../providers/professions_provider.dart';
import '../../repositories/settings_repository.dart';

class ProfessionPickerScreen extends ConsumerStatefulWidget {
  const ProfessionPickerScreen({super.key});

  @override
  ConsumerState<ProfessionPickerScreen> createState() => _ProfessionPickerScreenState();
}

class _ProfessionPickerScreenState extends ConsumerState<ProfessionPickerScreen> {
  final _settingsRepo = SettingsRepository();
  final _uuid = const Uuid();

  Future<void> _selectProfession(Profession profession) async {
    final profile = UserProfile(
      id: _uuid.v4(),
      name: profession.name,
      emoji: profession.emoji,
      baseProfession: profession,
      categories: List.from(profession.defaultCategories),
      baseFolderPath: '',
      createdAt: DateTime.now(),
    );
    await _settingsRepo.saveProfile(profile);
    await _settingsRepo.setActiveProfileId(profile.id);
    await _settingsRepo.setOnboardingDone(true);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsWithProfessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Seleziona professione')),
      body: sectorsAsync.when(
        data: (sectors) {
          if (sectors.isEmpty) {
            return const Center(child: Text('Nessuna professione disponibile'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sectors.length,
            itemBuilder: (context, i) {
              final sector = sectors[i];
              final sectorName = sector['name'] as String? ?? '';
              final emoji = sector['emoji'] as String? ?? '📁';
              final professions = sector['professions'] as List<dynamic>? ?? [];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(sectorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: professions.map<Widget>((p) {
                    final map = Map<String, dynamic>.from(p as Map);
                    map['sector'] = sectorName;
                    final profession = Profession.fromJson(map);
                    return ListTile(
                      leading: Text(profession.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(profession.name),
                      onTap: () => _selectProfession(profession),
                    );
                  }).toList(),
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
}
