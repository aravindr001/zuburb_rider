package com.zuburb.rider

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
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

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zuburb_rider/battery")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"isBatteryOptimizationDisabled" -> {
						val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
						result.success(pm.isIgnoringBatteryOptimizations(packageName))
					}
					"requestDisableBatteryOptimization" -> {
						try {
							val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
							intent.data = Uri.parse("package:$packageName")
							intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
							startActivity(intent)
							result.success(true)
						} catch (e: Exception) {
							result.success(false)
						}
					}
					else -> result.notImplemented()
				}
			}
	}
}
