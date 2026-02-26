import 'package:flutter/material.dart';
import 'listen_screen.dart';
import 'package:memoloop/globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/constants.dart';
import 'package:memoloop/widgets/common_widgets.dart';

class ListenSelect extends StatefulWidget {
  @override
  State<ListenSelect> createState() => _ListenSelectState();
}

class _ListenSelectState extends State<ListenSelect> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  List<Map<String, dynamic>> get _filteredTitleFilenames =>
      filterTitleFilenames(
        source: globals.titleFilenames,
        searchQuery: _searchQuery,
        selectedTag: _selectedTag,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio"),
        scrolledUnderElevation: 0.2,
        actions: [
          buildSwitchModeButton(
            accentColor: AppColors.listenAccent,
            onChanged: () => setState(() {}),
          ),
          buildOrderChipBar(
            accentColor: AppColors.listenAccent,
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
              accentColor: AppColors.listenAccent,
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
                          accentColor: AppColors.listenAccent,
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
                                  builder: (context) => ListenScreen(titleFilename: item),
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
