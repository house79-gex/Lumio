import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/person.dart';
import '../repositories/person_repository.dart';

final personRepositoryProvider = Provider<PersonRepository>((ref) => PersonRepository());

final personsListProvider = FutureProvider<List<PersonWithCount>>((ref) async {
  final repo = ref.watch(personRepositoryProvider);
  final persons = await repo.getAllPersons();
  final counts = await repo.getPhotoCountByPersonId();
  return persons.map((p) => PersonWithCount(p, counts[p.id] ?? 0)).toList();
});

class PersonWithCount {
  final Person person;
  final int photoCount;
  PersonWithCount(this.person, this.photoCount);
}
