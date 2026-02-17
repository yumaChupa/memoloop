import 'package:flutter/material.dart';
import 'package:memoloop/globals.dart' as globals;

/// 検索バー（5つのselectファイルで共通）
Widget buildSearchTextField({
  required TextEditingController controller,
  required String searchQuery,
  required ValueChanged<String> onChanged,
  required VoidCallback onClear,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: '検索...',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        ),
        onChanged: onChanged,
      ),
    ),
  );
}

/// タグフィルターバー（5つのselectファイルで共通）
Widget buildTagFilterBar({
  required String? selectedTag,
  required Color accentColor,
  required ValueChanged<String?> onTagSelected,
}) {
  return SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: globals.availableTags.map((tag) {
        final isSelected = selectedTag == tag;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => onTagSelected(isSelected ? null : tag),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? accentColor : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: 24,
                  color: isSelected ? accentColor : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

/// リストアイテムの外枠（5つのselectファイルで共通）
/// [child]にListTileを渡す
Widget buildSelectListItem({
  required Color accentColor,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// 出題順チップバー（listen_select, flashcard_selectで共通）
Widget buildOrderChipBar({
  required Color accentColor,
  required VoidCallback onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSingleOrderChip(
            order: globals.QuizOrder.original,
            icon: Icons.sort_by_alpha,
            accentColor: accentColor,
            onChanged: onChanged,
          ),
          _buildSingleOrderChip(
            order: globals.QuizOrder.wrongFirst,
            icon: Icons.priority_high,
            accentColor: accentColor,
            onChanged: onChanged,
          ),
          _buildSingleOrderChip(
            order: globals.QuizOrder.random,
            icon: Icons.shuffle,
            accentColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    ),
  );
}

Widget _buildSingleOrderChip({
  required globals.QuizOrder order,
  required IconData icon,
  required Color accentColor,
  required VoidCallback onChanged,
}) {
  final isActive = globals.currentOrder == order;
  return GestureDetector(
    onTap: () {
      globals.currentOrder = order;
      onChanged();
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? accentColor : Colors.transparent,
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

/// タイトルFilenamesのフィルタリング（5つのselectファイルで共通ロジック）
List<Map<String, dynamic>> filterTitleFilenames({
  required List<Map<String, dynamic>> source,
  required String searchQuery,
  required String? selectedTag,
}) {
  var list = source.toList();
  if (searchQuery.isNotEmpty) {
    list = list.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      return title.contains(searchQuery.toLowerCase());
    }).toList();
  }
  if (selectedTag != null) {
    list = list.where((item) {
      final tags = (item['tags'] as List<dynamic>?)?.cast<String>() ?? [];
      return tags.contains(selectedTag);
    }).toList();
  }
  return list;
}
