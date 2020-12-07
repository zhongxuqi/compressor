package com.musketeer.compressor

import android.util.Log
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import io.flutter.app.FlutterApplication

class MyApplication : FlutterApplication() {
    companion object {
        val TAG = "MyApplication"
    }

    override fun onCreate() {
        super.onCreate()
        UMConfigure.init(this, "5fce4e9dbed37e4506c546b0", "main", UMConfigure.DEVICE_TYPE_PHONE, "")
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO)
    }
}