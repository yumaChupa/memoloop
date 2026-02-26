import 'package:flutter/material.dart';
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/constants.dart';

class Create extends StatefulWidget {
  late final Map<String, dynamic> titleFilename;

  Create({required this.titleFilename});

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
    filename = widget.titleFilename["filename"];
    loadJson(filename).then((data) {
      contents = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
         updateAndSortByDate(widget.titleFilename);
        saveContents(contents, widget.titleFilename["filename"]);
        return;
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titleFilename["title"]),
          scrolledUnderElevation: 0.2,
        ),
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
                //　Questionの入力窓
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.createAccent, width: 4),
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
                    border: Border.all(color: AppColors.createAccent, width: 4),
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.createMain,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      final newItem = {
                        "index": contents.length + 1,
                        "Answer": _controllerJap.text,
                        "Question": _controllerEng.text,
                        "good": 0,
                        "bad": 0,
                      };
                      setState(() {
                        contents.add(newItem);
                        _controllerJap.text = "";
                        _controllerEng.text = "";
                      });
                      saveContents(contents, filename);
                    },
                    icon: Icon(Icons.add),
                    label: const Text("作成"),
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
