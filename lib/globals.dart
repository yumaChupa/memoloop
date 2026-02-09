import 'package:uuid/uuid.dart';

final uuid = Uuid().v4();

List<Map<String, String>> title_filenames = [
  {
    "title": "動作の表現",
    "filename": "shortexpression",
    "updatedAt": "2025-07-06T00:00:00.000",
  },
  {
    "title": "挨拶・反応",
    "filename": "greeting",
    "updatedAt": "2025-07-05T00:00:00.000",
  },
  {
    "title": "日常会話で使える短い表現",
    "filename": "everydayexpression",
    "updatedAt": "2025-07-04T00:00:00.000",
  },
  {
    "title": "表現の型",
    "filename": "format",
    "updatedAt": "2025-07-03T00:00:00.000",
  },
  {
    "title": "カフェ・レストラン",
    "filename": "cafe",
    "updatedAt": "2025-09-05T00:00:00.000",
  },
  {
    "title": "味・食感",
    "filename": "taste",
    "updatedAt": "2025-09-05T00:00:00.000",
  },
  {
    "title": "感触",
    "filename": "texture",
    "updatedAt": "2025-09-05T00:00:00.000",
  },
  // {
  //   "title": "fallout",
  //   "filename": "fallout",
  //   "updatedAt": "2025-07-01T00:00:00.000",
  // },
  // {
  //   "title": "フレンズ-s1-",
  //   "filename": "friends_s1",
  //   "updatedAt": "2025-07-02T00:00:00.000",
  // },
];

enum QuizOrder { original, wrongFirst, random }

QuizOrder currentOrder = QuizOrder.original;
