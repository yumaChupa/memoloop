import 'package:flutter/material.dart';
import 'overview_screen.dart';
import '../../globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/firebase_functions.dart';
import 'package:memoloop/constants.dart';
import 'package:memoloop/widgets/common_widgets.dart';

class OverviewSelect extends StatefulWidget {
  @override
  State<OverviewSelect> createState() => _OverviewSelectState();
}

class _OverviewSelectState extends State<OverviewSelect> {
  Offset? _tapPosition;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  List<Map<String, dynamic>> get _filteredTitleFilenames =>
      filterTitleFilenames(
        source: globals.titleFilenames,
        searchQuery: _searchQuery,
        selectedTag: _selectedTag,
      );

  ////////////////////////
  ///// ロジック /////
  ///////////////////////
  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  /// 長押しメニューの表示とルーティング
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(value: 'edit', child: Text('編集', style: TextStyle(fontWeight: FontWeight.bold))),
        PopupMenuItem(value: 'upload', child: Text('公開', style: TextStyle(fontWeight: FontWeight.bold))),
        PopupMenuItem(value: 'delete', child: Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ],
    );

    if (selected == 'edit') {
      await _showEditDialog(item);
    } else if (selected == 'upload') {
      await _showUploadDialog(item);
    } else if (selected == 'delete') {
      await _showDeleteDialog(item);
    }
  }

  /// 編集ダイアログ（タイトル＋タグ）
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final titleController = TextEditingController(text: item['title']?.toString() ?? '');
    final currentTags = (item['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final editingTags = currentTags.toSet();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('編集', style: TextStyle(fontSize: 18)),
          content: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    child: TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'タイトルを入力',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      final isSelected = editingTags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 13)),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setDialogState(() {
                            selected ? editingTags.add(tag) : editingTags.remove(tag);
                          });
                        },
                        selectedColor: Colors.orange[200],
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('キャンセル')),
            TextButton(
              onPressed: () {
                final newTitle = titleController.text.trim();
                if (newTitle.isEmpty) return;
                Navigator.pop(context, {'title': newTitle, 'tags': editingTags.toList()});
              },
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        item['title'] = result['title'];
        item['tags'] = result['tags'];
      });
      await saveTitleFilenames();
    }
  }

  /// 公開ダイアログ
  Future<void> _showUploadDialog(Map<String, dynamic> item) async {
    if (item['isMine'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('他者が作成した問題セットは公開できません')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('確認'),
        content: Text('この問題セットを公開しますか？\n再度公開することで内容を更新できます'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('公開')),
        ],
      ),
    );

    if (confirmed == true) {
      await globals.firebaseInitFuture; // Firebase初期化完了を保証
      final tags = (item['tags'] as List<dynamic>?)?.cast<String>() ?? [];
      final remaining = await uploadProblemSetWithReset(
        item["title"]!.toString(),
        item["filename"]!.toString(),
        tags: tags,
      );
      if (remaining != null) {
        final message = remaining == -1
            ? '問題数が$maxQuestionCount問を超えています。公開できる問題数は$maxQuestionCount問までです'
            : remaining == -2
                ? '本日のアクセス上限に達しました。明日再度お試しください'
                : 'アップロードの間隔が短すぎます。$remaining秒後に再試行してください';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  /// 削除ダイアログ
  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[50],
        title: Text('削除確認'),
        content: Text('この問題セットを削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('キャンセル')),
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
        globals.titleFilenames.removeWhere((e) => e['filename'] == item['filename']);
      });
      await saveTitleFilenames();
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
              accentColor: AppColors.overviewAccent,
              onTagSelected: (tag) => setState(() => _selectedTag = tag),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _filteredTitleFilenames[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: _storePosition,
                          onLongPress: () => _showMenu(item),
                          child: buildSelectListItem(
                            accentColor: AppColors.overviewAccent,
                            child: ListTile(
                              key: ValueKey(item["filename"]),
                              dense: true,
                              minVerticalPadding: 16,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  const SizedBox(width: 8),
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
                                                    color: AppColors.overviewAccent,
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
                                    builder: (context) => OverviewScreen(titleFilename: item),
                                  ),
                                ).then((_) => setState(() {}));
                              },
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
