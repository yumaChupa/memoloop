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

  Set<String> get _allTags {
    final tags = <String>{};
    for (var item in globals.title_filenames) {
      final itemTags = (item['tags'] as List<dynamic>?)?.cast<String>() ?? [];
      tags.addAll(itemTags);
    }
    return tags;
  }

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcard"),
        scrolledUnderElevation: 0.2,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16), // 右端に隙間
            child: DropdownButton<globals.QuizOrder>(
              value: globals.currentOrder,
              underline: SizedBox(),
              dropdownColor: Colors.grey[100],
              icon: SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    globals.currentOrder = value;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                  value: globals.QuizOrder.original,
                  child: Text('default'),
                ),
                DropdownMenuItem(
                  value: globals.QuizOrder.wrongFirst,
                  child: Text('mistakes'),
                ),
                DropdownMenuItem(
                  value: globals.QuizOrder.random,
                  child: Text('shuffle'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            Padding(
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
            if (_allTags.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _allTags.map((tag) {
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
                        selectedColor: Colors.red[200],
                        backgroundColor: Colors.grey[200],
                      ),
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTitleFilenames.length,
                itemBuilder: (context, index) {
                  final item = _filteredTitleFilenames[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: Color(0xFFFFE2E1)),
                    child: ListTile(
                      key: ValueKey(item["filename"]),
                      dense: true,
                      minVerticalPadding: 28,
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
                            style: TextStyle(color: Colors.grey[900], fontSize: 12),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
