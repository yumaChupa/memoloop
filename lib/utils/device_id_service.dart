import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// 端末固有UUIDを永続管理するサービス。
/// flutter_secure_storage により、アンインストール前まで同一IDを保持。
class DeviceIdService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _storageKey = 'device_uuid';

  /// 保存済みUUIDを返す。未生成の場合は新規生成して端末に永続保存。
  static Future<String> getOrCreate() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final newId = const Uuid().v4();
    await _storage.write(key: _storageKey, value: newId);
    return newId;
  }
}
