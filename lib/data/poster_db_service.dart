import 'dart:convert';
import 'package:poster_tool/data/database_helper.dart';

class PosterDbService {
  static final PosterDbService instance = PosterDbService._privateConstructor();
  PosterDbService._privateConstructor();

  // Insert poster
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
  }) async {
    final db = await DatabaseHelper.instance.database;

    final data = {
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'type': type,
      'model': model,
      'price': price,
      'distance_traveled': distanceTraveled,
      'engine_size': engineSize,
      'location': location,
      'notes': notes != null ? jsonEncode(notes) : null,
      'phone_number': phoneNumber,
    };

    return await db.insert('poster', data);
  }

  // Fetch all posters
  Future<List<Map<String, dynamic>>> fetchAllPosters() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('poster');

    return result.map((row) {
      // Make a mutable copy
      final Map<String, dynamic> data = Map<String, dynamic>.from(row);

      // Decode JSON safely
      if (data['notes'] != null && data['notes'] is String) {
        try {
          data['notes'] = List<String>.from(jsonDecode(data['notes']));
        } catch (_) {
          data['notes'] = [];
        }
      }

      return data;
    }).toList();
  }

  // Fetch poster by ID
  Future<Map<String, dynamic>?> fetchPosterById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('poster', where: 'id = ?', whereArgs: [id]);

    if (res.isEmpty) return null;

    final poster = res.first;
    if (poster['notes'] is String) {
      poster['notes'] = jsonDecode(poster['notes'] as String);
    }
    return poster;
  }

  // Update poster by ID
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
  }) async {
    final db = await DatabaseHelper.instance.database;

    final data = <String, dynamic>{};
    if (image1 != null) data['image1'] = image1;
    if (image2 != null) data['image2'] = image2;
    if (image3 != null) data['image3'] = image3;
    if (type != null) data['type'] = type;
    if (model != null) data['model'] = model;
    if (price != null) data['price'] = price;
    if (distanceTraveled != null) data['distance_traveled'] = distanceTraveled;
    if (engineSize != null) data['engine_size'] = engineSize;
    if (location != null) data['location'] = location;
    if (notes != null) data['notes'] = jsonEncode(notes);
    if (phoneNumber != null) data['phone_number'] = phoneNumber;

    return await db.update('poster', data, where: 'id = ?', whereArgs: [id]);
  }
}
