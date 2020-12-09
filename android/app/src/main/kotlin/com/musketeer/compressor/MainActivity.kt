package com.musketeer.compressor

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.util.Log
import androidx.annotation.NonNull
import com.alibaba.fastjson.JSON
import com.alibaba.fastjson.annotation.JSONField
import com.github.junrar.Archive
import com.github.junrar.Junrar
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import net.lingala.zip4j.ZipFile
import net.lingala.zip4j.exception.ZipException
import net.lingala.zip4j.model.ZipParameters
import net.lingala.zip4j.model.enums.EncryptionMethod
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.URLConnection
import java.util.concurrent.Executors


class FileInfo {
    @JSONField(name="name")
    var Name: String = ""
    @JSONField(name="uri")
    var Uri: String = ""
    @JSONField(name="content_type")
    var ContentType: String = ""
    @JSONField(name="files")
    var files = HashMap<String, FileInfo>()
}

class FileHeader {
    @JSONField(name="file_name")
    var FileName: String = ""
    @JSONField(name="is_directory")
    var IsDirectory: Boolean = false
    @JSONField(name="content_type")
    var ContentType: String = ""
    @JSONField(name="last_modified")
    var LastModified: Long = 0
    @JSONField(name="file_size")
    var FileSize: Long = 0
}

class ExtractRes {
    @JSONField(name="err_code")
    var errCode: String = ""
    @JSONField(name="target_uri")
    var targetUri: String = ""
}

class MainActivity: FlutterActivity() {
    companion object {
        val TAG = "MainActivity"
    }
    private val CHANNEL = "com.musketeer.compressor"

    private val PICK_FILE = 1
    private var resultCallback: MethodChannel.Result? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainExecutor: Handler by lazy {
        Handler(context.mainLooper)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
            this.finish()
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor, CHANNEL).setMethodCallHandler(object: MethodChannel.MethodCallHandler{
            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                when (call.method) {
                    "pick_file" -> {
                        val req = call.arguments as HashMap<String, String>
                        val intent = Intent(Intent.ACTION_GET_CONTENT)
                        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                        intent.type = req["mime_type"]!!
                        startActivityForResult(intent, PICK_FILE)
                        resultCallback = result
                    }
                    "create_archive" -> {
                        val req = call.arguments as HashMap<String, String>
                        val fileInfos = JSONObject(req["files"]!!)
                        executor.submit(object: Runnable{
                            override fun run() {
                                val fileResult = createArchiveFile(req["archive_type"]!!, req["file_name"]!!, req["password"]!!, fileInfos)
                                mainExecutor.post(object: Runnable{
                                    override fun run() {
                                        result.success(fileResult.toString())
                                    }
                                })
                            }
                        })
                    }
                    "get_file_headers" -> {
                        val req = call.arguments as HashMap<String, String>
                        val fileHeaders = getFileHeaders(req["archive_type"]!!, req["uri"]!!, req["password"]!!)
                        result.success(JSON.toJSONString(fileHeaders))
                    }
                    "extract_file" -> {
                        val req = call.arguments as HashMap<String, String>
                        executor.submit(object: Runnable{
                            override fun run() {
                                val res = extractFile(req["archive_type"]!!, req["uri"]!!, req["password"]!!, req["file_name"]!!)
                                mainExecutor.post(object: Runnable{
                                    override fun run() {
                                        result.success(JSON.toJSONString(res))
                                    }
                                })
                            }
                        })
                    }
                    "extract_all" -> {
                        val req = call.arguments as HashMap<String, String>
                        executor.submit(object: Runnable{
                            override fun run() {
                                val res = extractAll(req["archive_type"]!!, req["uri"]!!, req["password"]!!, req["target_dir"]!!)
                                mainExecutor.post(object: Runnable{
                                    override fun run() {
                                        result.success(JSON.toJSONString(res))
                                    }
                                })
                            }
                        })
                    }
                    "feedback" -> {
                        val mAddress = "market://details?id=com.musketeer.compressor"
                        val marketIntent = Intent("android.intent.action.VIEW")
                        marketIntent.data = Uri.parse(mAddress)
                        startActivity(marketIntent)
                        result.success("")
                    }
                }
            }
        })
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            PICK_FILE -> {
                if (resultCode == Activity.RESULT_OK) {
                    val clipData = data?.clipData
                    val jsonArray = JSONArray()
                    if (clipData != null && clipData.itemCount > 0) {
                        for (i in 0 until clipData.itemCount) {
                            val fileJsonObj = getFileObjByUri(clipData.getItemAt(i).uri)
                            if (fileJsonObj != null) {
                                jsonArray.put(fileJsonObj)
                            }
                        }
                    } else {
                        if (data != null) {
                            val fileJsonObj = getFileObjByUri(data.data!!)
                            if (fileJsonObj != null) {
                                jsonArray.put(fileJsonObj)
                            }
                        }
                    }
                    resultCallback?.success(jsonArray.toString())
                }
            }
        }
    }

    fun getFileObjByUri(uri: Uri): JSONObject? {
        val fileObj = FileUtils.getPathFromUri(this, uri) ?: return null
        val fileJsonObj = JSONObject()
        fileJsonObj.put("file_name", fileObj.fileName)
        fileJsonObj.put("uri", fileObj.uri)
        return fileJsonObj
    }

    fun createArchiveFile(archiveType: String, fileName: String, password: String, fileInfos: JSONObject): JSONObject {
        try {
            when (archiveType) {
                "zip" -> {
                    return createZipFile(fileName, password, fileInfos)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return JSONObject()
    }

    fun createZipFile(fileName: String, password: String, fileInfos: JSONObject): JSONObject {
        val fileDir = File(context.cacheDir.path, "file_dir")
        if (fileDir.exists()) {
            fileDir.deleteRecursively()
        }
        fileDir.mkdir()
        val zipFile = File(context.cacheDir.path, fileName)
        if (zipFile.exists()) {
            zipFile.deleteRecursively()
        }
        zipFile.deleteOnExit()
        val zipParameters = ZipParameters()
        val zipFileObj = if (password.isNotEmpty()) {
            zipParameters.isEncryptFiles = true
            zipParameters.encryptionMethod = EncryptionMethod.ZIP_STANDARD
            ZipFile(zipFile, password.toCharArray())
        } else {
            ZipFile(zipFile)
        }
        for (key in fileInfos.keys()) {
            cloneFile(fileDir, JSON.parseObject(fileInfos.get(key).toString(), FileInfo::class.java))
        }
        val targetFiles = fileDir.listFiles()
        if (targetFiles != null) {
            for (fileItem in targetFiles) {
                if (fileItem.isDirectory) {
                    zipFileObj.addFolder(fileItem, zipParameters)
                } else {
                    zipFileObj.addFile(fileItem, zipParameters)
                }
            }
        }
        val fileJsonObj = JSONObject()
        fileJsonObj.put("archive_type", "zip")
        fileJsonObj.put("file_name", fileName)
        fileJsonObj.put("uri", zipFile.path)
        return fileJsonObj
    }

    fun cloneFile(fileDir: File, fileInfo: FileInfo) {
        val targetFile = File(fileDir.path, fileInfo.Name)
        if (fileInfo.ContentType == "directory") {
            if (targetFile.mkdir()) {
                for (entry in fileInfo.files.entries) {
                    cloneFile(targetFile, entry.value)
                }
            }
            return
        }
        val fileItem = File(fileInfo.Uri)
        fileItem.copyRecursively(targetFile)
        targetFile.deleteOnExit()
    }

    fun getFileHeaders(archiveType: String, uri: String, password: String): List<FileHeader> {
        when (archiveType) {
            "rar" -> {
                val rarFile = File(uri)
                val rarFileObj = Archive(rarFile)
                if (password.isNotEmpty()) {
                    rarFileObj.password = password
                }
                return rarFileObj.fileHeaders.map {
                    val fileHeader = FileHeader()
                    fileHeader.FileName = it.fileName
                    fileHeader.IsDirectory = it.isDirectory
                    if (fileHeader.IsDirectory) {
                        fileHeader.ContentType = "directory"
                    } else {
                        fileHeader.ContentType = URLConnection.getFileNameMap().getContentTypeFor(fileHeader.FileName)
                    }
                    fileHeader.LastModified = it.mTime.time / 1000
                    fileHeader.FileSize = it.dataSize
                    fileHeader
                }
            }
            else -> {
                val zipFile = File(uri)
                val zipFileObj = if (password.isNotEmpty()) {
                    ZipFile(zipFile, password.toCharArray())
                } else {
                    ZipFile(zipFile)
                }
                return zipFileObj.fileHeaders.map { zipFileHeader ->
                    val fileHeader = FileHeader()
                    fileHeader.FileName = zipFileHeader.fileName
                    fileHeader.IsDirectory = zipFileHeader.isDirectory
                    if (fileHeader.IsDirectory) {
                        fileHeader.ContentType = "directory"
                    } else {
                        fileHeader.ContentType = URLConnection.getFileNameMap().getContentTypeFor(fileHeader.FileName)
                    }
                    fileHeader.LastModified = zipFileHeader.lastModifiedTimeEpoch / 1000
                    fileHeader.FileSize = zipFileHeader.uncompressedSize
                    fileHeader
                }
            }
        }
    }

    fun extractFile(archiveType: String, uri: String, password: String, fileName: String): ExtractRes {
        val res = ExtractRes()
        when (archiveType) {
            "rar" -> {
                try {
                    val rarFile = File(uri)
                    val rarFileObj = Archive(rarFile)
                    if (password.isNotEmpty()) {
                        rarFileObj.password = password
                    }
                    val destPath = File(externalCacheDir!!.absolutePath, fileName)
                    if (destPath.exists()) {
                        destPath.deleteRecursively()
                    }
                    val matchedFileHeaders = rarFileObj.fileHeaders.filter {
                        it.fileName == fileName
                    }
                    if (matchedFileHeaders.isEmpty()) {
                        res.errCode = "uncompress_error"
                    } else {
                        destPath.createNewFile()
                        rarFileObj.extractFile(matchedFileHeaders[0], destPath.outputStream())
                        destPath.deleteOnExit()
                        res.targetUri = destPath.path
                        return res
                    }
                } catch (e: ZipException) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                    if (e.type == ZipException.Type.WRONG_PASSWORD) {
                        res.errCode = "wrong_password"
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                }
            }
            else -> {
                try {
                    val zipFile = File(uri)
                    val zipFileObj = if (password.isNotEmpty()) {
                        ZipFile(zipFile, password.toCharArray())
                    } else {
                        ZipFile(zipFile)
                    }
                    val destPath = File(externalCacheDir!!.absolutePath, fileName)
                    if (destPath.exists()) {
                        destPath.deleteRecursively()
                    }
                    zipFileObj.extractFile(fileName, externalCacheDir!!.absolutePath)
                    destPath.deleteOnExit()
                    res.targetUri = destPath.path
                    return res
                } catch (e: ZipException) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                    if (e.type == ZipException.Type.WRONG_PASSWORD) {
                        res.errCode = "wrong_password"
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                }
            }
        }
        return res
    }

    fun extractAll(archiveType: String, uri: String, password: String, targetDir: String): ExtractRes {
        val res = ExtractRes()
        when (archiveType) {
            "rar" -> {
                try {
                    val rarFile = File(uri)
                    val rarFileObj = Archive(rarFile)
                    if (password.isNotEmpty()) {
                        rarFileObj.password = password
                    }
                    val targetDirObj = File(targetDir)
                    if (!targetDirObj.exists()) {
                        targetDirObj.mkdir()
                    }
                    Junrar.extract(uri, targetDir)
                } catch (e: ZipException) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                    if (e.type == ZipException.Type.WRONG_PASSWORD) {
                        res.errCode = "wrong_password"
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                }
                if (res.errCode.isNotEmpty()) {
                    File(targetDir).deleteRecursively()
                }
            }
            else -> {
                try {
                    val zipFile = File(uri)
                    val zipFileObj = if (password.isNotEmpty()) {
                        ZipFile(zipFile, password.toCharArray())
                    } else {
                        ZipFile(zipFile)
                    }
                    zipFileObj.extractAll(targetDir)
                } catch (e: ZipException) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                    if (e.type == ZipException.Type.WRONG_PASSWORD) {
                        res.errCode = "wrong_password"
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    res.errCode = "uncompress_error"
                }
                if (res.errCode.isNotEmpty()) {
                    File(targetDir).deleteRecursively()
                }
            }
        }
        return res
    }
}
