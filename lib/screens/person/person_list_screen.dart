import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';

final _personListProvider = FutureProvider<List<Object?>>((ref) async {
  final profile = await ref.watch(activeProfileProvider.future);
  if (profile == null) return [];
  return [];
});

class PersonListScreen extends ConsumerWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(_personListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Persone')),
      body: personsAsync.when(
        data: (_) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Nessuna persona. Il riconoscimento volti (ML Kit) sarà disponibile in una versione successiva.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}
