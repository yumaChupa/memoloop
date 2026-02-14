import 'dart:math';

import 'package:flutter/material.dart';

import 'package:memoloop/globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/tts_function.dart'; // speakText関数を含むファイル

class ListenScreen extends StatefulWidget {
  final Map<String, dynamic> title_filename;

  const ListenScreen({super.key, required this.title_filename});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  ////////////////////////
  ///// 1.変数定義 /////
  ///////////////////////
  int currentIndex = -1;
  bool isPlaying = false;
  String displayedText = "";
  List<Map<String, dynamic>> contents = [];

  ////////////////////////
  ///// 2.ライフサイクル /////
  ///////////////////////
  @override
  void initState() {
    super.initState();
    loadJson(widget.title_filename["filename"]).then((data) {
      setState(() {
        contents = List<Map<String, dynamic>>.from(data);
        switch (globals.currentOrder) {
          case globals.QuizOrder.original:
            contents.sort((a, b) => a["index"].compareTo(b["index"]));
            break;
          case globals.QuizOrder.wrongFirst:
            contents.sort((a, b) {
              int aTotal = a["more"] + a["done"];
              int bTotal = b["more"] + b["done"];
              double aAcc = a["done"] / (aTotal + 1);
              double bAcc = b["done"] / (bTotal + 1);

              int cmp = aAcc.compareTo(bAcc);
              return cmp != 0 ? cmp : aTotal.compareTo(bTotal);
            });
            break;
          case globals.QuizOrder.random:
            contents.shuffle();
            break;
        }
      });
    });
  }

  ////////////////////////
  ///// 3.ロジック /////
  ///////////////////////
  Future<void> _speakSequence() async {
    bool finished = false;

    for (int i = currentIndex + 1; i < contents.length; i++) {
      if (!isPlaying || !mounted) break;

      final textEn = contents[i]["English"].toString();
      final textJp = contents[i]["Japanese"].toString();

      if (mounted) {
        setState(() {
          currentIndex = i;
          displayedText = ""; // 読み上げ前にリセット
        });
      }

      await speakText(textJp); // Google Cloud TTS APIで読み上げ
      // await Future.delayed(const Duration(milliseconds: 0));  //delayなくてもawait終了待ってたら良いdelayに。

      if (mounted) {
        setState(() {
          displayedText = textEn;
        });
      }

      await Future.delayed(const Duration(milliseconds: 2500));

      if (i == contents.length - 1) {
        finished = true;
      }
    }

    if (mounted && finished) {
      setState(() {
        isPlaying = false;
        currentIndex = -1;
        displayedText = "";
      });
    }
  }

  Future<void> _start() async {
    if (isPlaying) return;
    if (contents.isEmpty) return;

    setState(() {
      isPlaying = true;
    });

    await _speakSequence();
  }

  void _stop() {
    // Google TTS APIの停止処理は非同期でないため不要
    setState(() {
      isPlaying = false;
      // currentIndex と displayedText は保持し再開可能に
    });
  }

  ////////////////
  ///// 4.UI /////
  ////////////////
  @override
  Widget build(BuildContext context) {
    int displayIndex = max(0, currentIndex);
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        updateAndSortByDate(widget.title_filename);
        saveContents(contents, widget.title_filename["filename"]);
        setState(() {});
        return;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title_filename["title"])),
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 160),
                Text("${displayIndex.toString()}/${contents.length}"),
                Container(
                  height: 260,
                  alignment: Alignment.center,
                  child: Text(
                    displayedText,
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF9B59B6),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _start,
                        child: const Text('再生'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: _stop,
                        child: const Text('停止'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
