package com.heliolytics.heliolytics

import android.app.Notification
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class BandAlertsNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        if (sbn.packageName == packageName) return
        val n = sbn.notification ?: return
        if (n.flags and Notification.FLAG_ONGOING_EVENT != 0) return
        if (n.flags and Notification.FLAG_FOREGROUND_SERVICE != 0) return

        val extras = n.extras ?: Bundle.EMPTY
        val title = readTitle(extras)
        val body = readBody(extras)
        if (title.isEmpty() && body.isEmpty()) return

        BandAlertsEventHub.emit(
            "app_notification",
            mapOf(
                "id" to sbn.id,
                "package" to sbn.packageName,
                "title" to title,
                "body" to body,
            ),
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) = Unit

    private fun readTitle(extras: Bundle): String {
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        if (!title.isNullOrBlank()) return title.trim()
        val big = extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString()
        return big?.trim() ?: ""
    }

    private fun readBody(extras: Bundle): String {
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        if (!text.isNullOrBlank()) return text.trim()
        val big = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        if (!big.isNullOrBlank()) return big.trim()
        val lines = extras.getCharSequenceArray("android.textLines")
        if (lines != null && lines.isNotEmpty()) {
            return lines.mapNotNull { it?.toString()?.trim() }
                .filter { it.isNotEmpty() }
                .joinToString(" ")
        }
        return ""
    }
}
