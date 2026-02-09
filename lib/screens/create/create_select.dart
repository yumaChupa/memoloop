import 'package:flutter/material.dart';
import 'package:memoloop/globals.dart' as globals;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'create_screen.dart';
import 'package:memoloop/utils/functions.dart'; // saveTitleFilenames()を定義

class createSelect extends StatefulWidget {
  @override
  State<createSelect> createState() => _createSelectState();
}

class _createSelectState extends State<createSelect> {
  //////////////////
  ///// 変数定義 /////
  //////////////////
  late List<Map<String, String>> title_filenames = globals.title_filenames;

  ////////////////////////
  ///// ライフサイクル /////
  ///////////////////////

  ////////////////////
  ///// ロジック /////
  ///////////////////
  //新規問題セット作成
  void _showAddDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[50],
            title: const Text('新しい問題セット作成', style: TextStyle(fontSize: 18)),
            content: Container(
              width: 560,
              color: Colors.white,
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'タイトルを入力',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  border: InputBorder.none,
                  // filled: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: TextStyle(fontSize: 16),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  final title = controller.text.trim();
                  if (title.isNotEmpty) {
                    final filename = md5.convert(utf8.encode(title+globals.uuid)).toString();
                    final update_now = DateTime.now().toIso8601String();

                    final newItem = {
                      "title": title,
                      "filename": filename,
                      "updatedAt": update_now,
                    };

                    setState(() {
                      globals.title_filenames.add(newItem);
                    });

                    createNewfile(filename);
                    updateAndSortByDate(newItem);  //最終更新でソート

                    setState(() {});
                  }
                  Navigator.pop(context);
                },
                child: const Text('作成'),
              ),
            ],
          ),
    );
  }

  ///////////////////
  /////// UI ///////
  ///////////////////
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
      body: ListView.builder(
        itemCount: title_filenames.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: Color(0xFFC5DBF7)),
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
                        (context) =>
                            Create(title_filename: title_filenames[index]),
                  ),
                ).then((_) {
                  setState(() {}); // → globals.title_filenamesが更新された内容で再描画される
                });
              },
            ),
          );
        },
      ),
    );
  }
}
