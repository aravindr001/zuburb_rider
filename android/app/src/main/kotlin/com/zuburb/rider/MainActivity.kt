package com.zuburb.rider

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zuburb_rider/maps")
			.setMethodCallHandler { call, result ->
				if (call.method == "getApiKey") {
					try {
						val appInfo = packageManager.getApplicationInfo(
							packageName,
							PackageManager.GET_META_DATA
						)
						val key = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
						result.success(key)
					} catch (e: Exception) {
						result.success(null)
					}
				} else {
					result.notImplemented()
				}
			}
	}
}
