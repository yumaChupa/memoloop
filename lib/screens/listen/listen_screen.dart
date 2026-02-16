import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:memoloop/globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/tts_function.dart';

enum AudioState { idle, loading, playing, stopping }

class ListenScreen extends StatefulWidget {
  final Map<String, dynamic> titleFilename;

  const ListenScreen({super.key, required this.titleFilename});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  ////////////////////////
  ///// 1.変数定義 /////
  ///////////////////////
  int currentIndex = -1;
  AudioState _audioState = AudioState.idle;
  String displayedText = "";
  List<Map<String, dynamic>> contents = [];
  AudioPlayer? _currentPlayer;

  ////////////////////////
  ///// 2.ライフサイクル /////
  ///////////////////////
  @override
  void initState() {
    super.initState();
    loadJson(widget.titleFilename["filename"]).then((data) {
      setState(() {
        contents = List<Map<String, dynamic>>.from(data);
        switch (globals.currentOrder) {
          case globals.QuizOrder.original:
            contents.sort((a, b) => a["index"].compareTo(b["index"]));
            break;
          case globals.QuizOrder.wrongFirst:
            contents.sort((a, b) {
              int aTotal = a["bad"] + a["good"];
              int bTotal = b["bad"] + b["good"];
              double aAcc = a["good"] / (aTotal + 1);
              double bAcc = b["good"] / (bTotal + 1);

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

  @override
  void dispose() {
    _currentPlayer?.dispose();
    super.dispose();
  }

  ////////////////////////
  ///// 3.ロジック /////
  ///////////////////////
  Future<void> _speakSequence() async {
    bool finished = false;

    for (int i = currentIndex + 1; i < contents.length; i++) {
      if (_audioState == AudioState.stopping || !mounted) break;

      final textQuestion = contents[i]["Question"].toString();
      final textAnswer = contents[i]["Answer"].toString();

      if (mounted) {
        setState(() {
          currentIndex = i;
          displayedText = "";
          _audioState = AudioState.loading;
        });
      }

      // 新しいPlayerを作成し、外部停止を可能にする
      _currentPlayer?.dispose();
      _currentPlayer = AudioPlayer();

      try {
        if (_audioState == AudioState.stopping || !mounted) break;

        if (mounted) {
          setState(() => _audioState = AudioState.playing);
        }

        await speakText(textAnswer, player: _currentPlayer!);
      } catch (_) {
        // 停止やdisposeによるエラーは無視して抜ける
        if (_audioState == AudioState.stopping || !mounted) break;
        rethrow;
      }

      if (_audioState == AudioState.stopping || !mounted) break;

      if (mounted) {
        setState(() {
          displayedText = textQuestion;
        });
      }

      // 2.5秒待機（停止時は即座に抜ける）
      for (int ms = 0; ms < 25; ms++) {
        if (_audioState == AudioState.stopping || !mounted) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (i == contents.length - 1) {
        finished = true;
      }
    }

    _currentPlayer?.dispose();
    _currentPlayer = null;

    if (mounted) {
      setState(() {
        _audioState = AudioState.idle;
        if (finished) {
          currentIndex = -1;
          displayedText = "";
        }
      });
    }
  }

  Future<void> _start() async {
    if (_audioState != AudioState.idle) return;
    if (contents.isEmpty) return;

    setState(() {
      _audioState = AudioState.loading;
    });

    await _speakSequence();
  }

  Future<void> _stop() async {
    if (_audioState == AudioState.idle || _audioState == AudioState.stopping) return;

    setState(() {
      _audioState = AudioState.stopping;
    });

    // 再生中のオーディオを即座に停止
    try {
      await _currentPlayer?.stop();
    } catch (_) {}
  }

  void _onButtonPressed() {
    if (_audioState == AudioState.idle) {
      _start();
    } else if (_audioState == AudioState.playing) {
      _stop();
    }
    // loading, stopping 時はボタン無効
  }

  ////////////////
  ///// 4.UI /////
  ////////////////
  @override
  Widget build(BuildContext context) {
    int displayIndex = max(0, currentIndex);

    // ボタンの表示状態を決定
    final bool buttonEnabled = _audioState == AudioState.idle || _audioState == AudioState.playing;
    final bool isIdle = _audioState == AudioState.idle;
    final bool isLoading = _audioState == AudioState.loading;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (_audioState != AudioState.idle) {
          await _stop();
        }
        updateAndSortByDate(widget.titleFilename);
        saveContents(contents, widget.titleFilename["filename"]);
        setState(() {});
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titleFilename["title"]),
          scrolledUnderElevation: 0.2,
        ),
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIdle ? Color(0xFF9B59B6) : Colors.grey[300],
                      foregroundColor: isIdle ? Colors.white : Colors.black87,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: buttonEnabled ? _onButtonPressed : null,
                    icon: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[400],
                            ),
                          )
                        : Icon(isIdle ? Icons.play_arrow : Icons.stop),
                    label: Text(isIdle ? '再生' : isLoading ? '読み込み中...' : _audioState == AudioState.stopping ? '停止中...' : '停止'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
