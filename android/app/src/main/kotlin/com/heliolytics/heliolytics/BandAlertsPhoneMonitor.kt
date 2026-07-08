package com.heliolytics.heliolytics

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat

class BandAlertsPhoneMonitor(private val context: Context) {
    private val telephony =
        context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager?
    private var ringing = false

    private val telephonyCallback =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) {
                    handleState(state, null)
                }
            }
        } else {
            null
        }

    @Suppress("DEPRECATION")
    private val phoneStateListener = object : PhoneStateListener() {
        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
            handleState(state, phoneNumber)
        }
    }

    fun start() {
        if (!hasPhonePermission()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && telephonyCallback != null) {
            telephony?.registerTelephonyCallback(context.mainExecutor, telephonyCallback)
        } else {
            @Suppress("DEPRECATION")
            telephony?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
        }
    }

    fun stop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && telephonyCallback != null) {
            telephony?.unregisterTelephonyCallback(telephonyCallback)
        } else {
            @Suppress("DEPRECATION")
            telephony?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
        }
        ringing = false
    }

    private fun hasPhonePermission(): Boolean =
        ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_PHONE_STATE,
        ) == PackageManager.PERMISSION_GRANTED

    private fun handleState(state: Int, number: String?) {
        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                ringing = true
                BandAlertsEventHub.emit(
                    "call_ring",
                    mapOf(
                        "callerName" to (number ?: ""),
                        "callerNumber" to (number ?: ""),
                    ),
                )
            }
            TelephonyManager.CALL_STATE_OFFHOOK,
            TelephonyManager.CALL_STATE_IDLE,
            -> {
                if (ringing) {
                    ringing = false
                    BandAlertsEventHub.emit("call_end", emptyMap())
                }
            }
        }
    }
}
