import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profession.dart';
import '../services/profession_catalog_service.dart';

final professionCatalogProvider = Provider<ProfessionCatalogService>((ref) => ProfessionCatalogService());

final allProfessionsProvider = FutureProvider<List<Profession>>((ref) async {
  final catalog = ref.watch(professionCatalogProvider);
  return catalog.loadAllProfessions();
});

final sectorsWithProfessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final catalog = ref.watch(professionCatalogProvider);
  await catalog.loadAllProfessions();
  return catalog.getSectorsWithProfessions();
});
