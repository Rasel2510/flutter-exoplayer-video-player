package com.example.flutter_video_player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.util.Rational
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.support.v4.media.MediaMetadataCompat
import androidx.core.content.ContextCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.flutter_video_player/media_session"
    private val NOTIFICATION_CHANNEL_ID = "video_player_playback"

    private var mediaSession: MediaSessionCompat? = null
    private var methodChannel: MethodChannel? = null
    private var mediaStoreBridge: MediaStoreBridge? = null
    private var exoPlugin: ExoPlayerPlugin? = null

    // "Open with" / VIEW-intent delivery.
    private var openFileChannel: MethodChannel? = null
    private var pendingOpenFile: String? = null

    private var isPlaying = false
    private var videoTitle = "Video Player"

    // Lock-screen / notification album art (the current video's thumbnail),
    // cached so we only decode the file when its path actually changes.
    private var albumArt: Bitmap? = null
    private var albumArtPath: String? = null

    // ── Flutter engine setup ──────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets MediaActionReceiver forward notification-button taps back to us.
        activeInstance = this
        createNotificationChannel()

        // Fast MediaStore video index + live ContentObserver notifications.
        mediaStoreBridge =
            MediaStoreBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)

        // Native Media3/ExoPlayer playback engine (renders into Flutter textures).
        exoPlugin = ExoPlayerPlugin(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
            flutterEngine.renderer,
        )

        // "Open with" channel — hands externally-opened videos to Flutter.
        openFileChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.flutter_video_player/open_file",
        )
        openFileChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "getOpenedFile") {
                result.success(pendingOpenFile)
                pendingOpenFile = null
            } else {
                result.notImplemented()
            }
        }
        // Capture the intent that launched us (cold start via "Open with").
        handleViewIntent(intent)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {

                "setMetadata" -> {
                    videoTitle = call.argument<String>("title")?.takeIf { it.isNotBlank() } ?: "Video Player"
                    val durationMs = call.argument<Int>("duration")?.toLong() ?: 0L
                    loadAlbumArt(call.argument<String>("artPath"))
                    ensureSession()
                    val meta = MediaMetadataCompat.Builder()
                        .putString(MediaMetadataCompat.METADATA_KEY_TITLE, videoTitle)
                        .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
                    albumArt?.let {
                        meta.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, it)
                        meta.putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, it)
                    }
                    mediaSession?.setMetadata(meta.build())
                    mediaSession?.isActive = true
                    postNotification()
                    result.success(null)
                }

                "setPlaybackState" -> {
                    isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val positionMs = call.argument<Int>("position")?.toLong() ?: 0L
                    val speed = call.argument<Double>("speed")?.toFloat() ?: 1.0f
                    val state = if (isPlaying) PlaybackStateCompat.STATE_PLAYING
                                else          PlaybackStateCompat.STATE_PAUSED
                    ensureSession()
                    mediaSession?.setPlaybackState(
                        PlaybackStateCompat.Builder()
                            .setState(state, positionMs, speed)
                            .setActions(
                                PlaybackStateCompat.ACTION_PLAY              or
                                PlaybackStateCompat.ACTION_PAUSE             or
                                PlaybackStateCompat.ACTION_PLAY_PAUSE        or
                                PlaybackStateCompat.ACTION_SKIP_TO_NEXT      or
                                PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS  or
                                PlaybackStateCompat.ACTION_SEEK_TO
                            )
                            .build()
                    )
                    postNotification()
                    result.success(null)
                }

                "release" -> {
                    cancelNotification()
                    mediaSession?.isActive = false
                    mediaSession?.release()
                    mediaSession = null
                    isPlaying = false
                    result.success(null)
                }

                "moveTaskToBack" -> {
                    // Background the app (like Home) instead of finishing the
                    // activity, so the Flutter engine + playback stay alive
                    // when the user backs out during audio mode.
                    moveTaskToBack(true)
                    result.success(null)
                }

                "enterPip" -> {
                    enterPip(
                        call.argument<Int>("width") ?: 16,
                        call.argument<Int>("height") ?: 9,
                    )
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ── Notification channel (required on API 26+) ────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Video Player",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Media playback controls"
                setShowBadge(false)
            }
            notificationManager().createNotificationChannel(channel)
        }
    }

    // ── Album art ─────────────────────────────────────────────────────────────

    private fun loadAlbumArt(path: String?) {
        if (path == albumArtPath) return
        albumArtPath = path
        albumArt = if (path != null) {
            try { BitmapFactory.decodeFile(path) } catch (e: Exception) { null }
        } else {
            null
        }
    }

    // ── Post / cancel media-style notification ────────────────────────────────
    // Built here (MainActivity owns the MediaSession) and handed to the
    // foreground PlaybackService, which keeps the process alive so playback
    // survives the screen turning off / the app going to the background.

    private fun postNotification() {
        val notification = buildNotification() ?: return
        val intent = Intent(this, PlaybackService::class.java).apply {
            action = PlaybackService.ACTION_START
            putExtra(PlaybackService.EXTRA_NOTIFICATION, notification)
        }
        try {
            ContextCompat.startForegroundService(this, intent)
        } catch (e: Exception) {
            // Background-start limits (Android 12+) can reject this; fall back
            // to a plain notification so the controls still appear.
            try {
                notificationManager().notify(PlaybackService.NOTIFICATION_ID, notification)
            } catch (_: Exception) {}
        }
    }

    private fun buildNotification(): Notification? {
        val session = mediaSession ?: return null
        return try {
            val immutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE else 0

            // FIX: getLaunchIntentForPackage() can return null on some devices.
            // Fall back to an explicit MainActivity intent to prevent NPE.
            val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
                }

            val contentPi = PendingIntent.getActivity(
                this, 0, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
            )

            // Route notification buttons through our own receiver, which
            // forwards straight to Flutter.
            val prevPi = buildActionIntent("previous", 1)
            val playPausePi = buildActionIntent(if (isPlaying) "pause" else "play", 2)
            val nextPi = buildActionIntent("next", 3)

            // Crisp Material vector icons instead of the low-res android.R
            // system media drawables.
            val playPauseIcon = if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play
            val playPauseLabel = if (isPlaying) "Pause" else "Play"

            NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle(videoTitle)
                .setContentText(if (isPlaying) "Playing" else "Paused")
                .setSmallIcon(R.drawable.ic_stat_music)
                .setLargeIcon(albumArt)
                .setContentIntent(contentPi)
                .setOngoing(isPlaying)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setSilent(true)
                .addAction(R.drawable.ic_skip_previous, "Previous", prevPi)
                .addAction(playPauseIcon, playPauseLabel, playPausePi)
                .addAction(R.drawable.ic_skip_next, "Next", nextPi)
                .setStyle(
                    MediaStyle()
                        .setMediaSession(session.sessionToken)
                        .setShowActionsInCompactView(0, 1, 2)
                )
                .build()
        } catch (e: Exception) {
            null
        }
    }

    // Build a notification-button PendingIntent that broadcasts to our own
    // MediaActionReceiver with the action name ("play"/"pause"/"next"/
    // "previous") — the same strings the Dart side already handles.
    private fun buildActionIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, MediaActionReceiver::class.java).apply {
            this.action = MediaActionReceiver.ACTION
            putExtra(MediaActionReceiver.EXTRA_ACTION, action)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getBroadcast(this, requestCode, intent, flags)
    }

    private fun cancelNotification() {
        try {
            val intent = Intent(this, PlaybackService::class.java).apply {
                action = PlaybackService.ACTION_STOP
            }
            startService(intent)
        } catch (e: Exception) {
            try { notificationManager().cancel(PlaybackService.NOTIFICATION_ID) } catch (_: Exception) {}
        }
    }

    // ── MediaSessionCompat ────────────────────────────────────────────────────

    private fun ensureSession() {
        if (mediaSession != null) return

        val immutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE else 0

        // FIX: null-safe launch intent fallback
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
        val sessionActivityPi = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
        )

        mediaSession = MediaSessionCompat(this, "VideoPlayer").apply {
            setSessionActivity(sessionActivityPi)
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay()            { dispatchToFlutter("play") }
                override fun onPause()           { dispatchToFlutter("pause") }
                override fun onSkipToNext()      { dispatchToFlutter("next") }
                override fun onSkipToPrevious()  { dispatchToFlutter("previous") }
                override fun onSeekTo(pos: Long) { dispatchSeekToFlutter(pos) }
            })
        }
    }

    // Handles a notification-button tap. Flips the play/pause state in the
    // notification immediately — before the Dart round-trip and the playback
    // stream echo that would otherwise gate the icon update — so the control
    // feels instant. The real playback state from Flutter confirms/corrects it.
    private fun onRemoteAction(action: String) {
        when (action) {
            "play"  -> { isPlaying = true;  postNotification() }
            "pause" -> { isPlaying = false; postNotification() }
        }
        dispatchToFlutter(action)
    }

    private fun dispatchToFlutter(action: String) {
        try {
            methodChannel?.invokeMethod("onMediaAction", action)
        } catch (e: Exception) {
            // Flutter engine may have detached — swallow to prevent native crash.
        }
    }

    private fun dispatchSeekToFlutter(posMs: Long) {
        try {
            methodChannel?.invokeMethod("onMediaSeek", posMs)
        } catch (e: Exception) {
            // Flutter engine may have detached — swallow to prevent native crash.
        }
    }

    // ── "Open with" / VIEW intents ────────────────────────────────────────────

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleViewIntent(intent)
    }

    private fun handleViewIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        val path = resolveToPath(uri) ?: return
        // If Flutter is already attached, deliver immediately; otherwise stash it
        // for the Dart side to pull on startup via getOpenedFile.
        val channel = openFileChannel
        if (channel != null) {
            channel.invokeMethod("onOpenFile", path)
        } else {
            pendingOpenFile = path
        }
        // Always keep it pending too, so a cold-start getOpenedFile still finds it.
        pendingOpenFile = path
    }

    /// Turns a VIEW intent's data URI into something media_kit can play: a real
    /// file path when resolvable, otherwise the raw URI string.
    private fun resolveToPath(uri: Uri): String? {
        return when (uri.scheme) {
            "file" -> uri.path
            "content" -> queryDataColumn(uri) ?: uri.toString()
            else -> uri.toString()
        }
    }

    private fun queryDataColumn(uri: Uri): String? {
        return try {
            contentResolver.query(
                uri, arrayOf(MediaStore.Video.Media.DATA), null, null, null,
            )?.use { c ->
                if (c.moveToFirst()) {
                    val idx = c.getColumnIndex(MediaStore.Video.Media.DATA)
                    if (idx >= 0) c.getString(idx) else null
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    // ── Picture-in-Picture ────────────────────────────────────────────────────

    private fun enterPip(width: Int, height: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            // Android only accepts aspect ratios in roughly [0.418, 2.39];
            // clamp out-of-range videos to 16:9 to avoid an exception.
            val w = width.coerceAtLeast(1)
            val h = height.coerceAtLeast(1)
            val ratio = w.toFloat() / h.toFloat()
            val rational = if (ratio < 0.42f || ratio > 2.39f) {
                Rational(16, 9)
            } else {
                Rational(w, h)
            }
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(rational)
                .build()
            enterPictureInPictureMode(params)
        } catch (e: Exception) {
            // Device may not support PiP, or it's disabled in system settings.
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        // Notify Flutter so it can hide controls, gesture layer, etc.
        methodChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onDestroy() {
        cancelNotification()
        mediaSession?.release()
        mediaSession = null
        methodChannel = null
        mediaStoreBridge?.dispose()
        mediaStoreBridge = null
        exoPlugin?.dispose()
        exoPlugin = null
        openFileChannel?.setMethodCallHandler(null)
        openFileChannel = null
        if (activeInstance === this) activeInstance = null
        super.onDestroy()
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun notificationManager() =
        getSystemService(NotificationManager::class.java)

    companion object {
        // The currently-attached activity, used by MediaActionReceiver to
        // forward notification-button taps back into the Flutter engine.
        private var activeInstance: MainActivity? = null

        fun dispatchMediaAction(action: String) {
            activeInstance?.onRemoteAction(action)
        }
    }
}

// Receives notification-button broadcasts and forwards them to Flutter via the
// active MainActivity. Declared (non-exported) in AndroidManifest.xml.
class MediaActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra(EXTRA_ACTION) ?: return
        MainActivity.dispatchMediaAction(action)
    }

    companion object {
        const val ACTION = "com.example.flutter_video_player.MEDIA_ACTION"
        const val EXTRA_ACTION = "media_action"
    }
}
