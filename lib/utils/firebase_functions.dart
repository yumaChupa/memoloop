import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'package:memoloop/globals.dart' as globals;

final FirebaseFirestore firestore = FirebaseFirestore.instance;

// レート制限: 最後のアップロード時刻を保持
DateTime? _lastUploadTime;
const _uploadCooldown = Duration(seconds: 20);

////////////////////////////////////////////////
////// Firebaseから問題セットを取得して返す(filename→return question)
////////////////////////////////////////////////
Future<List<Map<String, dynamic>>> getProblemSet(String filename) async {
  // 1. 問題セット情報の取得
  final doc = await firestore.collection('sets').doc(filename).get();
  final data = doc.data();
  if (data == null) return [];

  // 3. questions取得
  final snapshot =
      await firestore
          .collection('sets')
          .doc(filename)
          .collection('questions')
          .get();
  final questions = snapshot.docs.map((doc) => doc.data()).toList();
  return questions;
}


////////////////////////////////////////////////
// ローカルの問題セットjsonをFirebaseにアップロード(return;)
////////////////////////////////////////////////
/// 問題セットをアップロード。レート制限に引っかかった場合は残り秒数を返す。
/// 容量制限超過時は -1 を返す。成功時はnull。
const int maxQuestionCount = 310;

Future<int?> uploadProblemSetWithReset(String title, String filename, {List<String> tags = const []}) async {
  // レート制限チェック
  if (_lastUploadTime != null) {
    final elapsed = DateTime.now().difference(_lastUploadTime!);
    if (elapsed < _uploadCooldown) {
      final remaining = _uploadCooldown.inSeconds - elapsed.inSeconds;
      return remaining;
    }
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename.json');

  if (!await file.exists()) return null;

  final jsonStr = await file.readAsString();
  final List<dynamic> questions = jsonDecode(jsonStr);

  // 容量制限チェック
  if (questions.length > maxQuestionCount) {
    return -1;
  }

  final now = DateTime.now().toIso8601String();

  final setRef = firestore.collection('sets').doc(filename);
  final questionsRef = setRef.collection('questions');

  // 1. 既存 questions コレクションを削除
  final existing = await questionsRef.get();
  final batchDelete = firestore.batch();
  for (var doc in existing.docs) {
    batchDelete.delete(doc.reference);
  }
  await batchDelete.commit();

  // 既存のdownloadCountを保持
  final existingDoc = await setRef.get();
  final existingData = existingDoc.data();
  final currentDownloads = existingData?['downloadCount'] ?? 0;

  // 2. sets コレクションに基本情報登録
  await setRef.set({
    'title': title,
    'filename': filename,
    'updatedAt': now,
    'tags': tags,
    'downloadCount': currentDownloads,
    'questionCount': questions.length,
  });

  // 3. questions 再アップロード（done/moreはローカル専用のため除外）
  final batchUpload = firestore.batch();
  for (var q in questions) {
    final cleaned = Map<String, dynamic>.from(q)
      ..remove('done')
      ..remove('more');
    final docRef = questionsRef.doc(cleaned['index'].toString());
    batchUpload.set(docRef, cleaned);
  }
  await batchUpload.commit();

  _lastUploadTime = DateTime.now();
  return null;
}


////////////////////////////////////////////////
// dbにある問題セットのタイトル、ファイル名をリストで取得(List<Map<String, dynamic>>
////////////////////////////////////////////////
Future<List<Map<String, dynamic>>> getSetsList() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('sets')
      .get();

  return querySnapshot.docs
      .map((doc) => doc.data())
      .toList();
}




////////////////////////////////////////////////
// ダウンロード数をインクリメント
////////////////////////////////////////////////
Future<void> incrementDownloadCount(String filename) async {
  try {
    final setRef = firestore.collection('sets').doc(filename);
    await setRef.update({
      'downloadCount': FieldValue.increment(1),
    });
  } catch (e) {
    print('Failed to increment download count: $e');
  }
}


//////////////////////////////////////////
/////初期化用、firestoreにデータ入れる用//////
//////////////////////////////////////////

// Firebaseの初期化（開発時一回のみ）
Future<void> firebaseInit(List<Map<String, dynamic>> titleFilenames) async {
  for (var titleFilename in titleFilenames) {
    await uploadFilesInit(titleFilename);
  }
  return;
}

Future<void> uploadFilesInit(Map<String, dynamic> titleFilename) async {
  final filename = titleFilename["filename"];
  final title = titleFilename["title"];
  final updatedAt = titleFilename["updatedAt"];

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename.json');


  if (!await file.exists()) return print(title+" not exists"); ;
  print(title);

  final jsonStr = await file.readAsString();
  final List<dynamic> questions = jsonDecode(jsonStr);

  final setRef = firestore.collection('sets').doc(filename);
  final questionsRef = setRef.collection('questions');

  // 2. sets コレクションに基本情報登録
  await setRef.set({
    'filename': filename,
    'title': title,
    'updatedAt': updatedAt,
    'tags': titleFilename['tags'] ?? [],
    'downloadCount': 0,
  }, SetOptions(merge: true));

  // 3. questions 再アップロード
  final batchUpload = firestore.batch();
  for (var q in questions) {
    final docRef = questionsRef.doc(q['index'].toString());
    batchUpload.set(docRef, q);
  }
  await batchUpload.commit();
}
