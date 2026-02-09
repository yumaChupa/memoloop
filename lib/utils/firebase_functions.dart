import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'package:memoloop/globals.dart' as globals;

final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
Future<void> uploadProblemSetWithReset(String title, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename.json');

  if (!await file.exists()) return;

  final jsonStr = await file.readAsString();
  final List<dynamic> questions = jsonDecode(jsonStr);
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

  // 2. sets コレクションに基本情報登録
  await setRef.set({'title': title, 'filename': filename, 'updatedAt': now});

  // 3. questions 再アップロード
  final batchUpload = firestore.batch();
  for (var q in questions) {
    final docRef = questionsRef.doc(q['index'].toString());
    batchUpload.set(docRef, q);
  }
  await batchUpload.commit();
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




//////////////////////////////////////////
/////初期化用、firestoreにデータ入れる用//////
//////////////////////////////////////////

// Firebaseの初期化（開発時一回のみ）
Future<void> firebaseInit(List<Map<String, dynamic>> title_filenames) async {
  for (var title_filename in title_filenames) {
    await uploadFilesInit(title_filename);
  }
  return;
}

Future<void> uploadFilesInit(Map<String, dynamic> title_filename) async {
  final filename = title_filename["filename"];
  final title = title_filename["title"];
  final updatedAt = title_filename["updatedAt"];

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
  });

  // 3. questions 再アップロード
  final batchUpload = firestore.batch();
  for (var q in questions) {
    final docRef = questionsRef.doc(q['index'].toString());
    batchUpload.set(docRef, q);
  }
  await batchUpload.commit();
}
