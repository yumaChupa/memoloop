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

/// 出題順サイクルボタン（listen_select, flashcard_selectで共通）
/// タップするたびに index順 → ミス順 → ランダム → index順 と循環する
Widget buildOrderChipBar({
  required Color accentColor,
  required VoidCallback onChanged,
}) {
  final IconData icon;
  switch (globals.currentOrder) {
    case globals.QuizOrder.original:
      icon = Icons.format_list_numbered;
      break;
    case globals.QuizOrder.wrongFirst:
      icon = Icons.priority_high;
      break;
    case globals.QuizOrder.random:
      icon = Icons.shuffle;
      break;
  }

  return Padding(
    padding: const EdgeInsets.only(right: 16),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        switch (globals.currentOrder) {
          case globals.QuizOrder.original:
            globals.currentOrder = globals.QuizOrder.wrongFirst;
            break;
          case globals.QuizOrder.wrongFirst:
            globals.currentOrder = globals.QuizOrder.random;
            break;
          case globals.QuizOrder.random:
            globals.currentOrder = globals.QuizOrder.original;
            break;
        }
        onChanged();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: accentColor),
      ),
    ),
  );
}

/// Q/A 切り替えモードボタン（listen_select, flashcard_selectで共通）
/// アクティブ時はアクセントカラー、非アクティブ時はグレー
Widget buildSwitchModeButton({
  required Color accentColor,
  required VoidCallback onChanged,
}) {
  final isActive = globals.switchMode;
  return Padding(
    padding: const EdgeInsets.only(right: 4),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        globals.switchMode = !globals.switchMode;
        onChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.swap_horiz,
          size: 22,
          color: isActive ? accentColor : Colors.grey[500],
        ),
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
