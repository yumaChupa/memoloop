import 'package:flutter/material.dart';
import 'add_screen.dart';
import '../../globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/firebase_functions.dart';

class AddSelect extends StatefulWidget {
  @override
  State<AddSelect> createState() => _AddSelectState();
}

enum _AddSortOrder { date, downloads }

class _AddSelectState extends State<AddSelect> {
  late List<Map<String, dynamic>> title_filenames_fs;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;
  _AddSortOrder _sortOrder = _AddSortOrder.date;

  List<Map<String, dynamic>> get _filteredSets {
    var list = title_filenames_fs.toList();
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    if (_selectedTag != null) {
      list = list.where((item) {
        final tags = (item['tags'] as List<dynamic>?)?.cast<String>() ?? [];
        return tags.contains(_selectedTag);
      }).toList();
    }
    switch (_sortOrder) {
      case _AddSortOrder.date:
        list.sort((a, b) {
          final aDate = DateTime.tryParse(a['updatedAt']?.toString() ?? '') ?? DateTime(1970);
          final bDate = DateTime.tryParse(b['updatedAt']?.toString() ?? '') ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case _AddSortOrder.downloads:
        list.sort((a, b) => ((b['downloadCount'] ?? 0) as int)
            .compareTo((a['downloadCount'] ?? 0) as int));
        break;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    getSetsList().then((setsList) {
      setState(() {
        title_filenames_fs = setsList;
        isLoading = false;
      });
    });
    // firebaseInit(globals.title_filenames);
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
          appBar: AppBar(title: const Text("Add"), scrolledUnderElevation: 0.2),
          body: Center(child: CircularProgressIndicator()),
        )
        : Scaffold(
          appBar: AppBar(
            title: const Text("Add"),
            scrolledUnderElevation: 0.2,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: DropdownButton<_AddSortOrder>(
                  value: _sortOrder,
                  underline: SizedBox(),
                  dropdownColor: Colors.grey[100],
                  icon: Icon(Icons.sort),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortOrder = value);
                    }
                  },
                  items: [
                    DropdownMenuItem(value: _AddSortOrder.date, child: Text('新しい順')),
                    DropdownMenuItem(value: _AddSortOrder.downloads, child: Text('DL数順')),
                  ],
                ),
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: globals.availableTags.map((tag) {
                      final isSelected = _selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag, style: TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTag = selected ? tag : null;
                            });
                          },
                          selectedColor: Colors.green[200],
                          backgroundColor: Colors.grey[200],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '検索...',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _filteredSets[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(color: Color(0xFFDDFFDD)),
                              child: ListTile(
                                key: ValueKey(item["filename"]),
                                dense: true,
                                minVerticalPadding: 20,
                                contentPadding: EdgeInsets.symmetric(horizontal: 48),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item["title"].toString(),
                                      style: TextStyle(
                                        color: Colors.grey[900],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      updatedAtTrans(item['updatedAt'].toString()),
                                      style: TextStyle(
                                        color: Colors.grey[900],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 14, color: Colors.grey[600]),
                                      SizedBox(width: 2),
                                      Text(
                                        '${item['downloadCount'] ?? 0}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddScreen(title_filename: item),
                                    ),
                                  ).then((_) {
                                    setState(() {});
                                  });
                                },
                              ),
                            );
                          },
                          childCount: _filteredSets.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
