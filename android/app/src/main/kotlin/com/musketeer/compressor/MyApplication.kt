package com.musketeer.compressor

import android.util.Log
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import io.flutter.app.FlutterApplication
import net.sf.sevenzipjbinding.SevenZip

class MyApplication : FlutterApplication() {
    companion object {
        val TAG = "MyApplication"
    }

    override fun onCreate() {
        super.onCreate()
        SevenZip.initSevenZipFromPlatformJAR()
        UMConfigure.init(this, "5fce4e9dbed37e4506c546b0", "google", UMConfigure.DEVICE_TYPE_PHONE, "")
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO)
    }
}