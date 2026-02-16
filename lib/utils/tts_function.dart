import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

late AutoRefreshingAuthClient _ttsClient;

Future<void> initTtsClient() async {
  final jsonStr = await rootBundle.loadString('assets/keys/tts_service.json');
  final accountCredentials = ServiceAccountCredentials.fromJson(
    json.decode(jsonStr),
  );

  final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  _ttsClient = await clientViaServiceAccount(accountCredentials, scopes);
}

/// TTS音声を再生する。[player]を渡すと外部から停止制御が可能。
Future<void> speakText(String text, {AudioPlayer? player}) async {
  try {
    _ttsClient;
  } catch (_) {
    throw Exception('TTS client not initialized.');
  }

  final response = await _ttsClient.post(
    Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "input": {"text": text},
      //　プレミアム：ja-JP-Chirp3-HD-Aoede, Charon ,Fenrir、ja-JP-Neural2-B~D、ja-JP-Wavenet-A~D
      //	、ja-JP-Standard-A~D
      "voice": {"languageCode": "ja-JP", "name": "ja-JP-Neural2-C"},
      "audioConfig": {
        "audioEncoding": "MP3",
        "speakingRate": 1.1,
        "pitch": -4.0,
      },
    }),
  );

  if (response.statusCode == 200) {
    final audioContent = json.decode(response.body)['audioContent'];
    final audioBytes = base64Decode(audioContent);

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/tts_audio.mp3';
    await File(filePath).writeAsBytes(audioBytes);

    final p = player ?? AudioPlayer();
    await p.play(DeviceFileSource(filePath));

    // onPlayerComplete だけだと外部から stop() された時に永久に待ち続ける。
    // onPlayerStateChanged で stopped を検知するか、完了イベントが来たら抜ける。
    await Future.any([
      p.onPlayerComplete.first,
      p.onPlayerStateChanged
          .firstWhere((s) => s == PlayerState.stopped || s == PlayerState.disposed),
    ]);
  } else {
    throw Exception("TTS failed: ${response.body}");
  }
}

Future<void> disposeTtsClient() async {
  _ttsClient.close();
}
