package com.heliolytics.heliolytics

import android.app.Notification
import android.service.notification.StatusBarNotification

object WhatsAppCallDetector {
    private val packages = setOf("com.whatsapp", "com.whatsapp.w4b")

    fun isWhatsAppPackage(packageName: String): Boolean = packageName in packages

    fun isIncomingCall(sbn: StatusBarNotification): Boolean {
        if (!isWhatsAppPackage(sbn.packageName)) return false
        val notification = sbn.notification ?: return false
        val extras = notification.extras ?: return false

        if (Notification.CATEGORY_CALL == notification.category) {
            return true
        }

        val channelId = notification.channelId ?: ""
        if (channelId.contains("call", ignoreCase = true)) return true

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val combined = "$title $text".lowercase()
        val keywords = listOf(
            "incoming voice call",
            "incoming video call",
            "incoming call",
            "voice call",
            "video call",
            "calling",
        )
        return keywords.any { combined.contains(it) }
    }

    fun callerName(sbn: StatusBarNotification): String {
        val extras = sbn.notification?.extras ?: return ""
        return extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
    }
}
