import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poster_tool/data/poster_db_service.dart';
import 'package:poster_tool/screens/poster_viewer_screen.dart';

class AllPostersScreen extends StatefulWidget {
  const AllPostersScreen({super.key});

  @override
  State<AllPostersScreen> createState() => _AllPostersScreenState();
}

class _AllPostersScreenState extends State<AllPostersScreen> {
  List<Map<String, dynamic>> _allPosters = [];
  List<Map<String, dynamic>> _filteredPosters = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPosters);
    _loadPosters();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPosters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosters() async {
    setState(() => _loading = true);
    final posters = await PosterDbService.instance.fetchAllPosters();
    if (!mounted) {
      return;
    }
    setState(() {
      _allPosters = posters;
      _filteredPosters = _applyQuery(posters, _searchController.text);
      _loading = false;
    });
  }

  void _filterPosters() {
    setState(() {
      _filteredPosters = _applyQuery(_allPosters, _searchController.text);
    });
  }

  List<Map<String, dynamic>> _applyQuery(
    List<Map<String, dynamic>> posters,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return posters;
    }
    return posters.where((poster) {
      final type = poster['type']?.toString().toLowerCase() ?? '';
      final model = poster['model']?.toString().toLowerCase() ?? '';
      final webId = poster['web_id']?.toString().toLowerCase() ?? '';
      final phone = poster['phone_number']?.toString().toLowerCase() ?? '';
      return type.contains(normalizedQuery) ||
          model.contains(normalizedQuery) ||
          webId.contains(normalizedQuery) ||
          phone.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _confirmDelete(Map<String, dynamic> poster) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Poster'),
          content: Text(
            'Delete "${poster['type']} ${poster['model']}" with ID ${poster['web_id']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await PosterDbService.instance.deletePosterById(poster['id'] as int);
      await _loadPosters();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Poster deleted.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete poster.')),
      );
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) {
      return '-';
    }
    if (value is num) {
      if (value % 1 == 0) {
        return NumberFormat('#,###').format(value.toInt());
      }
      return NumberFormat('#,###.##').format(value);
    }
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }
    if (parsed % 1 == 0) {
      return NumberFormat('#,###').format(parsed.toInt());
    }
    return NumberFormat('#,###.##').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final resultsText = _searchController.text.trim().isEmpty
        ? '${_allPosters.length} poster(s)'
        : '${_filteredPosters.length} result(s)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poster Library'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPosters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search by type, model, ID, or phone number',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterPosters();
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(resultsText),
                        avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Open any poster to preview the generated layout, replace images, and export the final design.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPosters.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: _filteredPosters.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final poster = _filteredPosters[index];
                        final imagePath = poster['image1']?.toString();
                        final hasImage = imagePath != null &&
                            imagePath.isNotEmpty &&
                            File(imagePath).existsSync();

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PosterViewerScreen(poster: poster),
                                ),
                              );
                              _loadPosters();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: hasImage
                                        ? Image.file(
                                            File(imagePath),
                                            width: 96,
                                            height: 96,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 96,
                                            height: 96,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${poster['type']} ${poster['model']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Chip(
                                              label: Text('ID ${poster['web_id']}'),
                                            ),
                                            Chip(
                                              label: Text(
                                                'Price ${_formatNumber(poster['price'])}',
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                'Distance ${_formatNumber(poster['distance_traveled'])}',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          poster['phone_number']?.toString().isNotEmpty ==
                                                  true
                                              ? poster['phone_number'].toString()
                                              : 'No phone number',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        tooltip: 'Open poster',
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PosterViewerScreen(
                                                poster: poster,
                                              ),
                                            ),
                                          );
                                          _loadPosters();
                                        },
                                        icon: const Icon(Icons.open_in_new),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete poster',
                                        onPressed: () => _confirmDelete(poster),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = _searchController.text.trim().isNotEmpty;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.find_in_page_outlined, size: 54),
            const SizedBox(height: 16),
            Text(
              searching ? 'No matching posters found.' : 'No posters saved yet.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try a broader search using type, model, ID, or phone number.'
                  : 'Create a poster from the home screen or import them from Excel.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
