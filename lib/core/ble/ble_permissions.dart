import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BlePermissions {
  BlePermissions._();

  static Future<bool> ensure() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final scan = results[Permission.bluetoothScan] ??
        PermissionStatus.permanentlyDenied;
    final connect = results[Permission.bluetoothConnect] ??
        PermissionStatus.permanentlyDenied;
    final location =
        results[Permission.locationWhenInUse] ?? PermissionStatus.permanentlyDenied;

    final scanOk = scan.isGranted || location.isGranted;
    return scanOk && connect.isGranted;
  }

  static Future<bool> permanentlyDenied() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;
    final scan = await Permission.bluetoothScan.status;
    final location = await Permission.locationWhenInUse.status;
    return scan.isPermanentlyDenied || location.isPermanentlyDenied;
  }
}
