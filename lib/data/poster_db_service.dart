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
    Map<String, dynamic>? editorState,
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
      'editor_state': _encodeEditorState(editorState),
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
    Map<String, dynamic>? editorState,
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
    if (editorState != null) {
      data['editor_state'] = _encodeEditorState(editorState);
    }

    if (data.isEmpty) {
      return 0;
    }

    return db.update('poster', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePosterDataById(int id, Map<String, dynamic> updates) async {
    final db = await DatabaseHelper.instance.database;
    final data = _normalizeUpdateData(updates);

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
    data['editor_state'] = _decodeEditorState(data['editor_state']);
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

  String? _encodeEditorState(Map<String, dynamic>? editorState) {
    if (editorState == null || editorState.isEmpty) {
      return null;
    }
    return jsonEncode(editorState);
  }

  Map<String, dynamic> _decodeEditorState(dynamic rawEditorState) {
    if (rawEditorState == null) {
      return <String, dynamic>{};
    }
    if (rawEditorState is Map<String, dynamic>) {
      return rawEditorState;
    }
    if (rawEditorState is String && rawEditorState.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawEditorState);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeUpdateData(Map<String, dynamic> updates) {
    final data = <String, dynamic>{};

    if (updates.containsKey('image1')) {
      data['image1'] = _normalizeText(updates['image1']?.toString());
    }
    if (updates.containsKey('image2')) {
      data['image2'] = _normalizeText(updates['image2']?.toString());
    }
    if (updates.containsKey('image3')) {
      data['image3'] = _normalizeText(updates['image3']?.toString());
    }
    if (updates.containsKey('type')) {
      data['type'] = updates['type']?.toString().trim() ?? '';
    }
    if (updates.containsKey('model')) {
      data['model'] = updates['model']?.toString().trim() ?? '';
    }
    if (updates.containsKey('price')) {
      data['price'] = updates['price'];
    }
    if (updates.containsKey('distance_traveled')) {
      data['distance_traveled'] = updates['distance_traveled'];
    }
    if (updates.containsKey('engine_size')) {
      data['engine_size'] = _normalizeText(updates['engine_size']?.toString());
    }
    if (updates.containsKey('location')) {
      data['location'] = _normalizeText(updates['location']?.toString());
    }
    if (updates.containsKey('notes')) {
      final notes = updates['notes'];
      data['notes'] = notes is List<String> ? _encodeNotes(notes) : null;
    }
    if (updates.containsKey('phone_number')) {
      data['phone_number'] = _normalizeText(
        updates['phone_number']?.toString(),
      );
    }
    if (updates.containsKey('web_id')) {
      data['web_id'] = updates['web_id']?.toString().trim() ?? '';
    }
    if (updates.containsKey('editor_state')) {
      final editorState = updates['editor_state'];
      data['editor_state'] = editorState is Map<String, dynamic>
          ? _encodeEditorState(editorState)
          : null;
    }

    return data;
  }
}
