import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:memoloop/globals.dart' as globals;

/// Cloud Functions インスタンス（Firebase初期化後に安全にアクセス）
FirebaseFunctions get _fn => FirebaseFunctions.instance;

/// Firestoreインスタンス（開発用初期化のみ残す）
FirebaseFirestore get firestore => FirebaseFirestore.instance;

// ローカルクールダウン: 最後のアップロード時刻を保持
DateTime? _lastUploadTime;
const _uploadCooldown = Duration(seconds: 20);

////////////////////////////////////////////////
////// 公開問題セット一覧をCloud Functionsで取得
////////////////////////////////////////////////
Future<List<Map<String, dynamic>>> getSetsList() async {
  final result = await _fn.httpsCallable('getSetsList').call({
    'deviceUuid': globals.deviceUuid,
  });
  final list = result.data['sets'] as List<dynamic>;
  return list.cast<Map<String, dynamic>>();
}

////////////////////////////////////////////////
////// 特定問題セットの問題をCloud Functionsで取得
////////////////////////////////////////////////
Future<List<Map<String, dynamic>>> getProblemSet(String filename) async {
  final result = await _fn.httpsCallable('getProblemSet').call({
    'deviceUuid': globals.deviceUuid,
    'filename': filename,
  });
  final list = result.data['questions'] as List<dynamic>;
  return list.cast<Map<String, dynamic>>();
}

////////////////////////////////////////////////
// ローカルの問題セットjsonをCloud Functionsでアップロード
////////////////////////////////////////////////

/// 問題セットをアップロード。
/// 戻り値: null=成功, -1=問題数超過, -2=1日の上限超過, >0=クールダウン残秒数
const int maxQuestionCount = 310;

Future<int?> uploadProblemSetWithReset(
  String title,
  String filename, {
  List<String> tags = const [],
}) async {
  // ローカルクールダウンチェック
  if (_lastUploadTime != null) {
    final elapsed = DateTime.now().difference(_lastUploadTime!);
    if (elapsed < _uploadCooldown) {
      return _uploadCooldown.inSeconds - elapsed.inSeconds;
    }
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/data/$filename.json');
  if (!await file.exists()) return null;

  final jsonStr = await file.readAsString();
  final List<dynamic> questions = jsonDecode(jsonStr);

  if (questions.length > maxQuestionCount) return -1;

  // good/bad はローカル専用フィールドのため除外
  final cleaned = questions.map((q) {
    final m = Map<String, dynamic>.from(q as Map);
    m.remove('good');
    m.remove('bad');
    return m;
  }).toList();

  try {
    await _fn.httpsCallable('uploadProblemSet').call({
      'deviceUuid': globals.deviceUuid,
      'title': title,
      'filename': filename,
      'tags': tags,
      'questions': cleaned,
    });
    _lastUploadTime = DateTime.now();
    return null;
  } on FirebaseFunctionsException catch (e) {
    if (e.code == 'resource-exhausted') return -2;
    rethrow;
  }
}

////////////////////////////////////////////////
// ダウンロード数をインクリメント（Function経由）
////////////////////////////////////////////////
Future<void> incrementDownloadCount(String filename) async {
  try {
    await _fn.httpsCallable('incrementDownload').call({
      'deviceUuid': globals.deviceUuid,
      'filename': filename,
    });
  } catch (_) {
    // ダウンロードカウントは非クリティカルのため握りつぶす
  }
}

//////////////////////////////////////////
///// 開発用初期化（Firestore直接書き込み）///
//////////////////////////////////////////

Future<void> firebaseInit(List<Map<String, dynamic>> titleFilenames) async {
  for (var titleFilename in titleFilenames) {
    await uploadFilesInit(titleFilename);
  }
}

Future<void> uploadFilesInit(Map<String, dynamic> titleFilename) async {
  final filename = titleFilename["filename"];
  final title = titleFilename["title"];
  final updatedAt = titleFilename["updatedAt"];

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/data/$filename.json');

  final jsonStr = await file.readAsString();
  final List<dynamic> questions = jsonDecode(jsonStr);

  final setRef = firestore.collection('sets').doc(filename);
  final questionsRef = setRef.collection('questions');

  await setRef.set({
    'filename': filename,
    'title': title,
    'updatedAt': updatedAt,
    'tags': titleFilename['tags'] ?? [],
    'downloadCount': 0,
  }, SetOptions(merge: true));

  final batchUpload = firestore.batch();
  for (var q in questions) {
    final docRef = questionsRef.doc(q['index'].toString());
    batchUpload.set(docRef, q);
  }
  await batchUpload.commit();
}
