import 'package:flutter/material.dart';
import 'overview_screen.dart';
import '../../globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/firebase_functions.dart';

class OverviewSelect extends StatefulWidget {
  @override
  State<OverviewSelect> createState() => _OverviewSelectState();
}

class _OverviewSelectState extends State<OverviewSelect> {
  //////////////
  ////変数定義///
  //////////////
  Offset? _tapPosition;
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

  ///////////////////////
  //// ロジック /////
  ///////////////////////
  // タップしたポジションを返す
  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  // 長押しで共有・削除メニュー表示
  Future<void> _showMenu(Map<String, dynamic> item) async {
    final screenSize = MediaQuery.of(context).size;
    final dx = screenSize.width - 300;
    double dy = _tapPosition!.dy;

    if (dy + 100 > screenSize.height) {
      dy = _tapPosition!.dy - 100;
      if (dy < 0) dy = 0;
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(dx, dy, 10, screenSize.height - dy),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      items: [
        PopupMenuItem(
          value: 'tags',
          child: Text('タグ編集', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem(
          value: 'share',
          child: Text('共有', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem(
          value: 'upload',
          child: Text('公開', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            '削除',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    if (selected == 'tags') {
      final currentTags = (item['tags'] as List<dynamic>?)?.cast<String>() ?? [];
      final tagsController = TextEditingController(text: currentTags.join(', '));
      final newTags = await showDialog<List<String>>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('タグ編集', style: TextStyle(fontSize: 18)),
          content: TextField(
            controller: tagsController,
            decoration: InputDecoration(
              hintText: 'カンマ区切りでタグを入力',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final tags = tagsController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                Navigator.pop(context, tags);
              },
              child: Text('保存'),
            ),
          ],
        ),
      );
      if (newTags != null) {
        setState(() {
          item['tags'] = newTags;
        });
        await saveTitleFilenames();
      }
    } else if (selected == 'share') {
      await shareFile(context, item['filename']?.toString() ?? '');
    } else if (selected == 'upload') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('確認'),
              content: Text('この問題セットを公開しますか？\n再度公開することで内容を更新できます'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('公開'),
                ),
              ],
            ),
      );
      if (confirmed == true) {
        final tags = (item['tags'] as List<dynamic>?)?.cast<String>() ?? [];
        uploadProblemSetWithReset(
          item["title"]!.toString(),
          item["filename"]!.toString(),
          tags: tags,
        );
      }
    } else if (selected == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: Colors.grey[50],
              title: Text('削除確認'),
              content: Text('この問題セットを削除しますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('削除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
      );
      if (confirm == true) {
        await deleteFile(item['filename']?.toString() ?? '');
        setState(() {
          globals.title_filenames.removeWhere(
            (e) => e['filename'] == item['filename'],
          );
        });
        await saveTitleFilenames();
      }
    }
  }

  ///////////////
  ////  UI  /////
  ///////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Listview"),
        scrolledUnderElevation: 0.2,
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
                        selectedColor: Colors.orange[200],
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
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: _storePosition,
                    onLongPress: () => _showMenu(item),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(color: Color(0xFFFFE6CA)),
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
                              style: TextStyle(color: Colors.grey[900], fontSize: 12),
                            ),
                          ],
                        ),
                        subtitle: ((item['tags'] as List<dynamic>?)?.isNotEmpty == true)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  children: (item['tags'] as List<dynamic>)
                                      .cast<String>()
                                      .map((tag) => Chip(
                                            label: Text(tag, style: TextStyle(fontSize: 11)),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                          ))
                                      .toList(),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OverviewScreen(title_filename: item),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
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
}
