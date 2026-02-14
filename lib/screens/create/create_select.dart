import 'package:flutter/material.dart';
import 'package:memoloop/globals.dart' as globals;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'create_screen.dart';
import 'package:memoloop/utils/functions.dart'; // saveTitleFilenames()を定義

class createSelect extends StatefulWidget {
  @override
  State<createSelect> createState() => _createSelectState();
}

class _createSelectState extends State<createSelect> {
  //////////////////
  ///// 変数定義 /////
  //////////////////
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

  ////////////////////
  ///// ロジック /////
  ///////////////////
  //新規問題セット作成
  void _showAddDialog() {
    final controller = TextEditingController();
    final selectedTags = <String>{};

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[50],
          title: const Text('新しい問題セット作成', style: TextStyle(fontSize: 18)),
          content: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    child: TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'タイトルを入力',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('タグ', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: globals.availableTags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 13)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: Colors.blue[200],
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  // タイトルから安全なスラッグを生成（日本語OK、絵文字とFirestore禁止文字を除去）
                  final slug = title
                      .replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '') // 絵文字除去
                      .replaceAll(RegExp(r'[/\.\s]'), '_')   // パス区切り・ドット・空白→_
                      .replaceAll(RegExp(r'_+'), '_')          // 連続_を1つに
                      .replaceAll(RegExp(r'^_|_$'), '');       // 先頭末尾の_を除去
                  final truncatedSlug = slug.length > 20 ? slug.substring(0, 20) : slug;
                  final shortHash = md5.convert(utf8.encode(title + globals.uuid)).toString().substring(0, 8);
                  final filename = '${truncatedSlug}_$shortHash';
                  final update_now = DateTime.now().toIso8601String();

                  final newItem = <String, dynamic>{
                    "title": title,
                    "filename": filename,
                    "updatedAt": update_now,
                    "tags": selectedTags.toList(),
                    "isMine": true,
                  };

                  setState(() {
                    globals.title_filenames.add(newItem);
                  });

                  createNewfile(filename);
                  updateAndSortByDate(newItem);

                  setState(() {});
                }
                Navigator.pop(context);
              },
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }

  ///////////////////
  /////// UI ///////
  ///////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create"),
        scrolledUnderElevation: 0.2,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
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
                              color: isSelected ? Color(0xFF4A90D9) : Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 24,
                            color: isSelected ? Color(0xFF4A90D9) : Colors.transparent,
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
                                  left: BorderSide(color: Color(0xFF4A90D9), width: 4),
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
                                      builder: (context) => Create(title_filename: item),
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
