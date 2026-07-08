package com.heliolytics.heliolytics

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BandAlertsForegroundService : Service() {
    private var phoneMonitor: BandAlertsPhoneMonitor? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannel()
        val launch = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Band alerts active")
            .setContentText("Heliolytics is connected to your strap")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(launch)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
        startForeground(NOTIFICATION_ID, notification)
        phoneMonitor = BandAlertsPhoneMonitor(this).also { it.start() }
        return START_STICKY
    }

    override fun onDestroy() {
        phoneMonitor?.stop()
        phoneMonitor = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Band alerts",
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = "Keeps strap connection alive for alerts"
        mgr.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "band_alerts"
        private const val NOTIFICATION_ID = 41001

        fun start(context: Context) {
            val intent = Intent(context, BandAlertsForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BandAlertsForegroundService::class.java))
        }
    }
}
