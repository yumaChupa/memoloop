import 'package:flutter/material.dart';
import 'add_screen.dart';
import 'package:memoloop/globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/firebase_functions.dart';
import 'package:memoloop/constants.dart';
import 'package:memoloop/widgets/common_widgets.dart';

class AddSelect extends StatefulWidget {
  @override
  State<AddSelect> createState() => _AddSelectState();
}

enum _AddSortOrder { date, downloads }

class _AddSelectState extends State<AddSelect> {
  late List<Map<String, dynamic>> titleFilenamesFs;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;
  _AddSortOrder _sortOrder = _AddSortOrder.date;

  List<Map<String, dynamic>> get _filteredSets {
    var list = filterTitleFilenames(
      source: titleFilenamesFs,
      searchQuery: _searchQuery,
      selectedTag: _selectedTag,
    );
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
    _loadSets();
  }

  /// Firebase初期化完了を待ってからFirestoreのデータを取得
  Future<void> _loadSets() async {
    await globals.firebaseInitFuture;
    final setsList = await getSetsList();
    if (mounted) {
      setState(() {
        titleFilenamesFs = setsList;
        isLoading = false;
      });
    }
  }

  Widget _buildSortTab(String label, _AddSortOrder order) {
    final isActive = _sortOrder == order;
    return GestureDetector(
      onTap: () => setState(() => _sortOrder = order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.addAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Add"), scrolledUnderElevation: 0.2),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add"),
        scrolledUnderElevation: 0.2,
        actions: [
          Container(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _buildSortTab('New', _AddSortOrder.date),
                const SizedBox(width: 8),
                _buildSortTab('DL', _AddSortOrder.downloads),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            buildSearchTextField(
              controller: _searchController,
              searchQuery: _searchQuery,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            buildTagFilterBar(
              selectedTag: _selectedTag,
              accentColor: AppColors.addAccent,
              onTagSelected: (tag) => setState(() => _selectedTag = tag),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _filteredSets[index];
                        final questionCount = item['questionCount'] ?? 0;
                        final downloadCount = item['downloadCount'] ?? 0;
                        return buildSelectListItem(
                          accentColor: AppColors.addAccent,
                          child: ListTile(
                            key: ValueKey(item["filename"]),
                            dense: true,
                            minVerticalPadding: 16,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              item["title"].toString(),
                              style: TextStyle(
                                color: Colors.grey[850],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Text(
                                    updatedAtTrans(item['updatedAt'].toString()),
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.download, size: 13, color: Colors.grey[400]),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$downloadCount',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.quiz_outlined, size: 13, color: Colors.grey[400]),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$questionCount',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddScreen(titleFilename: item),
                                ),
                              ).then((_) => setState(() {}));
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
