import 'package:flutter/material.dart';
import 'package:memoloop/utils/functions.dart';

class Create extends StatefulWidget {
  late final Map<String, dynamic> title_filename;

  Create({required this.title_filename});

  @override
  State<Create> createState() => _CreateState();
}

class _CreateState extends State<Create> {
  final TextEditingController _controllerJap = TextEditingController();
  final TextEditingController _controllerEng = TextEditingController();

  late final String filename;
  late List<Map<String, dynamic>> contents = [];

  @override
  void initState() {
    super.initState();
    filename = widget.title_filename["filename"];
    loadJson(filename).then((data) {
      contents = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
         updateAndSortByDate(widget.title_filename);
        saveContents(contents, widget.title_filename["filename"]);
        return;
      },

      child: Scaffold(
        appBar: AppBar(title: Text(widget.title_filename["title"])),
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Center(
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                //　日本語フレーズの入力窓
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF3E80ED), width: 6),
                  ),
                  child: TextFormField(
                    minLines: 1,    // 初期1行
                    maxLines: 5,    // 最大5行まで拡張
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    controller: _controllerJap,
                    decoration: const InputDecoration(
                      hintText: "日本語フレーズ",
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // 英語フレーズの入力窓
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF3E80ED), width: 6),
                  ),
                  child: TextFormField(
                    minLines: 1,    // 初期1行
                    maxLines: 5,    // 最大5行まで拡張
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    controller: _controllerEng,
                    decoration: const InputDecoration(
                      hintStyle: TextStyle(color: Colors.black54),
                      hintText: "English phrase",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    final newItem = {
                      "index": contents.length + 1,
                      "Japanese": _controllerJap.text,
                      "English": _controllerEng.text,
                      "done": 0,
                      "more": 0,
                    };
                    setState(() {
                      contents.add(newItem);
                      _controllerJap.text = "";
                      _controllerEng.text = "";
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                    child: const Text(
                      "作成",
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
