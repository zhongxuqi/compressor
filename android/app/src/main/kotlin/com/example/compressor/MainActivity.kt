package com.example.compressor

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import com.alibaba.fastjson.JSON
import com.alibaba.fastjson.annotation.JSONField
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import net.lingala.zip4j.ZipFile
import net.lingala.zip4j.model.ZipParameters
import org.json.JSONArray
import org.json.JSONObject
import java.io.File


class FileItem {
    @JSONField(name="file_name")
    var FileName: String = ""
    @JSONField(name="uri")
    var Uri: String = ""
}

class MainActivity: FlutterActivity() {
    companion object {
        val TAG = "MainActivity"
    }
    private val CHANNEL = "com.musketeer.compressor"

    private val PICK_FILE = 1
    private var resultCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor, CHANNEL).setMethodCallHandler(object: MethodChannel.MethodCallHandler{
            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                if (call.method == "pick_file") {
                    val req = call.arguments as HashMap<String, String>
                    val intent = Intent(Intent.ACTION_GET_CONTENT)
                    intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    intent.type = req["mime_type"]!!
                    startActivityForResult(intent, PICK_FILE)
                    resultCallback = result
                } else if (call.method == "create_archive") {
                    val req = call.arguments as HashMap<String, String>
                    val files = JSON.parseArray(req["files"]!!, FileItem::class.java)
                    result.success(createArchiveFile(req["file_name"]!!, req["password"]!!, files).toString())
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

    fun createArchiveFile(fileName: String, password: String, files: List<FileItem>): JSONObject {
        val fileDir = File(context.cacheDir.path, "file_dir")
        if (fileDir.exists()) {
            fileDir.deleteRecursively()
        }
        fileDir.mkdir()
        val zipFile = File(context.cacheDir.path, "${fileName}.zip")
        if (zipFile.exists()) {
            zipFile.deleteRecursively()
        }
        zipFile.deleteOnExit()
        val zipFileObj = if (!password.isEmpty()) {
            ZipFile(zipFile, password.toCharArray())
        } else {
            ZipFile(zipFile)
        }
        for (fileData in files) {
            val targetFile = File(fileDir.path, fileData.FileName)
            val fileItem = File(fileData.Uri)
            fileItem.copyRecursively(targetFile)
            if (targetFile.isDirectory) {
                zipFileObj.addFolder(targetFile)
            } else {
                zipFileObj.addFile(targetFile)
            }
            targetFile.deleteOnExit()
        }
        val fileJsonObj = JSONObject()
        fileJsonObj.put("file_name", fileName)
        fileJsonObj.put("uri", zipFile.path)
        return fileJsonObj
    }
}
