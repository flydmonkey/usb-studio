package com.usbcamera.capture.usb_capture

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class CaptureRecordService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val ticker = object : Runnable {
        override fun run() {
            val hud = CaptureRuntime.engine?.recordingHud()
            if (hud == null) {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return
            }
            startFg(buildNotification(hud))
            handler.postDelayed(this, 1000L)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureChannel()
        val hud = CaptureRuntime.engine?.recordingHud() ?: RecordingHud(0L, 1, true)
        startFg(buildNotification(hud))
        handler.removeCallbacks(ticker)
        handler.post(ticker)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(ticker)
        super.onDestroy()
    }

    private fun startFg(notification: Notification) {
        if (Build.VERSION.SDK_INT >= 34) {
            val hud = CaptureRuntime.engine?.recordingHud()
            val types = foregroundServiceTypes(hud)
            startForeground(NOTIFICATION_ID, notification, types)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun foregroundServiceTypes(hud: RecordingHud?): Int {
        if (hud == null) {
            return ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
        }
        val recordingOrStreaming = hud.recording || hud.streaming
        return when {
            recordingOrStreaming && hud.httpServing ->
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            recordingOrStreaming ->
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            hud.httpServing -> ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            else -> ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
        }
    }

    private fun buildNotification(hud: RecordingHud): Notification {
        val ctx = UiLocale.wrap(this)
        val elapsed = formatElapsed(hud.elapsedMs)
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val baseText = when {
            hud.recording && hud.streaming && hud.segmented ->
                ctx.getString(
                    R.string.notification_recording_stream_segment,
                    elapsed,
                    hud.segmentIndex,
                )
            hud.recording && hud.streaming ->
                ctx.getString(R.string.notification_recording_stream, elapsed)
            hud.streaming && !hud.recording ->
                ctx.getString(R.string.notification_streaming, elapsed)
            hud.recording && hud.segmented ->
                ctx.getString(
                    R.string.notification_recording_segment,
                    elapsed,
                    hud.segmentIndex,
                )
            hud.recording -> ctx.getString(R.string.notification_recording, elapsed)
            hud.httpServing -> ctx.getString(R.string.notification_lan)
            else -> ctx.getString(R.string.app_name)
        }
        val text = if (hud.httpServing && (hud.recording || hud.streaming)) {
            ctx.getString(R.string.notification_lan_suffix, baseText)
        } else {
            baseText
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(ctx.getString(R.string.app_name))
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pending)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            UiLocale.wrap(this).getString(R.string.notification_channel),
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "usb_capture_recording"
        private const val NOTIFICATION_ID = 2402

        fun start(context: Context) {
            val intent = Intent(context, CaptureRecordService::class.java)
            if (Build.VERSION.SDK_INT >= 26) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun refresh(context: Context) {
            if (CaptureRuntime.engine?.recordingHud() == null) return
            start(context)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CaptureRecordService::class.java))
        }

        fun formatElapsed(elapsedMs: Long): String {
            val total = (elapsedMs / 1000).coerceAtLeast(0)
            val hours = total / 3600
            val minutes = (total % 3600) / 60
            val seconds = total % 60
            return "%02d:%02d:%02d".format(hours, minutes, seconds)
        }
    }
}
