import 'dart:convert';

import 'package:poster_tool/data/database_helper.dart';

class PosterDbService {
  static final PosterDbService instance = PosterDbService._privateConstructor();

  PosterDbService._privateConstructor();

  Future<int> insertPoster({
    String? image1,
    String? image2,
    String? image3,
    required String type,
    required String model,
    double? price,
    double? distanceTraveled,
    String? engineSize,
    String? location,
    List<String>? notes,
    String? phoneNumber,
    required String webId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final data = <String, dynamic>{
      'image1': _normalizeText(image1),
      'image2': _normalizeText(image2),
      'image3': _normalizeText(image3),
      'type': type.trim(),
      'model': model.trim(),
      'price': price,
      'distance_traveled': distanceTraveled,
      'engine_size': _normalizeText(engineSize),
      'location': _normalizeText(location),
      'notes': _encodeNotes(notes),
      'phone_number': _normalizeText(phoneNumber),
      'web_id': webId.trim(),
    };

    return db.insert('poster', data);
  }

  Future<List<Map<String, dynamic>>> fetchAllPosters() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('poster', orderBy: 'id DESC');
    return result.map(_normalizePosterRow).toList();
  }

  Future<Map<String, dynamic>?> fetchPosterById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('poster', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) {
      return null;
    }
    return _normalizePosterRow(res.first);
  }

  Future<int> updatePosterById(
    int id, {
    String? image1,
    String? image2,
    String? image3,
    String? type,
    String? model,
    double? price,
    double? distanceTraveled,
    String? engineSize,
    String? location,
    List<String>? notes,
    String? phoneNumber,
    String? webId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final data = <String, dynamic>{};
    if (image1 != null) data['image1'] = _normalizeText(image1);
    if (image2 != null) data['image2'] = _normalizeText(image2);
    if (image3 != null) data['image3'] = _normalizeText(image3);
    if (type != null) data['type'] = type.trim();
    if (model != null) data['model'] = model.trim();
    if (price != null) data['price'] = price;
    if (distanceTraveled != null) {
      data['distance_traveled'] = distanceTraveled;
    }
    if (engineSize != null) data['engine_size'] = _normalizeText(engineSize);
    if (location != null) data['location'] = _normalizeText(location);
    if (notes != null) data['notes'] = _encodeNotes(notes);
    if (phoneNumber != null) {
      data['phone_number'] = _normalizeText(phoneNumber);
    }
    if (webId != null) data['web_id'] = webId.trim();

    if (data.isEmpty) {
      return 0;
    }

    return db.update('poster', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePosterById(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('poster', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _normalizePosterRow(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    data['notes'] = _decodeNotes(data['notes']);
    data['web_id'] = data['web_id']?.toString() ?? '';
    return data;
  }

  String? _normalizeText(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _encodeNotes(List<String>? notes) {
    if (notes == null) {
      return null;
    }
    final normalized = notes
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList();
    return jsonEncode(normalized);
  }

  List<String> _decodeNotes(dynamic rawNotes) {
    if (rawNotes == null) {
      return <String>[];
    }
    if (rawNotes is List) {
      return rawNotes.map((note) => note.toString()).toList();
    }
    if (rawNotes is String) {
      try {
        final decoded = jsonDecode(rawNotes);
        if (decoded is List) {
          return decoded.map((note) => note.toString()).toList();
        }
      } catch (_) {
        return <String>[];
      }
    }
    return <String>[];
  }
}
