import 'package:uuid/uuid.dart';

final uuid = Uuid().v4();

// Firebase初期化状態の管理
bool isFirebaseReady = false;

List<Map<String, dynamic>> title_filenames = [
  {
    "title": "動作の表現",
    "filename": "shortexpression",
    "updatedAt": "2025-07-06T00:00:00.000",
    "tags": <String>[],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
  },
  {
    "title": "挨拶・反応",
    "filename": "greeting",
    "updatedAt": "2025-07-05T00:00:00.000",
    "tags": <String>[],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
  },
  {
    "title": "日常会話で使える短い表現",
    "filename": "everydayexpression",
    "updatedAt": "2025-07-04T00:00:00.000",
    "tags": <String>[],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
  },
  {
    "title": "表現の型",
    "filename": "format",
    "updatedAt": "2025-07-03T00:00:00.000",
    "tags": <String>[],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
  },
  {
    "title": "カフェ・レストラン",
    "filename": "cafe",
    "updatedAt": "2025-09-05T00:00:00.000",
    "tags": <String>[],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
  },
  {
    "title": "味・食感",
    "filename": "taste",
    "updatedAt": "2025-09-05T00:00:00.000",
    "tags": <String>[],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
  },
  {
    "title": "感触",
    "filename": "texture",
    "updatedAt": "2025-09-05T00:00:00.000",
    "tags": <String>[],
    "completionCount": 0,
    "avgTimePerQuestion": 0.0,
  },
  // {
  //   "title": "fallout",
  //   "filename": "fallout",
  //   "updatedAt": "2025-07-01T00:00:00.000",
  //   "tags": <String>[],
  // },
  // {
  //   "title": "フレンズ-s1-",
  //   "filename": "friends_s1",
  //   "updatedAt": "2025-07-02T00:00:00.000",
  //   "tags": <String>[],
  // },
];

// 選択可能なタグ一覧（追加する場合はここにStringを追加するだけ）
const List<String> availableTags = [
  'ドラマ・映画',
  '日常会話',
  '英単語',
  'IT',
];

enum QuizOrder { original, wrongFirst, random }

QuizOrder currentOrder = QuizOrder.original;
