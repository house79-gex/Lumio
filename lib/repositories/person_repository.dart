import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/person.dart';

class PersonRepository {
  Future<Database> get _db => DatabaseHelper.database;

  Future<void> insertPerson(Person person) async {
    final db = await _db;
    await db.insert('persons', person.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePerson(Person person) async {
    final db = await _db;
    await db.update('persons', person.toJson(), where: 'id = ?', whereArgs: [person.id]);
  }

  Future<void> deletePerson(String id) async {
    final db = await _db;
    await db.delete('photo_persons', where: 'person_id = ?', whereArgs: [id]);
    await db.delete('albums', where: 'person_id = ?', whereArgs: [id]);
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Person>> getAllPersons() async {
    final db = await _db;
    final list = await db.query('persons', orderBy: 'name');
    return list.map((e) => Person.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Person?> getPersonById(String id) async {
    final db = await _db;
    final list = await db.query('persons', where: 'id = ?', whereArgs: [id]);
    if (list.isEmpty) return null;
    return Person.fromJson(Map<String, dynamic>.from(list.first));
  }

  Future<void> linkPhotoToPerson(String photoId, String personId, {double confidence = 1.0}) async {
    final db = await _db;
    await db.insert('photo_persons', {
      'photo_id': photoId,
      'person_id': personId,
      'confidence': confidence,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unlinkPhotoFromPerson(String photoId, String personId) async {
    final db = await _db;
    await db.delete('photo_persons', where: 'photo_id = ? AND person_id = ?', whereArgs: [photoId, personId]);
  }

  /// Ritorna il numero di foto associate a ogni persona.
  Future<Map<String, int>> getPhotoCountByPersonId() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT person_id, COUNT(*) AS cnt FROM photo_persons GROUP BY person_id',
    );
    return {for (var r in rows) r['person_id'] as String: r['cnt'] as int};
  }
}
