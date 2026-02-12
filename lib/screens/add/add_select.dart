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
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTag = isSelected ? null : tag;
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Color(0xFF27AE60) : Colors.grey[500],
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                height: 2,
                                width: 24,
                                color: isSelected ? Color(0xFF27AE60) : Colors.transparent,
                              ),
                            ],
                          ),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Color(0xFF27AE60), width: 4),
                                    ),
                                  ),
                                  child: ListTile(
                                    key: ValueKey(item["filename"]),
                                    dense: true,
                                    minVerticalPadding: 16,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item["title"].toString(),
                                            style: TextStyle(
                                              color: Colors.grey[850],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          updatedAtTrans(item['updatedAt'].toString()),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.download, size: 13, color: Colors.grey[400]),
                                          SizedBox(width: 3),
                                          Text(
                                            '${item['downloadCount'] ?? 0}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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
                                ),
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
