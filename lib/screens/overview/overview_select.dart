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
  late List<Map<String, String>> title_filenames;
  Offset? _tapPosition;

  void initState() {
    super.initState();
    setState(() {
      title_filenames = globals.title_filenames;
    });
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
  Future<void> _showMenu(int index) async {
    final screenSize = MediaQuery.of(context).size;
    final dx = screenSize.width - 300; // 画面右寄りに固定（右端から10px内側）
    double dy = _tapPosition!.dy; // 指の位置より20px下

    // 画面下端より下に行かないように調整（メニュー高さ約100と想定）
    if (dy + 100 > screenSize.height) {
      dy = _tapPosition!.dy - 100;
      if (dy < 0) dy = 0;
    }

    // 変数selectedをshowMenuへの操作から取得
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(dx, dy, 10, screenSize.height - dy),
      color: Colors.white,
      // 背景色白
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 角丸
      ),
      items: [
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

    if (selected == 'share') {
      await shareFile(context, title_filenames[index]['filename'] ?? '');
    } else if (selected == 'upload') {
      // 公開前に確認ダイアログ
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
        uploadProblemSetWithReset(
          title_filenames[index]["title"]!,
          title_filenames[index]["filename"]!,
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
        await deleteFile(
          title_filenames[index]['filename'] ?? '',
        ); //ローカルディレクトリから該当ファイルを削除
        setState(() {
          globals.title_filenames.removeAt(
            index,
          ); //title_filenamesから該当問題セットを削除。globalsを置き換え
          title_filenames = List.from(
            globals.title_filenames,
          ); //削除後のglobals.title_filenamesを呼び出し
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
      body: ListView.builder(
        itemCount: title_filenames.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: _storePosition,
            onLongPress: () => _showMenu(index),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(color: Color(0xFFFFE6CA)),
              child: ListTile(
                key: ValueKey(title_filenames[index]["filename"]),
                dense: true,
                minVerticalPadding: 28,
                contentPadding: EdgeInsets.symmetric(horizontal: 48),

                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title_filenames[index]["title"].toString(),
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      updatedAtTrans(
                        title_filenames[index]['updatedAt'].toString(),
                      ),
                      style: TextStyle(color: Colors.grey[900], fontSize: 12),
                    ),
                  ],
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OverviewScreen(
                            title_filename: title_filenames[index],
                          ),
                    ),
                  ).then((_) {
                    setState(() {}); // → globals.title_filenamesが更新された内容で再描画される
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
