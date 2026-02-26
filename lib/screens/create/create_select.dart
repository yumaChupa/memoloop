import 'package:flutter/material.dart';
import 'package:memoloop/globals.dart' as globals;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'create_screen.dart';
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/constants.dart';
import 'package:memoloop/widgets/common_widgets.dart';

class CreateSelect extends StatefulWidget {
  @override
  State<CreateSelect> createState() => _CreateSelectState();
}

class _CreateSelectState extends State<CreateSelect> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  List<Map<String, dynamic>> get _filteredTitleFilenames =>
      filterTitleFilenames(
        source: globals.titleFilenames,
        searchQuery: _searchQuery,
        selectedTag: _selectedTag,
      );

  /// 新規問題セット作成ダイアログ
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
            child: SizedBox(
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
                      final isSelected = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 13)),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setDialogState(() {
                            selected ? selectedTags.add(tag) : selectedTags.remove(tag);
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            TextButton(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  final filename = _generateFilename(title);
                  final newItem = <String, dynamic>{
                    "title": title,
                    "filename": filename,
                    "updatedAt": DateTime.now().toIso8601String(),
                    "tags": selectedTags.toList(),
                    "isMine": true,
                  };

                  setState(() {
                    globals.titleFilenames.add(newItem);
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

  /// タイトルからファイル名（スラッグ＋ハッシュ）を生成
  String _generateFilename(String title) {
    final slug = title
        .replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '')
        .replaceAll(RegExp(r'[/\.\s]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final truncatedSlug = slug.length > 20 ? slug.substring(0, 20) : slug;
    final shortHash = md5
        .convert(utf8.encode(title + globals.deviceUuid))
        .toString()
        .substring(0, 8);
    return '${truncatedSlug}_$shortHash';
  }

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
              accentColor: AppColors.createAccent,
              onTagSelected: (tag) => setState(() => _selectedTag = tag),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _filteredTitleFilenames[index];
                        return buildSelectListItem(
                          accentColor: AppColors.createAccent,
                          child: ListTile(
                            key: ValueKey(item["filename"]),
                            dense: true,
                            minVerticalPadding: 20,
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Create(titleFilename: item),
                                ),
                              ).then((_) => setState(() {}));
                            },
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
