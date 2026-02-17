import 'package:flutter/material.dart';

/// 各機能のテーマカラー
/// main: ボタンなど面積の大きいUI要素向け（やや落ち着いた彩度）
/// accent: 帯・Divider・チップなど面積の小さいUI要素向け（やや鮮やかな彩度）
class AppColors {
  // Listen (Purple)
  static const listenMain   = Color(0xFF9B7FB8); // 落ち着いた紫
  static const listenAccent = Color(0xFF9B59B6); // 鮮やかな紫

  // Flashcard (Red)
  static const flashcardMain   = Color(0xFFD06A6A); // 落ち着いた赤
  static const flashcardAccent = Color(0xFFE05555); // 鮮やかな赤

  // Add (Green)
  static const addMain   = Color(0xFF5BB07A); // 落ち着いた緑
  static const addAccent = Color(0xFF27AE60); // 鮮やかな緑

  // Overview (Orange)
  static const overviewMain   = Color(0xFFD4944F); // 落ち着いたオレンジ
  static const overviewAccent = Color(0xFFE8913A); // 鮮やかなオレンジ

  // Create (Blue)
  static const createMain   = Color(0xFF6A9BD0); // 落ち着いた青
  static const createAccent = Color(0xFF4A90D9); // 鮮やかな青
}
