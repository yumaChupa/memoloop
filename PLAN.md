# Migration System Implementation Plan

## Overview
schemaVersion-based data migration system. App startup time に一度だけ実行。冪等性を保つ設計。

## Schema Versions
- **v0**: 暗黙的な初期状態（既存ユーザー、schema_version.json なし）
- **v1**: ファイルを `appDocs/data/` へ移動 + titleFilenames フィールド追加保証
- **v2**: 問題データのキー名変更 (English→Question, Japanese→Answer, done→good, more→bad)

## 新規ファイル
### `lib/utils/migration.dart`
- `runMigrations()`: メインエントリポイント。schema_version.json を読み、各バージョンのマイグレーションを順次実行
- `_migrateV1()`: data/ ディレクトリ作成、ルート直下の quiz JSON を data/ へ移動（衝突時はスキップ）、titleFilenames のフィールド追加保証
- `_migrateV2()`: data/ 内の全 JSON ファイルを走査し、キー名を変換（冪等）
- 各ステップ完了後に schemaVersion を書き込み（クラッシュセーフ）

## 変更ファイル一覧

### 1. `lib/main.dart`
- `runMigrations()` を `loadTitleFilenames()` の前に呼び出し

### 2. `lib/utils/functions.dart` (パス変更 + キー名変更)
- `loadJson()`: パスを `data/` に変更。assets からコピー時にキー変換
- `saveContents()`: パスを `data/` に変更
- `createNewfile()`: パスを `data/` に変更、data/ ディレクトリ作成
- `shareFile()`: パスを `data/` に変更
- `deleteFile()`: パスを `data/` に変更
- `addQuizItem()`: キー名 Japanese→Answer, English→Question, done→good, more→bad
- `editQuizItem()`: キー名 Japanese→Answer, English→Question

### 3. `lib/utils/firebase_functions.dart`
- `uploadProblemSetWithReset()`: パスを `data/` に変更、remove('done'/'more') → remove('good'/'bad')
- `uploadFilesInit()`: パスを `data/` に変更

### 4. Screen ファイル（キー名変更のみ）
- `create_screen.dart`: Japanese→Answer, English→Question, done→good, more→bad
- `overview_screen.dart`: Japanese→Answer, English→Question
- `flashcard_screen.dart`: Japanese→Answer, English→Question, done→good, more→bad（ソートロジック含む）
- `listen_screen.dart`: Japanese→Answer, English→Question, done→good, more→bad（ソートロジック含む）
- `add_screen.dart`: Japanese→Answer, English→Question、printJsonFiles() のパス変更

## 実行順序
1. migration.dart 作成
2. main.dart 修正
3. functions.dart 修正（パス + キー）
4. firebase_functions.dart 修正（パス + キー）
5. 全 screen ファイル修正（キー）
6. flutter analyze で確認
