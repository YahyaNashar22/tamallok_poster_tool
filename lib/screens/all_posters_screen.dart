import 'dart:io';
import 'package:flutter/material.dart';
import 'package:poster_tool/data/poster_db_service.dart';
import 'package:poster_tool/screens/poster_viewer_screen.dart';

class AllPostersScreen extends StatefulWidget {
  const AllPostersScreen({super.key});

  @override
  State<AllPostersScreen> createState() => _AllPostersScreenState();
}

class _AllPostersScreenState extends State<AllPostersScreen> {
  List<Map<String, dynamic>> _posters = [];

  @override
  void initState() {
    super.initState();
    _loadPosters();
  }

  Future<void> _loadPosters() async {
    final posters = await PosterDbService.instance.fetchAllPosters();
    setState(() => _posters = posters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Posters')),
      body: _posters.isEmpty
          ? const Center(child: Text('No posters created yet.'))
          : ListView.builder(
              itemCount: _posters.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, i) {
                final poster = _posters[i];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PosterViewerScreen(poster: poster),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading:
                          poster['image1'] != null &&
                              File(poster['image1']).existsSync()
                          ? Image.file(
                              File(poster['image1']),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported, size: 40),
                      title: Text('${poster['type']} - ${poster['model']}'),
                      subtitle: Text(
                        'Price: ${poster['price'] ?? '-'} | Distance: ${poster['distance_traveled'] ?? '-'}',
                      ),
                      trailing: Text(poster['phone_number'] ?? ''),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
