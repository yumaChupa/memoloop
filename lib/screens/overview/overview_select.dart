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
      final editingTags = currentTags.toSet();
      final newTags = await showDialog<List<String>>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.grey[50],
            title: Text('タグ編集', style: TextStyle(fontSize: 18)),
            content: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: globals.availableTags.map((tag) {
                final isSelected = editingTags.contains(tag);
                return FilterChip(
                  label: Text(tag, style: TextStyle(fontSize: 13)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setDialogState(() {
                      if (selected) {
                        editingTags.add(tag);
                      } else {
                        editingTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Colors.orange[200],
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, editingTags.toList()),
                child: Text('保存'),
              ),
            ],
          ),
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
      if (item['isMine'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ダウンロードした問題セットは公開できません')),
        );
        return;
      }
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
        final remaining = await uploadProblemSetWithReset(
          item["title"]!.toString(),
          item["filename"]!.toString(),
          tags: tags,
        );
        if (remaining != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('アップロードの間隔が短すぎます。${remaining}秒後に再試行してください')),
          );
        }
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
                              color: isSelected ? Color(0xFFE8913A) : Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 24,
                            color: isSelected ? Color(0xFFE8913A) : Colors.transparent,
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
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: _storePosition,
                    onLongPress: () => _showMenu(item),
                    child: Container(
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
                              left: BorderSide(color: Color(0xFFE8913A), width: 4),
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
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                              ],
                            ),
                            subtitle: ((item['tags'] as List<dynamic>?)?.isNotEmpty == true)
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 6,
                                      children: (item['tags'] as List<dynamic>)
                                          .cast<String>()
                                          .map((tag) => Text(
                                                '#$tag',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFE8913A),
                                                  fontWeight: FontWeight.w500,
                                                ),
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
