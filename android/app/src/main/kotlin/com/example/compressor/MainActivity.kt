package com.example.compressor

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONArray
import org.json.JSONObject


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.musketeer.compressor"

    private val PICK_FILE = 1
    private var resultCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor, CHANNEL).setMethodCallHandler(object: MethodChannel.MethodCallHandler{
            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                if (call.method == "pick_file") {
                    val intent = Intent(Intent.ACTION_GET_CONTENT)
                    intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    intent.type = "*/*"
                    startActivityForResult(intent, PICK_FILE)
                    resultCallback = result
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
}
