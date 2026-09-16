package com.usbcamera.capture.usb_capture

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import java.io.File

class RecordingLibrary(private val activityProvider: () -> Activity?) {
    fun list(context: Context): List<Map<String, Any?>> {
        val items = mutableListOf<Map<String, Any?>>()
        val seen = mutableSetOf<String>()
        for (item in listMediaStore(context)) {
            val uri = item["uri"] as? String ?: continue
            if (seen.add(uri)) {
                items.add(item)
            }
        }
        for (item in listDownloads(context)) {
            val uri = item["uri"] as? String ?: continue
            if (seen.add(uri)) {
                items.add(item)
            }
        }
        for (item in listTree(context)) {
            val uri = item["uri"] as? String ?: continue
            if (seen.add(uri)) {
                items.add(item)
            }
        }
        return items
    }

    fun delete(context: Context, id: String) {
        val mediaId = id.toLongOrNull()
        if (mediaId != null) {
            val uri = ContentUris.withAppendedId(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                mediaId,
            )
            val deleted = context.contentResolver.delete(uri, null, null)
            if (deleted <= 0) {
                throw CaptureException("unknown", "deleteFailed")
            }
            return
        }
        val uri = Uri.parse(id)
        val deleted = try {
            context.contentResolver.delete(uri, null, null)
        } catch (_: Exception) {
            0
        }
        if (deleted > 0) {
            return
        }
        val removed = DocumentFile.fromSingleUri(context, uri)?.delete() == true
        if (!removed) {
            throw CaptureException("unknown", "deleteFailed")
        }
    }

    fun share(id: String) {
        val activity = activityProvider() ?: throw CaptureException("unknown", LibraryShareMissing)
        val uri = uriFor(id)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "video/mp4"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(
            Intent.createChooser(
                intent,
                UiLocale.wrap(activity).getString(R.string.share_recording),
            ),
        )
    }

    private fun uriFor(id: String): Uri {
        return id.toLongOrNull()?.let {
            ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, it)
        } ?: Uri.parse(id)
    }

    private fun renameUri(context: Context, uri: Uri, displayName: String): Boolean {
        if (uri.scheme == "file") {
            val source = File(uri.path ?: return false)
            val dest = File(source.parentFile ?: return false, displayName)
            if (LibraryNames.same(source.name, displayName)) {
                return true
            }
            if (dest.exists()) {
                return false
            }
            return source.renameTo(dest)
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
        }
        return try {
            if (context.contentResolver.update(uri, values, null, null) > 0) {
                true
            } else {
                DocumentFile.fromSingleUri(context, uri)?.renameTo(displayName) == true
            }
        } catch (_: Exception) {
            DocumentFile.fromSingleUri(context, uri)?.renameTo(displayName) == true
        }
    }

    fun open(id: String) {
        val activity = activityProvider() ?: throw CaptureException("unknown", "playFailed")
        val uri = uriFor(id)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "video/mp4")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = android.content.ClipData.newRawUri("", uri)
        }
        try {
            activity.startActivity(
                Intent.createChooser(
                    intent,
                    UiLocale.wrap(activity).getString(R.string.open_recording),
                ),
            )
        } catch (_: Exception) {
            throw CaptureException("unknown", "playFailed")
        }
    }

    fun openForRead(context: Context, id: String): Pair<android.os.ParcelFileDescriptor, Long>? {
        return try {
            val uri = uriFor(id)
            val pfd = context.contentResolver.openFileDescriptor(uri, "r") ?: return null
            var size = pfd.statSize
            if (size < 0) {
                size = querySize(context, uri) ?: -1L
            }
            if (size <= 0L) {
                pfd.close()
                return null
            }
            Pair(pfd, size)
        } catch (_: Exception) {
            null
        }
    }

    private fun querySize(context: Context, uri: Uri): Long? {
        context.contentResolver.query(
            uri,
            arrayOf(MediaStore.MediaColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val col = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                if (col >= 0) return cursor.getLong(col)
            }
        }
        return DocumentFile.fromSingleUri(context, uri)?.length()
    }

    fun rename(context: Context, id: String, rawName: String): Map<String, Any?> {
        val displayName = LibraryNames.normalize(rawName)
            ?: throw CaptureException("unknown", "renameInvalid")
        val items = list(context)
        val current = items.firstOrNull { item ->
            item["id"] == id || item["uri"] == id
        } ?: throw CaptureException("unknown", "renameFailed")
        val currentName = current["name"] as? String ?: ""
        if (LibraryNames.same(currentName, displayName)) {
            return current
        }
        val names = items.map { it["name"] as? String ?: "" }
        if (LibraryNames.taken(names, currentName, displayName)) {
            throw CaptureException("unknown", "renameTaken")
        }
        if (!renameUri(context, uriFor(id), displayName)) {
            throw CaptureException("unknown", "renameFailed")
        }
        return current.toMutableMap().apply { put("name", displayName) }
    }

    fun concat(
        context: Context,
        stamp: String,
        uris: List<String>,
        displayName: String,
        recordingStamp: String?,
    ): Map<String, Any?> {
        preflight(stamp, uris, displayName, recordingStamp)
        val parsed = uris.map(Uri::parse)
        val cache = File(context.cacheDir, "concat_$stamp.mp4")
        try {
            SessionConcat.remux(context, parsed, cache)
            val published = CaptureSave.publishBeside(context, parsed.first(), cache, displayName)
            return mapOf(
                "id" to published.toString(),
                "name" to displayName,
                "uri" to published.toString(),
                "durationMs" to null,
                "bytes" to cache.length(),
                "shareAvailable" to true,
                "deleteAvailable" to true,
            )
        } finally {
            cache.delete()
        }
    }

    companion object {
        const val LibraryShareMissing = "shareUnavailable"

        internal fun preflight(
            stamp: String,
            uris: List<String>,
            displayName: String,
            recordingStamp: String?,
        ) {
            if (recordingStamp != null && recordingStamp == stamp) {
                throw CaptureException("recordingFailed", "sessionRecording")
            }
            if (uris.size < 2 || displayName.isBlank() || stamp.isBlank()) {
                throw CaptureException("recordingFailed", "concatFailed")
            }
        }
    }

    private fun listMediaStore(context: Context): List<Map<String, Any?>> {
        val collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
        )
        val paths = CaptureSave.albumRelativePaths()
        val selection: String
        val args: Array<String>
        if (Build.VERSION.SDK_INT >= 29) {
            selection = paths.joinToString(" OR ") { "${MediaStore.Video.Media.RELATIVE_PATH} LIKE ?" }
            args = paths.map { "%$it%" }.toTypedArray()
        } else {
            @Suppress("DEPRECATION")
            selection = paths.joinToString(" OR ") { "${MediaStore.Video.Media.DATA} LIKE ?" }
            args = paths.map { "%/$it/%" }.toTypedArray()
        }
        val sort = "${MediaStore.Video.Media.DATE_ADDED} DESC"
        val items = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(collection, projection, selection, args, sort)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val durationCol = cursor.getColumnIndex(MediaStore.Video.Media.DURATION)
            val sizeCol = cursor.getColumnIndex(MediaStore.Video.Media.SIZE)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val uri = ContentUris.withAppendedId(collection, id)
                items.add(
                    mapOf(
                        "id" to id.toString(),
                        "name" to cursor.getString(nameCol),
                        "uri" to uri.toString(),
                        "durationMs" to if (durationCol >= 0) cursor.getLong(durationCol) else null,
                        "bytes" to if (sizeCol >= 0) cursor.getLong(sizeCol) else null,
                        "shareAvailable" to true,
                        "deleteAvailable" to true,
                    ),
                )
            }
        }
        return items
    }

    private fun listDownloads(context: Context): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < 29) {
            return emptyList()
        }
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Downloads._ID,
            MediaStore.Downloads.DISPLAY_NAME,
            MediaStore.Downloads.SIZE,
        )
        val selection = "${MediaStore.Downloads.RELATIVE_PATH} LIKE ?"
        val args = arrayOf("%${Environment.DIRECTORY_DOWNLOADS}/${CaptureSave.ALBUM}%")
        val sort = "${MediaStore.Downloads.DATE_ADDED} DESC"
        val items = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(collection, projection, selection, args, sort)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
            val sizeCol = cursor.getColumnIndex(MediaStore.Downloads.SIZE)
            while (cursor.moveToNext()) {
                val uri = ContentUris.withAppendedId(collection, cursor.getLong(idCol))
                items.add(
                    mapOf(
                        "id" to uri.toString(),
                        "name" to cursor.getString(nameCol),
                        "uri" to uri.toString(),
                        "durationMs" to null,
                        "bytes" to if (sizeCol >= 0) cursor.getLong(sizeCol) else null,
                        "shareAvailable" to true,
                        "deleteAvailable" to true,
                    ),
                )
            }
        }
        return items
    }

    private fun listTree(context: Context): List<Map<String, Any?>> {
        val treeUri = CaptureSave.treeUri(context) ?: return emptyList()
        val tree = DocumentFile.fromTreeUri(context, treeUri) ?: return emptyList()
        return tree.listFiles()
            .filter { file ->
                file.isFile && (
                    file.type?.startsWith("video/") == true ||
                        file.name?.endsWith(".mp4", ignoreCase = true) == true
                    )
            }
            .sortedByDescending { it.lastModified() }
            .map { file ->
                mapOf(
                    "id" to file.uri.toString(),
                    "name" to (file.name ?: "video.mp4"),
                    "uri" to file.uri.toString(),
                    "durationMs" to null,
                    "bytes" to file.length(),
                    "shareAvailable" to true,
                    "deleteAvailable" to true,
                )
            }
    }
}
