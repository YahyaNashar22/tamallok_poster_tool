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
  // Original list of all posters
  List<Map<String, dynamic>> _allPosters = [];
  // List shown to the user (filtered list)
  List<Map<String, dynamic>> _filteredPosters = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosters();
    // Start listening to changes in the search field
    _searchController.addListener(_filterPosters);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _searchController.removeListener(_filterPosters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosters() async {
    final posters = await PosterDbService.instance.fetchAllPosters();
    setState(() {
      _allPosters = posters;
      _filteredPosters =
          posters; // Initialize the filtered list with all posters
    });
  }

  void _filterPosters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // If the search query is empty, show all posters
        _filteredPosters = _allPosters;
      } else {
        // Filter the original list based on the query
        _filteredPosters = _allPosters.where((poster) {
          final type = poster['type']?.toLowerCase() ?? '';
          final model = poster['model']?.toLowerCase() ?? '';
          final webId =
              poster['web_id']?.toString().toLowerCase() ?? ''; // Check ID

          // Search by type, model, or ID
          return type.contains(query) ||
              model.contains(query) ||
              webId.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Posters'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Type, Model, or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterPosters(); // Re-run filter to show all
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
              onChanged: (_) => _filterPosters(),
            ),
          ),
        ),
      ),
      body: _filteredPosters.isEmpty
          ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No posters created yet.'
                    : 'No results found for "${_searchController.text}"',
              ),
            )
          : ListView.builder(
              itemCount: _filteredPosters.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, i) {
                final poster = _filteredPosters[i]; // Use filtered list
                // ... rest of your existing ListTile code ...
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
                      title: Text(
                        '${poster['type']} - ${poster['model']} - ${poster['web_id']}',
                      ),
                      subtitle: Text(
                        'Price: ${poster['price'] ?? '-'} | Distance: ${poster['distance_traveled'] ?? '-'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(poster['phone_number'] ?? ''),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete poster',
                            onPressed: () => _confirmDelete(poster),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> poster) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poster'),
        content: Text(
          'Are you sure you want to delete "${poster['type']} - ${poster['model']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final id = poster['id'];
      if (id == null) return;

      await PosterDbService.instance.deletePosterById(id as int);
      await _loadPosters();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Poster deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete poster')));
    }
  }
}
