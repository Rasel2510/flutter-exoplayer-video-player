package com.example.flutter_video_player

import android.app.Notification
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/// Foreground service that keeps the app process alive while audio/video plays
/// in the background, so playback survives the screen turning off or the app
/// being sent to the background. The notification it shows in the foreground is
/// built by MainActivity (which owns the MediaSession) and handed over via the
/// start intent.
class PlaybackService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForegroundCompat()
                stopSelf()
            }
            else -> {
                val notification = extractNotification(intent)
                if (notification == null) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            }
        }
        return START_NOT_STICKY
    }

    @Suppress("DEPRECATION")
    private fun extractNotification(intent: Intent?): Notification? {
        intent ?: return null
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(EXTRA_NOTIFICATION, Notification::class.java)
        } else {
            intent.getParcelableExtra(EXTRA_NOTIFICATION)
        }
    }

    @Suppress("DEPRECATION")
    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
    }

    override fun onDestroy() {
        stopForegroundCompat()
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "com.example.flutter_video_player.PLAYBACK_START"
        const val ACTION_STOP = "com.example.flutter_video_player.PLAYBACK_STOP"
        const val EXTRA_NOTIFICATION = "notification"
        const val NOTIFICATION_ID = 1001
    }
}
