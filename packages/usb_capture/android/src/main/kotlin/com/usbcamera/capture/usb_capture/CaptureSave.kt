package com.usbcamera.capture.usb_capture

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import java.io.File

object CaptureSave {
    const val KIND_GALLERY = "gallery"
    const val KIND_MOVIES = "movies"
    const val KIND_DOWNLOADS = "downloads"
    const val KIND_CUSTOM = "custom"
    const val ALBUM = "UsbCapture"

    private const val PREFS = "usb_capture"
    private const val KEY_KIND = "save_kind"
    private const val KEY_URI = "save_tree_uri"

    fun kind(context: Context): String {
        val stored = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_KIND, KIND_GALLERY)
        return when (stored) {
            KIND_MOVIES, KIND_DOWNLOADS, KIND_CUSTOM -> stored
            else -> KIND_GALLERY
        }
    }

    fun treeUri(context: Context): Uri? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_URI, null)
        return raw?.takeIf { it.isNotBlank() }?.let(Uri::parse)
    }

    fun set(context: Context, kind: String, uri: String?) {
        val normalized = when (kind) {
            KIND_MOVIES, KIND_DOWNLOADS, KIND_CUSTOM -> kind
            else -> KIND_GALLERY
        }
        val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_KIND, normalized)
        if (normalized == KIND_CUSTOM && !uri.isNullOrBlank()) {
            editor.putString(KEY_URI, uri)
        }
        editor.apply()
    }

    fun folderName(context: Context): String? {
        val uri = treeUri(context) ?: return null
        return DocumentFile.fromTreeUri(context, uri)?.name
    }

    fun albumRelativePaths(): List<String> {
        return listOf(
            "${Environment.DIRECTORY_DCIM}/$ALBUM",
            "${Environment.DIRECTORY_MOVIES}/$ALBUM",
            "${Environment.DIRECTORY_DOWNLOADS}/$ALBUM",
        )
    }

    fun relativePath(context: Context): String {
        val dir = when (kind(context)) {
            KIND_MOVIES -> Environment.DIRECTORY_MOVIES
            KIND_DOWNLOADS -> Environment.DIRECTORY_DOWNLOADS
            else -> Environment.DIRECTORY_DCIM
        }
        return "$dir/$ALBUM"
    }

    fun publishMovie(context: Context, file: File, displayName: String): Uri {
        if (kind(context) == KIND_CUSTOM) {
            val tree = treeUri(context)
            if (tree != null) {
                try {
                    return writeTree(context, tree, file, displayName)
                } catch (_: Exception) {
                    // Fall back to the album if the picked tree is gone.
                }
            }
        }
        if (kind(context) == KIND_DOWNLOADS) {
            try {
                return writeDownloads(context, file, displayName)
            } catch (_: Exception) {
                return writeMediaStore(
                    context,
                    file,
                    displayName,
                    "${Environment.DIRECTORY_DCIM}/$ALBUM",
                )
            }
        }
        return writeMediaStore(context, file, displayName)
    }

    fun publishBeside(context: Context, source: Uri, file: File, displayName: String): Uri {
        if (isDownloadsUri(source)) {
            return writeDownloads(context, file, displayName)
        }
        val relative = mediaRelativePath(context, source)
        if (!relative.isNullOrBlank()) {
            return writeMediaStore(context, file, displayName, relative.trimEnd('/'))
        }
        val parent = DocumentFile.fromSingleUri(context, source)?.parentFile
        if (parent != null) {
            return writeIntoTree(context, parent, file, displayName)
        }
        val tree = treeUri(context)
        if (tree != null) {
            val treeDoc = DocumentFile.fromTreeUri(context, tree)
            if (treeDoc != null) {
                return writeIntoTree(context, treeDoc, file, displayName)
            }
        }
        return publishMovie(context, file, displayName)
    }

    fun payload(context: Context, uri: Uri, hasAudio: Boolean): Map<String, Any?> {
        val saveKind = kind(context)
        return mapOf(
            "path" to uri.toString(),
            "hasAudio" to hasAudio,
            "savedToMovies" to (saveKind == KIND_MOVIES),
            "saveKind" to saveKind,
        )
    }

    private fun writeTree(
        context: Context,
        treeUri: Uri,
        file: File,
        displayName: String,
    ): Uri {
        val tree = DocumentFile.fromTreeUri(context, treeUri)
            ?: throw CaptureException("recordingFailed")
        return writeIntoTree(context, tree, file, displayName)
    }

    private fun writeIntoTree(
        context: Context,
        tree: DocumentFile,
        file: File,
        displayName: String,
    ): Uri {
        tree.findFile(displayName)?.delete()
        val dest = tree.createFile("video/mp4", displayName)
            ?: throw CaptureException("recordingFailed")
        context.contentResolver.openOutputStream(dest.uri)?.use { out ->
            file.inputStream().use { input -> input.copyTo(out) }
        } ?: throw CaptureException("recordingFailed")
        return dest.uri
    }

    private fun isDownloadsUri(uri: Uri): Boolean {
        val text = uri.toString()
        return text.contains("downloads", ignoreCase = true) ||
            uri.authority?.contains("downloads", ignoreCase = true) == true
    }

    private fun mediaRelativePath(context: Context, uri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.RELATIVE_PATH)
        return try {
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use null
                }
                cursor.getString(0)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun writeDownloads(context: Context, file: File, displayName: String): Uri {
        if (Build.VERSION.SDK_INT >= 29) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, displayName)
                put(MediaStore.Downloads.MIME_TYPE, "video/mp4")
                put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$ALBUM")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = context.contentResolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                values,
            ) ?: throw CaptureException("recordingFailed")
            context.contentResolver.openOutputStream(uri)?.use { out ->
                file.inputStream().use { input -> input.copyTo(out) }
            } ?: throw CaptureException("recordingFailed")
            val done = ContentValues().apply {
                put(MediaStore.Downloads.IS_PENDING, 0)
            }
            context.contentResolver.update(uri, done, null, null)
            return uri
        }
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            ALBUM,
        )
        if (!dir.exists() && !dir.mkdirs()) {
            throw CaptureException("recordingFailed")
        }
        val dest = File(dir, displayName)
        file.copyTo(dest, overwrite = true)
        return Uri.fromFile(dest)
    }

    private fun writeMediaStore(
        context: Context,
        file: File,
        displayName: String,
        relative: String = relativePath(context),
    ): Uri {
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, relative)
            if (Build.VERSION.SDK_INT >= 29) {
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }
        }
        val uri = context.contentResolver.insert(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: throw CaptureException("recordingFailed")
        context.contentResolver.openOutputStream(uri)?.use { out ->
            file.inputStream().use { input -> input.copyTo(out) }
        } ?: throw CaptureException("recordingFailed")
        if (Build.VERSION.SDK_INT >= 29) {
            val done = ContentValues().apply {
                put(MediaStore.Video.Media.IS_PENDING, 0)
            }
            context.contentResolver.update(uri, done, null, null)
        }
        return uri
    }
}
