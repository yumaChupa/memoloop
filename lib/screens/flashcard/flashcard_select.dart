import 'package:flutter/material.dart';
import 'flashcard_screen.dart';
import '../../globals.dart' as globals;
import '../../utils/functions.dart';

class FlashCardSelect extends StatefulWidget {
  @override
  State<FlashCardSelect> createState() => _FlashCardSelectState();
}

class _FlashCardSelectState extends State<FlashCardSelect> {
  //////////////////
  ///// 変数定義 /////
  //////////////////
  globals.QuizOrder selectedOrder = globals.currentOrder;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  List<Map<String, dynamic>> get _filteredTitleFilenames {
    var list = globals.title_filenames.toList();
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
    return list;
  }

  ////////////////////////
  ///// ライフサイクル /////
  ///////////////////////

  /////////////////////
  //////// UI ////////
  ////////////////////
  Widget _buildOrderChip(globals.QuizOrder order, String? label, IconData icon) {
    final isActive = globals.currentOrder == order;
    return GestureDetector(
      onTap: () => setState(() => globals.currentOrder = order),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFFE05555) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcard"),
        scrolledUnderElevation: 0.2,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOrderChip(globals.QuizOrder.original, 'A-Z', Icons.sort_by_alpha),
                  _buildOrderChip(globals.QuizOrder.wrongFirst, '!', Icons.priority_high),
                  _buildOrderChip(globals.QuizOrder.random, null, Icons.shuffle),
                ],
              ),
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
                              color: isSelected ? Color(0xFFE05555) : Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 24,
                            color: isSelected ? Color(0xFFE05555) : Colors.transparent,
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
                        final item = _filteredTitleFilenames[index];
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
                                  left: BorderSide(color: Color(0xFFE05555), width: 4),
                                ),
                              ),
                              child: ListTile(
                                key: ValueKey(item["filename"]),
                                dense: true,
                                minVerticalPadding: 20,
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
                                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FlashCard(title_filename: item),
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
                      childCount: _filteredTitleFilenames.length,
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
