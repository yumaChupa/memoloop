import 'package:flutter/material.dart';
import '../../globals.dart' as globals;
import '../../utils/functions.dart';
import '../../utils/firebase_functions.dart';
import 'package:memoloop/constants.dart';

class AddScreen extends StatefulWidget {
  final Map<String, dynamic> titleFilename;

  AddScreen({required this.titleFilename});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  late List<Map<String, dynamic>> contents = [];
  late String filename;

  @override
  void initState() {
    super.initState();

    filename = widget.titleFilename["filename"];
    getProblemSet(filename).then((data) async {
      setState(() {
        contents = data;
      });
    });

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
      final newFilename = widget.titleFilename['filename'].toString();
      final exists = globals.titleFilenames.any(
        (e) => e['filename'] == newFilename,
      );
      if (exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("すでに追加されています")));
      } else {
        final newItem = <String, dynamic>{
          'title': widget.titleFilename['title']?.toString() ?? '',
          'filename': widget.titleFilename['filename']?.toString() ?? '',
          'updatedAt': widget.titleFilename['updatedAt']?.toString() ?? '',
          'tags': (widget.titleFilename['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[],
          'isMine': false,
        };
        globals.titleFilenames.add(newItem);
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
        updateAndSortByDate(widget.titleFilename);
        saveContents(contents, widget.titleFilename["filename"]);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titleFilename["title"] ?? ""),
          scrolledUnderElevation: 0.2,
          actions: [
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
                        item["Answer"] ?? item["Japanese"] ?? "",
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        item["Question"] ?? item["English"] ?? "",
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(thickness: 1, color: AppColors.addAccent, height: 1),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
