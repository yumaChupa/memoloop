// 1. Dart標準ライブラリ
import 'dart:convert';
import 'dart:io';

// 2. Flutter SDKのパッケージ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// 3. サードパーティパッケージ
import 'package:path_provider/path_provider.dart';

// 4. プロジェクト内部のパッケージ
// import '../../globals.dart' as globals;
import '../../utils/functions.dart';
import 'package:memoloop/screens/create/create_screen.dart';

class OverviewScreen extends StatefulWidget {
  final Map<String, dynamic> title_filename;

  OverviewScreen({required this.title_filename});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

//　ステート、問題一覧の表示
class _OverviewScreenState extends State<OverviewScreen> {
  List<Map<String, dynamic>> contents = [];
  late String filename;

  // 初期化
  @override
  void initState() {
    super.initState();
    filename = widget.title_filename["filename"];
    loadJson(filename).then((data) {
      setState(() {
        contents = data;
      });
    });
  }

  //////////////
  // 問題の編集 //
  //////////////
  void showEditDialog(BuildContext context, int index) {
    final original = contents[index];
    TextEditingController japaneseController = TextEditingController(
      text: original["Japanese"],
    );
    TextEditingController englishController = TextEditingController(
      text: original["English"],
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[50],
            title: Text("フレーズを更新", style: TextStyle(fontSize: 20)),
            // タイトル非表示
            content: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SizedBox(
                width: 500,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: japaneseController,
                    decoration: InputDecoration(
                      labelText: '日本語',
                      labelStyle: TextStyle(color: Colors.black45),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: englishController,
                    decoration: InputDecoration(
                      labelText: 'English',
                      labelStyle: TextStyle(color: Colors.black45),
                    ),
                  ),
                ],
                ),
              ),
            ),

            //　「フレーズを削除」を押した時の確認ダイアログ
            actions: [
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey[50],
                        title: Text("確認", style: TextStyle(fontSize: 18)),
                        content: Text("このフレーズを消去しますか？"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text("キャンセル"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              "消去",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    saveContents(contents, filename);
                    contents.removeAt(index);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: Text("フレーズを削除", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    contents[index]["Japanese"] = japaneseController.text;
                    contents[index]["English"] = englishController.text;
                  });
                  Navigator.pop(context);
                },
                child: Text("変更を保存"),
              ),
            ],
          ),
    );
  }

  //////////////
  // 表示画面 //
  //////////////
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        updateAndSortByDate(widget.title_filename);
        saveContents(contents, widget.title_filename["filename"]);
        // return;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title_filename["title"] ?? ""),
          scrolledUnderElevation: 0.2,
        ),
        body:
            (contents.isEmpty)
                // contentsの中身がない時
                ? Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  Create(title_filename: widget.title_filename),
                        ),
                      );
                    },
                    child: const Text(
                      '"create"で問題を作成',
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                  ),
                )
                // contentsの中身がある時
                : ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = contents.removeAt(oldIndex);
                      contents.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (final item in contents)
                      ListTile(
                        key: ValueKey(item['index']),
                        minVerticalPadding: 0,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 0,
                        ),
                        onTap:
                            () =>
                                showEditDialog(context, contents.indexOf(item)),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                item["Japanese"] ?? "",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // SizedBox(height: 2),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                item["English"] ?? "",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Divider(
                              thickness: 1,
                              color: Colors.orange[900],
                              height: 1,
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
