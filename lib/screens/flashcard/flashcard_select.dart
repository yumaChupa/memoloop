import 'package:flutter/material.dart';
import 'flashcard_screen.dart';
import '../../globals.dart' as globals;
import '../../utils/functions.dart';
import 'package:memoloop/constants.dart';
import 'package:memoloop/widgets/common_widgets.dart';

class FlashCardSelect extends StatefulWidget {
  @override
  State<FlashCardSelect> createState() => _FlashCardSelectState();
}

class _FlashCardSelectState extends State<FlashCardSelect> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  List<Map<String, dynamic>> get _filteredTitleFilenames =>
      filterTitleFilenames(
        source: globals.titleFilenames,
        searchQuery: _searchQuery,
        selectedTag: _selectedTag,
      );

  String _formatAvgTime(dynamic seconds) {
    if (seconds == null || seconds == 0) return '-';
    final s = (seconds as num).toDouble();
    if (s < 60) return '${s.toStringAsFixed(1)}s/問';
    return '${(s / 60).toStringAsFixed(1)}m/問';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcard"),
        scrolledUnderElevation: 0.2,
        actions: [
          buildSwitchModeButton(
            accentColor: AppColors.flashcardAccent,
            onChanged: () => setState(() {}),
          ),
          buildOrderChipBar(
            accentColor: AppColors.flashcardAccent,
            onChanged: () => setState(() {}),
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
              accentColor: AppColors.flashcardAccent,
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
                          accentColor: AppColors.flashcardAccent,
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
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.replay, size: 13, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item['completionCount'] ?? 0}回',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.timer_outlined, size: 13, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatAvgTime(item['avgTimePerQuestion']),
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.quiz_outlined, size: 13, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item['questionCount'] ?? 0}問',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FlashCard(titleFilename: item),
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
