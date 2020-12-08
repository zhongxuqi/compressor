package com.musketeer.compressor

import android.content.Context
import android.net.Uri
import java.io.*

class FileObj(val fileName: String, val uri: String)

object FileUtils {
    fun getPathFromUri(context: Context, uri: Uri): FileObj? {
        var file: File? = null
        var inputStream: InputStream? = null
        var outputStream: OutputStream? = null
        var success = false

        try {
            val extension = getImageExtension(uri)
            inputStream = context.contentResolver.openInputStream(uri)
            file = File(context.cacheDir, "${System.nanoTime()}$extension")
            file.createNewFile()
            file.deleteOnExit()
            outputStream = FileOutputStream(file!!)
            if (inputStream != null) {
                copy(inputStream, outputStream)
                success = true
            }
        } catch (ignored: IOException) {

        } finally {
            try {
                inputStream?.close()
            } catch (ignored: IOException) {
            }
            try {
                outputStream?.close()
            } catch (ignored: IOException) {
                success = false
            }
        }
        return if (success) FileObj(Uri.parse(Uri.decode(uri.toString())).pathSegments.last(), file!!.path) else null
    }

    private fun getImageExtension(uriImage: Uri): String {
        var extension: String? = null
        try {
            val imagePath = uriImage.path
            if (imagePath != null && imagePath.lastIndexOf(".") != -1) {
                extension = imagePath.substring(imagePath.lastIndexOf(".") + 1)
            }
        } catch (e: Exception) {
            extension = null
        }
        if (extension == null || extension.isEmpty()) {
            //default extension for matches the previous behavior of the plugin
            extension = "jpg"
        }
        return ".$extension"
    }

    @Throws(IOException::class)
    private fun copy(`in`: InputStream, out: OutputStream) {
        val buffer = ByteArray(4 * 1024)
        var bytesRead: Int
        while (`in`.read(buffer).also { bytesRead = it } != -1) {
            out.write(buffer, 0, bytesRead)
        }
        out.flush()
    }
}