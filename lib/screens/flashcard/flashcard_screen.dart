// 1. Dart標準ライブラリ
import 'dart:async';

// 2. Flutter SDKのパッケージ
import 'package:flutter/material.dart';

// 3. サードパーティパッケージ
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

// 4. プロジェクト内部のパッケージ
import '../../globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/screens/create/create_screen.dart';
import 'package:memoloop/constants.dart';

// ステートフル
class FlashCard extends StatefulWidget {
  final Map<String, dynamic> titleFilename;

  FlashCard({required this.titleFilename});

  @override
  State<FlashCard> createState() => _FlashCardState();
}

/////////////////
//   ステート
/////////////////
class _FlashCardState extends State<FlashCard> {
  //////////////////////////
  ////////変数の宣言//////////
  //////////////////////////
  final controller = CardSwiperController();

  //画面全体
  List<bool> showAnswer = [];
  bool finished = false;
  int currentIndex = 0;
  bool isSwipable = false;
  List<Map<String, dynamic>> contents = [];

  //　タイマー表示・時間計測
  late DateTime startTime;
  Duration elapsed = Duration.zero;
  late Timer timer;

  //正答率表示
  double accuracy = 0;
  Duration answerDuration = Duration.zero;
  int countCorrect = 0;
  late String durationStr;
  late String accuracyStr;

  ///////////////////
  // ライフサイクル///
  ///////////////////
  @override
  void initState() {
    super.initState();
    loadJson(widget.titleFilename["filename"]).then((data) {
      setState(() {
        ////  出題順を変更（badが多い順、次にgoodが少ない順） ////
        contents = List<Map<String, dynamic>>.from(data);
        switch (globals.currentOrder) {
          case globals.QuizOrder.original:
            contents.sort((a, b) {
              int aIndex = a["index"];
              int bIndex = b["index"];
              return bIndex.compareTo(aIndex); // 降順（最近登録したものを先頭に）
            });
            break;
          case globals.QuizOrder.wrongFirst:
            contents.sort((a, b) {
              int aTotal = a["bad"] + a["good"];
              int bTotal = b["bad"] + b["good"];
              double aAcc = a["good"] / (a["good"] + a["bad"] + 1);
              double bAcc = b["good"] / (b["good"] + b["bad"] + 1);

              int cmp = aAcc.compareTo(bAcc);
              if (cmp != 0) return cmp;
              return aTotal.compareTo(bTotal);
            });
            break;
          case globals.QuizOrder.random:
            contents.shuffle();
            break;
        }
        showAnswer = List.filled(contents.length, false);
      });
    });

    /////////　画面端にタイマー表示
    startTime = DateTime.now();
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        elapsed = DateTime.now().difference(startTime);
      });
    });

    /// 正答率
    countCorrect = 0;
  }

  @override
  void dispose() {
    controller.dispose();
    timer.cancel();
    super.dispose();
  }

  ////////////////////
  /////// ロジック//////
  ////////////////////
  //スワイプ時の処理
  bool handleSwipe(int? prev, int? curr, CardSwiperDirection dir) {
    // 1枚目の時prevがnullなので、その時だけはじく。
    if (prev == null) return false;
    setState(() {
      if (dir == CardSwiperDirection.left) {
        contents[prev]['good'] += 1;
        countCorrect += 1;
      } else if (dir == CardSwiperDirection.right) {
        contents[prev]['bad'] += 1;
      }
      showAnswer[prev] = false;
      isSwipable = false;
    });
    return true;
  }

  //  「もう一度」でリセット
  void resetCards() {
    setState(() {
      showAnswer = List.filled(contents.length, false);
      finished = false;
      startTime = DateTime.now();
      countCorrect = 0;
      Duration elapsed = Duration.zero;
    });
    controller.moveTo(0);
  }

  //数値→文字列の形式の調整
  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) {
      return '${d.inSeconds % 60}s';
    } else {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }
  }

  String _formatAccuracy(double a) {
    return accuracyStr = (a * 100).toStringAsFixed(1) + '%';
  }

  ////////////////////
  // UI（メイン画面） //
  ////////////////////

  /// カードスワイパー部分
  Widget _buildCardSwiper() {
    return Container(
      height: 500,
      padding: EdgeInsets.only(top: 140),
      child: CardSwiper(
        controller: controller,
        cardsCount: contents.length,
        maxAngle: 10,
        isLoop: false,
        scale: 0.9,
        duration: Duration(milliseconds: 60),
        isDisabled: !isSwipable,
        onSwipe: handleSwipe,
        onEnd: () async {
          setState(() {
            finished = true;
            answerDuration = DateTime.now().difference(startTime);
            accuracy =
                contents.isEmpty
                    ? 0.0
                    : countCorrect / contents.length;
          });
          await saveContents(
            contents,
            widget.titleFilename["filename"],
          );
          // 統計情報を更新
          if (contents.isNotEmpty) {
            final prevCount = (widget.titleFilename['completionCount'] ?? 0) as int;
            final newCount = prevCount + 1;
            final newAvg = answerDuration.inSeconds / contents.length;
            widget.titleFilename['completionCount'] = newCount;
            widget.titleFilename['avgTimePerQuestion'] = newAvg;
            await saveTitleFilenames();
          }
        },
        numberOfCardsDisplayed:
            contents.isEmpty
                ? 1
                : (contents.length < 3 ? contents.length : 3),
        cardBuilder: (context, index, percentX, percentY) {
          currentIndex = index;
          final card = contents[index];
          // デフォルト: Question（日本語）を表示し Answer（英語）をタップで表示
          // switchMode ON: Answer（英語）を先に表示し Question（日本語）をタップで表示
          final promptText = globals.switchMode
              ? card['Answer'].toString()
              : card['Question'].toString();
          final revealText = globals.switchMode
              ? card['Question'].toString()
              : card['Answer'].toString();
          return GestureDetector(
            onTap: () {
              setState(() {
                showAnswer[index] = !showAnswer[index];
                if (!isSwipable) isSwipable = true;
              });
            },
            child: Card(
              color: Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: AppColors.flashcardAccent, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 30,
                        left: 0,
                        child: Text(
                          "${card['index']}.",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        right: 10,
                        child: Text("${index + 1}/${contents.length}"),
                      ),
                      Positioned(
                        top: 90,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promptText,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                            showAnswer[index]
                                ? Text(
                                  revealText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                                : SizedBox(height: 20),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 250,
                        right: 10,
                        child: Text(
                          'Correct: ${card['good']}   Wrong: ${card['bad']}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 結果表示部分
  Widget _buildResultView() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "結果",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text("正解数: $countCorrect", style: TextStyle(fontSize: 24)),
              SizedBox(height: 12),
              Text("正答率: ${_formatAccuracy(accuracy)}", style: TextStyle(fontSize: 24)),
              SizedBox(height: 12),
              Text("タイム: ${_formatDuration(answerDuration)}", style: TextStyle(fontSize: 24)),
              SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        minimumSize: Size.fromHeight(60),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.home_outlined),
                      label: Text('ホームに戻る'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.flashcardMain,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: resetCards,
                      icon: Icon(Icons.refresh),
                      label: Text('もう一度'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // contentsがからの時
    if (contents.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.titleFilename["title"]),
          scrolledUnderElevation: 0.2,
        ),
        body: Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.flashcardMain,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                          Create(titleFilename: widget.titleFilename),
                ),
              );
            },
            icon: Icon(Icons.add),
            label: const Text(
              '"create"で問題を作成',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        updateAndSortByDate(widget.titleFilename);
        saveContents(contents, widget.titleFilename["filename"]);
        setState(() {});
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titleFilename["title"]),
          scrolledUnderElevation: 0.2,
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline),
              tooltip: '使い方',
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        contentPadding: EdgeInsets.fromLTRB(6, 12, 6, 0),
                        backgroundColor: Colors.grey[50],
                        content: SizedBox(
                          // width: MediaQuery.of(context).size.width * 0.96,// 横幅を広げる
                          child: Image.asset('assets/img/usage_flashcard.png'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('閉じる'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (!finished) _buildCardSwiper(),
            if (!finished)
              Container(
                padding: EdgeInsets.all(40),
                child: Text(
                  '${_formatDuration(elapsed)}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            if (finished) _buildResultView(),
          ],
        ),
      ),
    );
  }
}
