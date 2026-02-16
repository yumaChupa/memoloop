// 標準の Flutter パッケージ（最優先）
import 'package:flutter/material.dart';

// サードパーティパッケージ（アルファベット順）
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

// プロジェクト内のパッケージ（アルファベット順、階層深い順でもOK）
import 'package:memoloop/globals.dart' as globals;
import 'package:memoloop/utils/functions.dart';
import 'package:memoloop/utils/tts_function.dart';
import 'package:memoloop/utils/migration.dart';
import 'package:memoloop/utils/firebase_functions.dart';

// プロジェクトのローカルファイル（アルファベット順）
import 'screens/create/create_select.dart';
import 'screens/flashcard/flashcard_select.dart';
import 'screens/listen/listen_select.dart';
import 'screens/overview/overview_select.dart';
import 'screens/add/add_select.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initTtsClient(); // TTS初期化
  await runMigrations(); // マイグレーション（schemaVersionで制御）
  await loadTitleFilenames(); // 必ずMyApp実行前に呼び出す
  runApp(const MyApp());

  // Firebase初期化をバックグラウンドで実行
  _initFirebaseInBackground();
}

/// Firebaseをバックグラウンドで初期化する
Future<void> _initFirebaseInBackground() async {
  try {
    await Firebase.initializeApp();
    await firebaseInit(globals.titleFilenames);
    globals.isFirebaseReady = true;
    debugPrint('Firebase initialized successfully in background');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'memoloop',
      theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),

        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(backgroundColor: Colors.white, elevation: 0),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.fromHeight(60),
            // 枠線の色と太さ
            shape: RoundedRectangleBorder(
              // 角丸の指定
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black,

            textStyle: TextStyle(
              fontWeight: FontWeight.w600, // 太さを指定
              fontSize: 18,
            ),
          ),
        ),
      ),
      home: const MyHomePage(title: 'memoloop'),
      // debugShowCheckedModeBanner: false
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ボタンのスタイル指定
  Widget mainButton({
    required Color color,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          side: BorderSide.none,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 100),
            alignment: Alignment.center,
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.32,
            child: const Text(
              "memoloop",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ),
          mainButton(
            color: Colors.redAccent.shade100,
            text: 'Flashcards',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FlashCardSelect()),
              );
            },
          ),
          mainButton(
            color: Colors.blueAccent.shade100,
            text: 'Create',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => createSelect()),
              );
            },
          ),
          mainButton(
            color: Color(0xFF61D685),
            text: 'Add',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddSelect()),
              );
            },
          ),
          mainButton(
            color: Colors.orangeAccent.shade200,
            text: 'Listview',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OverviewSelect()),
              );
            },
          ),
          mainButton(
            color: Color(0xFFEB89E6),
            text: 'Audio',
            onPressed: () async {
              final connectivityResult =
                  await Connectivity().checkConnectivity();
              final isOnline = connectivityResult != ConnectivityResult.none;

              if (!isOnline) {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text("オフラインです"),
                        content: Text("この機能を使うにはインターネット接続が必要です。"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("OK"),
                          ),
                        ],
                      ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListenSelect()),
              );
            },
          ),
        ],
      ),
    );
  }
}
