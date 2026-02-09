// 1. Dart標準ライブラリ
import 'dart:convert';
import 'dart:io';

// 2. Flutter SDKのパッケージ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// 3. サードパーティパッケージ
import 'package:path_provider/path_provider.dart';

// 4. プロジェクト内部のパッケージ
import '../../globals.dart' as globals;
import '../../utils/functions.dart';
import '../../utils/firebase_functions.dart';
import 'package:memoloop/screens/create/create_screen.dart';

class AddScreen extends StatefulWidget {
  final Map<String, dynamic> title_filename;

  AddScreen({required this.title_filename});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  late List<Map<String, dynamic>> contents = [];
  late String filename;

  @override
  void initState() {
    super.initState();

    filename = widget.title_filename["filename"];
    getProblemSet(filename).then((data) async {
      setState(() {
        contents = data;
      });
    });

    printJsonFiles();
  }

  Future<void> printJsonFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      print('ディレクトリが存在しません: ${dir.path}');
      return;
    }

    final entities = dir.listSync();
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        print(entity.path);
      }
    }
    print("////////////////");
    print(globals.title_filenames);
    print("");
  }

  Future<void> showAddDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("問題セットをローカルに保存しますか"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("キャンセル"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("保存"),
              ),
            ],
          ),
    );

    if (added == true) {
      final newFilename = widget.title_filename['filename'].toString();
      final exists = globals.title_filenames.any(
        (e) => e['filename'] == newFilename,
      );
      if (exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("すでに追加されています")));
      } else {
        final newItem = <String, dynamic>{
          'title': widget.title_filename['title']?.toString() ?? '',
          'filename': widget.title_filename['filename']?.toString() ?? '',
          'updatedAt': widget.title_filename['updatedAt']?.toString() ?? '',
          'tags': (widget.title_filename['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[],
        };
        globals.title_filenames.add(newItem);
        updateAndSortByDate(newItem);
        await saveContents(contents, filename);
        await incrementDownloadCount(filename);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("問題セットを保存しました")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        updateAndSortByDate(widget.title_filename);
        saveContents(contents, widget.title_filename["filename"]);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title_filename["title"] ?? ""),
          scrolledUnderElevation: 0.2,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 2),
                  Text(
                    '${widget.title_filename['downloadCount'] ?? 0}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(icon: Icon(Icons.download), onPressed: showAddDialog),
          ],
        ),
        body: ListView(
          children: [
            for (final item in contents)
              ListTile(
                key: ValueKey(item['index']),
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 0,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        item["Japanese"] ?? "",
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        item["English"] ?? "",
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(thickness: 1, color: Colors.green, height: 1),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
