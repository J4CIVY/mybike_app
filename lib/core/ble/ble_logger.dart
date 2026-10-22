import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

const appBuild = '20261020j';

class BleLogger {
  BleLogger._();
  static final BleLogger instance = BleLogger._();

  IOSink? _sink;
  File? _file;
  int _eventCount = 0;

  bool get active => _sink != null;
  File? get file => _file;
  int get eventCount => _eventCount;

  Future<File> startSession() async {
    await close();
    final dir = await _logDir();
    final ts = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '')
        .replaceAll('-', '');
    _file = File('${dir.path}/session_$ts.jsonl');
    _sink = _file!.openWrite(mode: FileMode.append);
    _eventCount = 0;
    event('session_start', {
      'app': 'mybike_flutter',
      'platform': Platform.operatingSystem,
      'build': appBuild,
    });
    return _file!;
  }

  Future<void> close() async {
    final sink = _sink;
    _sink = null;
    await sink?.flush();
    await sink?.close();
  }

  void event(String type, [Map<String, Object?> data = const {}]) {
    final sink = _sink;
    if (sink == null) return;
    try {
      final line = jsonEncode({
        'ts': DateTime.now().toIso8601String(),
        'type': type,
        ...data,
      });
      sink.writeln(line);
      _eventCount++;

      unawaited(sink.flush().catchError((_) {}));
    } catch (_) {

      try {
        sink.writeln(jsonEncode({
          'ts': DateTime.now().toIso8601String(),
          'type': type,
          'log_err': 'encode_failed',
        }));
      } catch (_) {}
    }
  }

  static String hex(List<int> bytes, {int maxBytes = 256}) {
    final show = bytes.length > maxBytes ? bytes.sublist(0, maxBytes) : bytes;
    final hex = show.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    return bytes.length > maxBytes ? '$hex …(+${bytes.length - maxBytes}B)' : hex;
  }

  static String? tryUtf8(List<int> bytes) {
    try {
      final s = utf8.decode(bytes, allowMalformed: false);
      return s.codeUnits.every((c) => c >= 32 && c <= 126) ? s : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Directory> _logDir() async {

    final ext = await getExternalStorageDirectory();
    final base = ext?.path ?? (await getApplicationDocumentsDirectory()).path;
    final dir = Directory('$base/ble_logs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<List<FileSystemEntity>> listSessions() async {
    final dir = await _logDir();
    final files = dir.existsSync()
        ? dir.listSync().whereType<File>().toList()
        : <File>[];
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  static Future<String> dirPath() async => (await _logDir()).path;

  static Future<void> deleteAll() async {
    final dir = await _logDir();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
