import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class ForegroundService {
  static const _channel = MethodChannel('vn.mybike/export');

  static Future<void> start({String? title, String? text}) async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
      final args = <String, dynamic>{};
      if (title != null) args['title'] = title;
      if (text != null) args['text'] = text;
      await _channel.invokeMethod('startForegroundService', args);
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (_) {}
  }
}
