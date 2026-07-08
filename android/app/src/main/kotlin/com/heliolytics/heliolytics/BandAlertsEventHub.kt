package com.heliolytics.heliolytics

import io.flutter.plugin.common.EventChannel
import java.util.ArrayDeque

object BandAlertsEventHub {
    private var sink: EventChannel.EventSink? = null
    private val pending = ArrayDeque<Map<String, Any?>>(32)

    fun setSink(events: EventChannel.EventSink?) {
        sink = events
        if (events == null) return
        while (pending.isNotEmpty()) {
            events.success(pending.removeFirst())
        }
    }

    fun emit(type: String, fields: Map<String, Any?>) {
        val payload = HashMap<String, Any?>(fields.size + 1)
        payload["type"] = type
        payload.putAll(fields)
        val active = sink
        if (active == null) {
            if (pending.size >= 32) pending.removeFirst()
            pending.addLast(payload)
            return
        }
        active.success(payload)
    }
}
