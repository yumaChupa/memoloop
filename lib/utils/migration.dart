import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const int currentSchemaVersion = 2;

// 除外対象のファイル名（data/ディレクトリへ移動しない）
const _excludedFiles = {'title_filenames.json', 'schema_version.json'};

Future<int> _readSchemaVersion(Directory dir) async {
  final file = File('${dir.path}/schema_version.json');
  if (!await file.exists()) return 0;
  try {
    final json = jsonDecode(await file.readAsString());
    return json['schemaVersion'] as int? ?? 0;
  } catch (_) {
    return 0;
  }
}

Future<void> _writeSchemaVersion(Directory dir, int version) async {
  final file = File('${dir.path}/schema_version.json');
  await file.writeAsString(jsonEncode({'schemaVersion': version}));
}

void _renameKey(Map<String, dynamic> map, String oldKey, String newKey) {
  if (map.containsKey(oldKey) && !map.containsKey(newKey)) {
    map[newKey] = map[oldKey];
    map.remove(oldKey);
  }
}

/// メインエントリポイント。schemaVersionに基づき必要なマイグレーションを順次実行。
Future<void> runMigrations() async {
  final dir = await getApplicationDocumentsDirectory();
  final storedVersion = await _readSchemaVersion(dir);

  if (storedVersion >= currentSchemaVersion) return;

  if (storedVersion < 1) {
    await _migrateV1(dir);
    await _writeSchemaVersion(dir, 1);
    debugPrint('Migration v1 completed: files moved to data/');
  }

  if (storedVersion < 2) {
    await _migrateV2(dir);
    await _writeSchemaVersion(dir, 2);
    debugPrint('Migration v2 completed: question keys renamed');
  }
}

/// v1: ファイルを data/ サブディレクトリへ移動 + titleFilenames フィールド追加保証
Future<void> _migrateV1(Directory dir) async {
  final dataDir = Directory('${dir.path}/data');
  if (!await dataDir.exists()) {
    await dataDir.create(recursive: true);
  }

  // titleFilenames を読み込み、フィールド追加保証
  final titleFilenamesFile = File('${dir.path}/title_filenames.json');
  List<Map<String, dynamic>> titleFilenames = [];
  if (await titleFilenamesFile.exists()) {
    try {
      final jsonStr = await titleFilenamesFile.readAsString();
      titleFilenames = List<Map<String, dynamic>>.from(
        (jsonDecode(jsonStr) as List).map((e) => Map<String, dynamic>.from(e)),
      );
      bool changed = false;
      for (var item in titleFilenames) {
        if (!item.containsKey('tags')) {
          item['tags'] = <String>[];
          changed = true;
        }
        if (!item.containsKey('completionCount')) {
          item['completionCount'] = 0;
          changed = true;
        }
        if (!item.containsKey('avgTimePerQuestion')) {
          item['avgTimePerQuestion'] = 0.0;
          changed = true;
        }
        if (!item.containsKey('isMine')) {
          item['isMine'] = false;
          changed = true;
        }
      }
      if (changed) {
        await titleFilenamesFile.writeAsString(jsonEncode(titleFilenames));
      }
    } catch (e) {
      debugPrint('Migration v1: Failed to process title_filenames.json: $e');
    }
  }

  // titleFilenames に登録されているファイル名を取得
  final knownFilenames = <String>{};
  for (var item in titleFilenames) {
    final fn = item['filename']?.toString();
    if (fn != null && fn.isNotEmpty) {
      knownFilenames.add('$fn.json');
    }
  }

  // ルートディレクトリの全JSONファイルを走査
  final rootEntities = dir.listSync();
  for (var entity in rootEntities) {
    if (entity is! File) continue;
    final basename = entity.uri.pathSegments.last;
    if (!basename.endsWith('.json')) continue;
    if (_excludedFiles.contains(basename)) continue;

    // data/ への移動
    final targetFile = File('${dataDir.path}/$basename');
    try {
      if (await targetFile.exists()) {
        // 移動先に既に存在する場合はルートのファイルを削除（冪等性）
        await entity.delete();
      } else {
        // 移動（同一ファイルシステムのため rename で高速に）
        await entity.rename(targetFile.path);
      }
    } catch (e) {
      // rename が失敗した場合はコピー+削除でフォールバック
      try {
        await entity.copy(targetFile.path);
        await entity.delete();
      } catch (e2) {
        debugPrint('Migration v1: Failed to move $basename: $e2');
      }
    }
  }
}

/// v2: 問題データのキー名を変更 (English→Question, Japanese→Answer, done→good, more→bad)
Future<void> _migrateV2(Directory dir) async {
  final dataDir = Directory('${dir.path}/data');
  if (!await dataDir.exists()) return;

  final entities = dataDir.listSync();
  for (var entity in entities) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;

    try {
      final jsonStr = await entity.readAsString();
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) continue;

      bool changed = false;
      for (var item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        if (item.containsKey('Japanese') && !item.containsKey('Answer')) {
          _renameKey(item, 'Japanese', 'Answer');
          changed = true;
        }
        if (item.containsKey('English') && !item.containsKey('Question')) {
          _renameKey(item, 'English', 'Question');
          changed = true;
        }
        if (item.containsKey('done') && !item.containsKey('good')) {
          _renameKey(item, 'done', 'good');
          changed = true;
        }
        if (item.containsKey('more') && !item.containsKey('bad')) {
          _renameKey(item, 'more', 'bad');
          changed = true;
        }
      }

      if (changed) {
        await entity.writeAsString(jsonEncode(decoded));
      }
    } catch (e) {
      debugPrint('Migration v2: Failed to process ${entity.path}: $e');
    }
  }
}
