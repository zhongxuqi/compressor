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
import net.sf.sevenzipjbinding.*
import net.sf.sevenzipjbinding.impl.OutItemFactory
import net.sf.sevenzipjbinding.impl.RandomAccessFileInStream
import net.sf.sevenzipjbinding.impl.RandomAccessFileOutStream
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.RandomAccessFile
import java.net.URLConnection
import java.util.*
import java.util.concurrent.Executors
import kotlin.collections.ArrayList
import kotlin.collections.HashMap


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
                        try {
                            val req = call.arguments as HashMap<String, String>
                            val fileHeaders = getFileHeaders(req["archive_type"]!!, req["uri"]!!, req["password"]!!)
                            result.success(JSON.toJSONString(fileHeaders))
                        } catch(e: java.lang.Exception) {
                            e.printStackTrace()
                        }
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
                "7z" -> {
                    return create7zFile(fileName, password, fileInfos)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return JSONObject()
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

    fun extractFile(fileMap: HashMap<String, File>, parentPath: String, fileInfo: FileInfo) {
        val pathPrefix = if (parentPath.isNotEmpty()) {
            "$parentPath/"
        } else {
            ""
        }
        if (fileInfo.ContentType == "directory") {
            for (entry in fileInfo.files.entries) {
                extractFile(fileMap, "$pathPrefix${fileInfo.Name}", entry.value)
            }
            return
        }
        fileMap["$pathPrefix${fileInfo.Name}"] = File(fileInfo.Uri)
    }

    fun create7zFile(fileName: String, password: String, fileInfos: JSONObject): JSONObject {
        val fileMap = HashMap<String, File>()
        for (key in fileInfos.keys()) {
            extractFile(fileMap, "", JSON.parseObject(fileInfos.get(key).toString(), FileInfo::class.java))
        }
        val fileEntries = fileMap.entries.toList()
        val sevenZFile = File(context.cacheDir.path, fileName)
        if (sevenZFile.exists()) {
            sevenZFile.deleteRecursively()
        }
        sevenZFile.createNewFile()
        sevenZFile.deleteOnExit()
        var raf: RandomAccessFile? = null
        var outArchive: IOutCreateArchive7z? = null
        try {
            raf = RandomAccessFile(sevenZFile.path, "rw")
            outArchive = SevenZip.openOutArchive7z()
            outArchive?.setLevel(5)
            outArchive?.setSolid(true)
            outArchive?.setSolidFiles(fileEntries.size)
            outArchive?.setThreadCount(1)
            Log.d(TAG, "begin createArchive")
            outArchive?.createArchive(RandomAccessFileOutStream(raf), fileEntries.size, object: IOutCreateCallback<IOutItem7z>{
                override fun setOperationResult(p0: Boolean) {
                    Log.d(TAG, "setOperationResult $p0")
                }

                override fun setCompleted(p0: Long) {
                    Log.d(TAG, "setCompleted $p0")
                }

                override fun getItemInformation(index: Int, outItemFactory: OutItemFactory<IOutItem7z>?): IOutItem7z {
                    val item = outItemFactory!!.createOutItem()
                    item.dataSize = fileEntries[index].value.length()
                    item.propertyPath = fileEntries[index].key
                    return item
                }

                override fun getStream(index: Int): ISequentialInStream {
                    return MyFileOutStream(fileEntries[index].value.inputStream())
                }

                override fun setTotal(p0: Long) {
                    Log.d(TAG, "setTotal $p0")
                }
            })
            Log.d(TAG, "end createArchive")
        } catch (e: SevenZipException) {
            e.printStackTrace()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
//            outArchive?.close()
//            raf?.close()
        }
        val fileJsonObj = JSONObject()
        fileJsonObj.put("archive_type", "7z")
        fileJsonObj.put("file_name", fileName)
        fileJsonObj.put("uri", sevenZFile.path)
        return fileJsonObj
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
            "7z" -> {
                val sevenZipFile = File(uri)
                val randomAccessFile = RandomAccessFile(sevenZipFile, "r")
                val inStream = RandomAccessFileInStream(randomAccessFile)
                val inArchive = if (password.isNotEmpty()) {
                    SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP, inStream, password)
                } else {
                    SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP, inStream)
                }
                val fileHeaders = ArrayList<FileHeader>()
                for (i in 0 until inArchive.numberOfItems) {
                    val fileHeader = FileHeader()
                    fileHeader.FileName = inArchive.getStringProperty(i, PropID.PATH)
                    fileHeader.IsDirectory = inArchive.getProperty(i, PropID.IS_FOLDER) as Boolean
                    if (fileHeader.IsDirectory) {
                        fileHeader.ContentType = "directory"
                    } else {
                        fileHeader.ContentType = URLConnection.getFileNameMap().getContentTypeFor(fileHeader.FileName)
                    }
                    fileHeader.LastModified = (inArchive.getProperty(i, PropID.LAST_MODIFICATION_TIME) as Date).time / 1000
                    fileHeader.FileSize = inArchive.getProperty(i, PropID.SIZE) as Long
                    fileHeaders.add(fileHeader)
                }
                inArchive.close()
                inStream.close()
                return fileHeaders
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
            "7z" -> {
                try {
                    val sevenZipFile = File(uri)
                    val randomAccessFile = RandomAccessFile(sevenZipFile, "r")
                    val inStream = RandomAccessFileInStream(randomAccessFile)
                    val inArchive = if (password.isNotEmpty()) {
                        SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP, inStream, password)
                    } else {
                        SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP, inStream)
                    }
                    var fileIndex = -1
                    for (i in 0 until inArchive.numberOfItems) {
                        if (inArchive.getStringProperty(i, PropID.PATH) == fileName) {
                            fileIndex = i
                            break
                        }
                    }
                    val destPath = File(externalCacheDir!!.absolutePath, fileName)
                    if (destPath.exists()) {
                        destPath.deleteRecursively()
                    }
                    if (fileIndex < 0) {
                        res.errCode = "uncompress_error"
                    } else {
                        destPath.createNewFile()
                        val outStream = RandomAccessFileOutStream(RandomAccessFile(destPath, "rw"))
                        inArchive.extractSlow(fileIndex, outStream)
                        destPath.deleteOnExit()
                        res.targetUri = destPath.path
                        return res
                    }
                    inArchive.close()
                    inStream.close()
                } catch(e: Exception) {
                    e.printStackTrace()
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
            "7z" -> {
                try {
                    val sevenZipFile = File(uri)
                    val randomAccessFile = RandomAccessFile(sevenZipFile, "r")
                    val inStream = RandomAccessFileInStream(randomAccessFile)
                    val inArchive = if (password.isNotEmpty()) {
                        SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP, inStream, password)
                    } else {
                        SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP, inStream)
                    }
                    val targetDirObj = File(targetDir)
                    if (!targetDirObj.exists()) {
                        targetDirObj.mkdir()
                    }
                    inArchive.extract(null, false, object: IArchiveExtractCallback{
                        override fun setOperationResult(p0: ExtractOperationResult?) {
                            Log.d(TAG, "setOperationResult ${p0.toString()}")
                        }

                        override fun setCompleted(p0: Long) {
                            Log.d(TAG, "setCompleted ${p0.toString()}")
                        }

                        override fun getStream(p0: Int, p1: ExtractAskMode?): ISequentialOutStream {
                            Log.d(TAG, "getStream ${p0.toString()} ${p1.toString()}")
                            val outFile = File(targetDir, inArchive.getStringProperty(p0, PropID.PATH))
                            return RandomAccessFileOutStream(RandomAccessFile(outFile, "rw"))
                        }

                        override fun prepareOperation(p0: ExtractAskMode?) {
                            Log.d(TAG, "prepareOperation ${p0.toString()}")
                        }

                        override fun setTotal(p0: Long) {
                            Log.d(TAG, "setTotal ${p0.toString()}")
                        }
                    })
                    inArchive.close()
                    inStream.close()
                } catch(e: Exception) {
                    e.printStackTrace()
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

class MyFileOutStream(val inputStream: FileInputStream): ISequentialInStream {
    override fun close() {
        inputStream.close()
    }

    override fun read(p0: ByteArray?): Int {
        return inputStream.read(p0)
    }
}