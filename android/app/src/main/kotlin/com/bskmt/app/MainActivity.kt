package com.bskmt.app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelNames = listOf("com.bskmt.app/export", "vn.datbike/export", "vn.mybike/export")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        for (channelName in channelNames) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportToDownloads" -> {
                        val paths = call.argument<List<String>>("paths") ?: emptyList()
                        try {
                            val exported = exportToDownloads(paths)
                            result.success(exported)
                        } catch (e: Exception) {
                            result.error("EXPORT_FAILED", e.message, null)
                        }
                    }
                    "startForegroundService" -> {
                        val title = call.argument<String>("title")
                        val text = call.argument<String>("text")
                        try {
                            ConnectService.start(this, title, text)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FOREGROUND_START_FAILED", e.message, null)
                        }
                    }
                    "stopForegroundService" -> {
                        try {
                            ConnectService.stop(this)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FOREGROUND_STOP_FAILED", e.message, null)
                        }
                    }
                    "openMap" -> {
                        val url = call.argument<String>("url")
                        try {
                            if (url != null) {
                                val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url))
                                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.error("URL_NULL", "URL is null", null)
                            }
                        } catch (e: Exception) {
                            result.error("MAP_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun exportToDownloads(paths: List<String>): List<String> {
        val exported = mutableListOf<String>()
        val subDir = "BskmtLogs"
        for (path in paths) {
            val src = File(path)
            if (!src.exists()) continue
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, src.name)
                    put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
                    put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$subDir")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("MediaStore insert error")
                contentResolver.openOutputStream(uri)?.use { out ->
                    src.inputStream().use { it.copyTo(out) }
                } ?: throw IllegalStateException("Could not open output stream")
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
            } else {
                @Suppress("DEPRECATION")
                val dir = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                    subDir
                )
                if (!dir.exists()) dir.mkdirs()
                val dst = File(dir, src.name)
                src.copyTo(dst, overwrite = true)
            }
            exported.add(src.name)
        }
        if (exported.isEmpty()) throw IllegalStateException("No files to export")
        Log.i("BskmtExport", "Exported ${exported.size} file(s) to Downloads/$subDir")
        return exported
    }
}
