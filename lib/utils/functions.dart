import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:memoloop/globals.dart' as globals;

/////////////////
// データ処理系 ///
/////////////////
void _renameKey(Map<String, dynamic> map, String oldKey, String newKey) {
  if (map.containsKey(oldKey) && !map.containsKey(newKey)) {
    map[newKey] = map[oldKey];
    map.remove(oldKey);
  }
}

Future<List<Map<String, dynamic>>> loadJson(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final dataDir = Directory('${dir.path}/data');
  if (!await dataDir.exists()) {
    await dataDir.create(recursive: true);
  }
  final localFile = File('${dataDir.path}/$filename.json');

  // ファイルがなければ assets からコピー（キー変換付き）
  if (!await localFile.exists()) {
    final jsonStr = await rootBundle.loadString('assets/data/$filename.json');
    final List<dynamic> rawData = jsonDecode(jsonStr);
    for (var item in rawData) {
      if (item is Map<String, dynamic>) {
        _renameKey(item, 'Japanese', 'Answer');
        _renameKey(item, 'English', 'Question');
        _renameKey(item, 'done', 'good');
        _renameKey(item, 'more', 'bad');
      }
    }
    await localFile.writeAsString(jsonEncode(rawData));
  }

  // ローカルから読み込み（防御的にキー変換）
  final jsonStr = await localFile.readAsString();
  final List<dynamic> data = jsonDecode(jsonStr);
  final result = List<Map<String, dynamic>>.from(data);
  for (var item in result) {
    _renameKey(item, 'Japanese', 'Answer');
    _renameKey(item, 'English', 'Question');
    _renameKey(item, 'done', 'good');
    _renameKey(item, 'more', 'bad');
  }
  return result;
}



// 変更をローカルファイルに保存・反映
Future<void> saveContents(List<Map<String, dynamic>> contents, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/data/$filename.json');

  final jsonStr = jsonEncode(contents);
  await file.writeAsString(jsonStr);
}


// titleFilenamesを読み込み。アプリ起動時に動かす。
Future<void> loadTitleFilenames() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/title_filenames.json');

  if (await file.exists()) {
    // ファイルが存在する場合 → 読み込んでglobalsに代入
    final jsonStr = await file.readAsString();
    globals.titleFilenames = List<Map<String, dynamic>>.from(
      (jsonDecode(jsonStr) as List).map((e) => Map<String, dynamic>.from(e)),
    );
    // 既存データのマイグレーション
    for (var item in globals.titleFilenames) {
      if (!item.containsKey('tags')) {
        item['tags'] = <String>[];
      }
      if (!item.containsKey('completionCount')) {
        item['completionCount'] = 0;
      }
      if (!item.containsKey('avgTimePerQuestion')) {
        item['avgTimePerQuestion'] = 0.0;
      }
      if (!item.containsKey('isMine')) {
        item['isMine'] = false;
      }
    }
  } else {
    // 初回起動時 → globalsの値を保存
    final jsonStr = jsonEncode(globals.titleFilenames);
    await file.writeAsString(jsonStr);
  }
}

//titleFilenamesの最終更新日時を更新
void updateAndSortByDate(titleFilename) {
  final now = DateTime.now().toIso8601String();
  int index = globals.titleFilenames.indexWhere((item) => item == titleFilename);
  if (index==-1) {
    false;
  }else{
    globals.titleFilenames[index]["updatedAt"] = now;
  }
  //最終更新日時でソート（降順）
  globals.titleFilenames.sort((a, b) {
    final aDate = DateTime.tryParse(a["updatedAt"] ?? "") ?? DateTime(1970);
    final bDate = DateTime.tryParse(b["updatedAt"] ?? "") ?? DateTime(1970);
    return bDate.compareTo(aDate);
  });
  saveTitleFilenames();
}

// titleFilenamesをローカルファイルに保存・反映
Future<void> saveTitleFilenames() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/title_filenames.json');

  final jsonStr = jsonEncode(globals.titleFilenames);
  await file.writeAsString(jsonStr);
}

Future<void> createNewfile(filename) async{
  final dir = await getApplicationDocumentsDirectory();
  final dataDir = Directory('${dir.path}/data');
  if (!await dataDir.exists()) {
    await dataDir.create(recursive: true);
  }
  final file = File('${dataDir.path}/$filename.json');
  final emptyContent = jsonEncode(<Map<String, dynamic>>[]);
  await file.writeAsString(emptyContent);
}



// 問題1つを削除
void deleteQuizItem(List<Map<String, dynamic>> quizList, int indexToRemove) {
  quizList.removeWhere((item) => item['index'] == indexToRemove);
}


// 問題の編集
void editQuizItem(
    List<Map<String, dynamic>> quizList,
    int indexToEdit,
    String newAnswer,
    String newQuestion,
    ) {
  for (var item in quizList) {
    if (item['index'] == indexToEdit) {
      item['Answer'] = newAnswer;
      item['Question'] = newQuestion;
      break;
    }
  }
}


// 問題の追加
void addQuizItem(
    List<Map<String, dynamic>> quizList,
    String answer,
    String question,
    ) {
  int nextIndex = quizList.isNotEmpty
      ? (quizList.map((e) => e['index'] as int).reduce((a, b) => a > b ? a : b) + 1)
      : 1;

  quizList.add({
    'index': nextIndex,
    'Answer': answer,
    'Question': question,
    'good': 0,
    'bad': 0,
  });
}

//問題セットの共有（作成した問題をファイルで保存するため）
Future<void> shareFile(BuildContext context, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/data/$filename.json';
  final file = File(path);

  if (await file.exists()) {
    await Share.shareXFiles([XFile(file.path)], text: '共有ファイル: $filename');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ファイルが見つかりません: $filename.dart')),
    );
  }
}

// 問題ファイル削除関数
Future<void> deleteFile(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/data/$filename.json');
  if (await file.exists()) {
    await file.delete();
  }
}


String updatedAtTrans(String date){
  String datePart = date.split("T")[0]; // "2025-08-01"
  List<String> parts = datePart.split("-"); // ["2025", "08", "01"]
  String result = "${parts[0]} ${parts[1]}/${parts[2]}";
  return result;
}