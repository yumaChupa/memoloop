import 'package:cloud_functions/cloud_functions.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    filename = widget.titleFilename["filename"];
    _loadProblemSet();
  }

  /// Firebase初期化完了を待ってからCloud Functionsで問題セットを取得
  Future<void> _loadProblemSet() async {
    await globals.firebaseInitFuture;
    try {
      final data = await getProblemSet(filename);
      if (mounted) {
        setState(() {
          contents = data;
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'データ取得に失敗しました')),
        );
      }
    }
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
          'questionCount': contents.length,
          'isMine': false,
        };
        globals.titleFilenames.add(newItem);
        updateAndSortByDate(newItem);
        await saveContents(contents, filename);
        await globals.firebaseInitFuture;
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  for (final item in contents)
                    ListTile(
                      key: ValueKey(item['index']),
                      minVerticalPadding: 0,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 0,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              item["Answer"] ?? item["Japanese"] ?? "",
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              item["Question"] ?? item["English"] ?? "",
                              style: const TextStyle(fontSize: 18, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 10),
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
