import 'package:uuid/uuid.dart';

final uuid = Uuid().v4();

<<<<<<< HEAD
// Firebase初期化のFuture（main()で開始、Firebase使用箇所でawait）
=======
// Firebase初期化Futureの管理（使用箇所でawaitして初期化完了を待つ）
>>>>>>> main
late Future<void> firebaseInitFuture;

List<Map<String, dynamic>> titleFilenames = [
  {
    "title": "動作の表現",
    "filename": "shortexpression",
    "updatedAt": "2025-07-06T00:00:00.000",
    "tags": <String>['短文'],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
    "isMine": false,
  },
  {
    "title": "挨拶・反応",
    "filename": "greeting",
    "updatedAt": "2025-07-05T00:00:00.000",
    "tags": <String>['短文'],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
    "isMine": false,
  },
  {
    "title": "日常会話で使える短い表現",
    "filename": "everydayexpression",
    "updatedAt": "2025-07-04T00:00:00.000",
    "tags": <String>['短文'],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
    "isMine": false,
  },
  {
    "title": "表現の型",
    "filename": "format",
    "updatedAt": "2025-07-03T00:00:00.000",
    "tags": <String>['短文'],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
    "isMine": false,
  },
  {
    "title": "カフェ・レストラン",
    "filename": "cafe",
    "updatedAt": "2025-09-05T00:00:00.000",
    "tags": <String>['短文'],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
    "isMine": false,
  },
  {
    "title": "味・食感",
    "filename": "taste",
    "updatedAt": "2025-09-05T00:00:00.000",
    "tags": <String>['英単語'],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
    "isMine": false,
  },
  {
    "title": "感触",
    "filename": "texture",
    "updatedAt": "2025-09-05T00:00:00.000",
    "tags": <String>['英単語'],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
    "isMine": false,
  },
];

// 選択可能なタグ一覧（追加する場合はここにStringを追加するだけ）
const List<String> availableTags = [
  'ドラマ・映画',
  '日常会話',
  '英単語',
  'IT',
  '短文'
];

enum QuizOrder { original, wrongFirst, random }

QuizOrder currentOrder = QuizOrder.original;
