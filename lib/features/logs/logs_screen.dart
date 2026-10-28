import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ble/ble_logger.dart';
import '../../ui/app_theme.dart';
import 'widgets/log_dialogs.dart';
import 'widgets/log_file_tile.dart';
import 'widgets/log_header_card.dart';
import 'widgets/log_preview_panel.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  static const _exportChannel = MethodChannel('vn.datbike/export');

  List<File> _files = [];
  String? _preview;
  String? _dirPath;
  File? _selected;
  bool _exporting = false;
  int? _sdkInt;

  @override
  void initState() {
    super.initState();
    BleLogger.dirPath().then((p) {
      if (mounted) setState(() => _dirPath = p);
    });
    DeviceInfoPlugin().androidInfo.then((i) {
      if (mounted) setState(() => _sdkInt = i.version.sdkInt);
    }).catchError((_) {});
    _refresh();
  }

  Future<void> _refresh() async {
    final files = await BleLogger.listSessions();
    setState(() => _files = files.cast<File>());
  }

  Future<void> _open(File f) async {
    final len = f.lengthSync();
    final cap = 20 * 1024 * 1024;
    final start = len > cap ? len - cap : 0;
    final content = await File(f.path)
        .openRead(start, len)
        .transform(systemEncoding.decoder)
        .join();
    setState(() {
      _selected = f;
      _preview = (start > 0 ? '…(omitidos $start bytes iniciales)\n' : '') + content;
    });
  }

  Future<void> _share(File f) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(f.path)], text: 'Registro de sesión BLE — BSKMT'),
    );
  }

  Future<void> _exportAll() async {
    if (_files.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final sdk = _sdkInt;
      if (sdk != null && sdk < 29) {
        final storage = await Permission.storage.request();
        if (storage.isPermanentlyDenied) {
          if (!mounted) return;
          LogDialogs.showStorageSettingsDialog(context);
          return;
        }
        if (!storage.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de almacenamiento requerido')),
          );
          return;
        }
      }
      final exported = await _exportChannel.invokeMethod<List<dynamic>>(
        'exportToDownloads',
        {'paths': _files.map((f) => f.path).toList()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exportados ${exported?.length ?? 0} archivos → Downloads/BskmtLogs'),
          backgroundColor: AppColors.tertiary,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: ${e.message}\nUse la opción de compartir por archivo'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAll() async {
    final ok = await LogDialogs.showDeleteAllDialog(context);
    if (ok == true) {
      await BleLogger.deleteAll();
      setState(() {
        _files = [];
        _preview = null;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'REGISTRO BLUETOOTH',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Eliminar todo',
              onPressed: _deleteAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          LogHeaderCard(
            fileCount: _files.length,
            dirPath: _dirPath,
            isExporting: _exporting,
            onExportAll: _exportAll,
          ),
          Expanded(
            flex: _preview == null ? 2 : 1,
            child: _files.isEmpty
                ? Center(
                    child: Text(
                      'Sin registros — conecte una moto para iniciar la captura.',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _files.length,
                    itemBuilder: (ctx, idx) {
                      final f = _files[idx];
                      return LogFileTile(
                        file: f,
                        isSelected: _selected?.path == f.path,
                        onTap: () => _open(f),
                        onShare: () => _share(f),
                      );
                    },
                  ),
          ),
          if (_preview != null)
            Expanded(
              flex: 2,
              child: LogPreviewPanel(
                previewText: _preview!,
                onShare: () => _selected != null ? _share(_selected!) : null,
                onClose: () => setState(() => _preview = null),
              ),
            ),
        ],
      ),
    );
  }
}
