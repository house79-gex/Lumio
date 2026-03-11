import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/profession.dart';

class ProfessionCatalogService {
  List<Map<String, dynamic>>? _rawSectors;

  Future<List<Profession>> loadAllProfessions() async {
    final json = await rootBundle.loadString('assets/professions/professions_catalog.json');
    final data = jsonDecode(json) as Map<String, dynamic>;
    final sectors = data['sectors'] as List<dynamic>? ?? [];
    _rawSectors = sectors.map((e) => e as Map<String, dynamic>).toList();
    final list = <Profession>[];
    for (final sector in _rawSectors!) {
      final sectorName = sector['name'] as String? ?? '';
      final professions = sector['professions'] as List<dynamic>? ?? [];
      for (final p in professions) {
        final map = Map<String, dynamic>.from(p as Map);
        map['sector'] = sectorName;
        list.add(Profession.fromJson(map));
      }
    }
    return list;
  }

  List<Map<String, dynamic>> getSectorsWithProfessions() {
    if (_rawSectors == null) return [];
    return _rawSectors!;
  }
}
