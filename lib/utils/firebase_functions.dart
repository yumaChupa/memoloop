import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Firestoreインスタンスは遅延取得（Firebase.initializeApp()後に安全にアクセス）
FirebaseFirestore get firestore => FirebaseFirestore.instance;

FirebaseFunctions get _functions => FirebaseFunctions.instance;

const _storage = FlutterSecureStorage();
const _uuidKey = 'device_uuid';

/// 端末固有UUID を取得、なければ生成して永続化する
Future<String> getOrCreateDeviceUuid() async {
  final existing = await _storage.read(key: _uuidKey);
  if (existing != null) return existing;
  final newUuid = const Uuid().v4();
  await _storage.write(key: _uuidKey, value: newUuid);
  return newUuid;
}

////////////////////////////////////////////////
////// Firebaseから問題セットを取得して返す(filename→return question)
////////////////////////////////////////////////
Future<List<Map<String, dynamic>>> getProblemSet(String filename) async {
  final doc = await firestore.collection('sets').doc(filename).get();
  final data = doc.data();
  if (data == null) return [];

  final snapshot =
      await firestore
          .collection('sets')
          .doc(filename)
          .collection('questions')
          .get();
  return snapshot.docs.map((doc) => doc.data()).toList();
}

////////////////////////////////////////////////
// ローカルの問題セットjsonをFirebaseにアップロード（Function経由）
////////////////////////////////////////////////
/// 問題セットをアップロード。レート制限に引っかかった場合は残り秒数を返す。
/// 容量制限超過時は -1 を返す。成功時はnull。
const int maxQuestionCount = 310;

// クライアント側の簡易チェック用（サーバー側でも検証する）
DateTime? _lastUploadTime;
const _uploadCooldown = Duration(seconds: 20);

Future<int?> uploadProblemSetWithReset(
  String title,
  String filename, {
  List<String> tags = const [],
}) async {
  // クライアント側レート制限チェック（サーバーへの無駄なリクエストを防ぐ）
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

  final uuid = await getOrCreateDeviceUuid();

  final callable = _functions.httpsCallable('uploadProblemSet');
  final result = await callable.call({
    'uuid': uuid,
    'title': title,
    'filename': filename,
    'tags': tags,
    'questions': questions,
  });

  final remaining = result.data['remaining'];
  if (remaining != null) {
    return remaining as int;
  }

  _lastUploadTime = DateTime.now();
  return null;
}

////////////////////////////////////////////////
// dbにある問題セットのタイトル、ファイル名をリストで取得
////////////////////////////////////////////////
Future<List<Map<String, dynamic>>> getSetsList() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('sets')
      .get();
  return querySnapshot.docs.map((doc) => doc.data()).toList();
}

////////////////////////////////////////////////
// ダウンロード数をインクリメント（Function経由）
////////////////////////////////////////////////
Future<void> incrementDownloadCount(String filename) async {
  try {
    final callable = _functions.httpsCallable('incrementDownload');
    await callable.call({'filename': filename});
  } catch (e) {
    // ダウンロード数の更新失敗はユーザー体験に影響しないためログのみ
    // ignore: avoid_print
    print('Failed to increment download count: $e');
  }
}
