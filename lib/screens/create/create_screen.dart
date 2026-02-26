import 'package:flutter/material.dart';
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/constants.dart';
import 'package:memoloop/globals.dart' as globals;

class Create extends StatefulWidget {
  late final Map<String, dynamic> titleFilename;

  Create({required this.titleFilename});

  @override
  State<Create> createState() => _CreateState();
}

class _CreateState extends State<Create> {
  // Question = Japanese（日本語）, Answer = English（英語フレーズ）
  final TextEditingController _controllerQuestion = TextEditingController();
  final TextEditingController _controllerAnswer = TextEditingController();

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
        // questionCount を更新してから保存（updateAndSortByDate 内で saveTitleFilenames が呼ばれるため先に更新）
        final idx = globals.titleFilenames.indexWhere(
          (item) => item['filename'] == widget.titleFilename['filename'],
        );
        if (idx != -1) {
          globals.titleFilenames[idx]['questionCount'] = contents.length;
        }
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
                // Question（日本語）の入力窓 — フラッシュカードで最初に表示される側
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.createAccent, width: 4),
                  ),
                  child: TextFormField(
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    controller: _controllerQuestion,
                    decoration: const InputDecoration(
                      hintText: "Question",
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Answer（英語フレーズ）の入力窓 — タップで表示される側
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.createAccent, width: 4),
                  ),
                  child: TextFormField(
                    minLines: 1,
                    maxLines: 5,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    controller: _controllerAnswer,
                    decoration: const InputDecoration(
                      hintStyle: TextStyle(color: Colors.black54),
                      hintText: "Answer",
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
                        "Question": _controllerQuestion.text,
                        "Answer": _controllerAnswer.text,
                        "good": 0,
                        "bad": 0,
                      };
                      setState(() {
                        contents.add(newItem);
                        _controllerQuestion.text = "";
                        _controllerAnswer.text = "";
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
