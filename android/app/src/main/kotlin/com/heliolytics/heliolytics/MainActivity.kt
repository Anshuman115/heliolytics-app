package com.heliolytics.heliolytics

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.heliolytics/band_alerts"
    private val eventChannelName = "com.heliolytics/band_alerts_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationListenerEnabled" -> {
                        result.success(isNotificationListenerEnabled())
                    }
                    "openNotificationListenerSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "startForegroundService" -> {
                        BandAlertsForegroundService.start(this)
                        result.success(null)
                    }
                    "stopForegroundService" -> {
                        BandAlertsForegroundService.stop(this)
                        result.success(null)
                    }
                    "getBluetoothAdapterName" -> {
                        result.success(readBluetoothAdapterName())
                    }
                    else -> result.notImplemented()
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BandAlertsEventHub.setSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    BandAlertsEventHub.setSink(null)
                }
            })
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val component = ComponentName(this, BandAlertsNotificationListener::class.java)
        return flat.contains(component.flattenToString())
    }

    private fun readBluetoothAdapterName(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return null
        }
        return BluetoothAdapter.getDefaultAdapter()?.name
    }
}
