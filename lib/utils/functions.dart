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
Future<List<Map<String, dynamic>>> loadJson(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final localFile = File('${dir.path}/$filename.json');

  // ファイルがなければ assets からコピー
  if (!await localFile.exists()) {
    final jsonStr = await rootBundle.loadString('assets/data/$filename.json');
    await localFile.writeAsString(jsonStr);
  }

  // ローカルから読み込み
  final jsonStr = await localFile.readAsString();
  final List<dynamic> data = jsonDecode(jsonStr);
  return List<Map<String, dynamic>>.from(data);
}



// 変更をローカルファイルに保存・反映
Future<void> saveContents(List<Map<String, dynamic>> contents, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename.json');

  final jsonStr = jsonEncode(contents);
  await file.writeAsString(jsonStr);
}


// title_filenamesを読み込み。アプリ起動時に動かす。
Future<void> loadTitleFilenames() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/title_filenames.json');

  if (await file.exists()) {
    // ファイルが存在する場合 → 読み込んでglobalsに代入
    final jsonStr = await file.readAsString();
    globals.title_filenames = List<Map<String, dynamic>>.from(
      (jsonDecode(jsonStr) as List).map((e) => Map<String, dynamic>.from(e)),
    );
    // 既存データのマイグレーション
    for (var item in globals.title_filenames) {
      if (!item.containsKey('tags')) {
        item['tags'] = <String>[];
      }
      if (!item.containsKey('completionCount')) {
        item['completionCount'] = 0;
      }
      if (!item.containsKey('avgTimePerQuestion')) {
        item['avgTimePerQuestion'] = 0.0;
      }
    }
  } else {
    // 初回起動時 → globalsの値を保存
    final jsonStr = jsonEncode(globals.title_filenames);
    await file.writeAsString(jsonStr);
  }
}

//title_filenamesの最終更新日時を更新
void updateAndSortByDate(title_filename) {
  final now = DateTime.now().toIso8601String();
  int index = globals.title_filenames.indexWhere((item) => item == title_filename);
  if (index==-1) {
    false;
  }else{
    globals.title_filenames[index]["updatedAt"] = now;
  }
  //最終更新日時でソート（降順）
  globals.title_filenames.sort((a, b) {
    final aDate = DateTime.tryParse(a["updatedAt"] ?? "") ?? DateTime(1970);
    final bDate = DateTime.tryParse(b["updatedAt"] ?? "") ?? DateTime(1970);
    return bDate.compareTo(aDate);
  });
  saveTitleFilenames();
}

// title_filenamesをローカルファイルに保存・反映
Future<void> saveTitleFilenames() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/title_filenames.json');

  final jsonStr = jsonEncode(globals.title_filenames);
  await file.writeAsString(jsonStr);
}

Future<void> createNewfile(filename) async{
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename.json');
  // 空の List<Map<String, dynamic>> を JSON 文字列にして書き込む
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
    String newJapanese,
    String newEnglish,
    ) {
  for (var item in quizList) {
    if (item['index'] == indexToEdit) {
      item['Japanese'] = newJapanese;
      item['English'] = newEnglish;
      break;
    }
  }
}


// 問題の追加
void addQuizItem(
    List<Map<String, dynamic>> quizList,
    String japanese,
    String english,
    ) {
  int nextIndex = quizList.isNotEmpty
      ? (quizList.map((e) => e['index'] as int).reduce((a, b) => a > b ? a : b) + 1)
      : 1;

  quizList.add({
    'index': nextIndex,
    'Japanese': japanese,
    'English': english,
    'done': 0,
    'more': 0,
  });
}

//問題セットの共有（作成した問題をファイルで保存するため）
Future<void> shareFile(BuildContext context, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/$filename.json';
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
  final file = File('${dir.path}/$filename.json');
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