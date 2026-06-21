package com.example.flutter_video_player

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.text.CueGroup
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

/// Native Media3/ExoPlayer bridge. One [ExoInstance] per Flutter engine player;
/// commands arrive on a shared MethodChannel keyed by playerId, events go back
/// on a per-instance EventChannel ("exo/events/<id>"). Video renders into a
/// Flutter SurfaceTexture so it composites inside the Flutter scene.
class ExoPlayerPlugin(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val textures: TextureRegistry,
) : MethodChannel.MethodCallHandler {

    private val methodChannel = MethodChannel(messenger, "exo/methods").also {
        it.setMethodCallHandler(this)
    }

    private val players = HashMap<Int, ExoInstance>()
    private var nextId = 1
    private val main = Handler(Looper.getMainLooper())

    fun dispose() {
        for (p in players.values) p.release()
        players.clear()
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "create") {
            main.post {
                try {
                    val id = nextId++
                    players[id] = ExoInstance(id, context, messenger, textures, main)
                    result.success(
                        mapOf("playerId" to id, "textureId" to players[id]!!.textureId),
                    )
                } catch (e: Exception) {
                    result.error("create_failed", e.message, null)
                }
            }
            return
        }
        if (call.method == "probeDuration") {
            // Runs off the player path entirely — a stateless metadata read.
            Thread {
                val ms = probeDurationMs(call.argument<String>("path"))
                main.post { result.success(ms) }
            }.start()
            return
        }

        val id = call.argument<Int>("playerId")
        val inst = players[id]
        if (inst == null) {
            result.success(null)
            return
        }
        main.post { inst.handle(call, result) }
    }

    private fun probeDurationMs(path: String?): Long? {
        if (path.isNullOrEmpty()) return null
        val r = MediaMetadataRetriever()
        return try {
            r.setDataSource(path)
            r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
        } catch (_: Exception) {
            null
        } finally {
            try { r.release() } catch (_: Exception) {}
        }
    }

    fun removePlayer(id: Int) {
        players.remove(id)
    }

    // ── Per-player instance ──────────────────────────────────────────────────
    inner class ExoInstance(
        private val id: Int,
        context: Context,
        messenger: BinaryMessenger,
        textures: TextureRegistry,
        private val main: Handler,
    ) : Player.Listener {

        private val player: ExoPlayer = ExoPlayer.Builder(context).build()
        private val textureEntry = textures.createSurfaceTexture()
        val textureId: Long = textureEntry.id()
        private val surface: Surface

        private var sink: EventChannel.EventSink? = null
        private val eventChannel = EventChannel(messenger, "exo/events/$id")

        // External subtitle MediaItem.SubtitleConfigurations accumulate so a
        // re-prepare keeps previously-loaded external subs.
        private val externalSubs = ArrayList<MediaItem.SubtitleConfiguration>()
        private var currentUri: String? = null

        // Poll position ~3x/sec (ExoPlayer doesn't push it continuously).
        private val ticker = object : Runnable {
            override fun run() {
                if (player.isPlaying) {
                    send(mapOf("event" to "position", "value" to player.currentPosition))
                }
                main.postDelayed(this, 300)
            }
        }

        init {
            val st = textureEntry.surfaceTexture()
            surface = Surface(st)
            player.setVideoSurface(surface)
            player.addListener(this)
            eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    sink = events
                }
                override fun onCancel(args: Any?) {
                    sink = null
                }
            })
            main.postDelayed(ticker, 300)
        }

        fun handle(call: MethodCall, result: MethodChannel.Result) {
            when (call.method) {
                "open" -> {
                    val path = call.argument<String>("path")!!
                    val startMs = (call.argument<Int>("start") ?: 0).toLong()
                    val play = call.argument<Boolean>("play") ?: true
                    open(path, startMs, play)
                    result.success(null)
                }
                "play" -> { playFromEndIfNeeded(); player.play(); result.success(null) }
                "pause" -> { player.pause(); result.success(null) }
                "playOrPause" -> {
                    // Toggle on INTENT (playWhenReady), not isPlaying, so a tap
                    // during a seek's re-buffer matches the button's shown state.
                    if (player.playWhenReady && player.playbackState != Player.STATE_ENDED) {
                        player.pause()
                    } else {
                        playFromEndIfNeeded()
                        player.play()
                    }
                    result.success(null)
                }
                "seek" -> {
                    // Scrubbing (releasing a progress-bar drag) passes fast=true so
                    // we snap to the nearest keyframe — near-instant, no decode
                    // hitch. Precise seeks (double-tap ±N, A-B) keep exact seeking.
                    val fast = call.argument<Boolean>("fast") ?: false
                    player.setSeekParameters(
                        if (fast) SeekParameters.CLOSEST_SYNC else SeekParameters.DEFAULT,
                    )
                    player.seekTo((call.argument<Int>("position") ?: 0).toLong())
                    // Emit the new position immediately so the Flutter side reflects
                    // the seek even while paused (the ticker only polls while
                    // playing). Fixes the seek-bar snapping back and A-B points
                    // captured at a stale position.
                    send(mapOf("event" to "position", "value" to player.currentPosition))
                    result.success(null)
                }
                "setRate" -> {
                    val r = (call.argument<Double>("rate") ?: 1.0).toFloat()
                    player.playbackParameters = PlaybackParameters(r)
                    result.success(null)
                }
                "setVolume" -> {
                    val pct = (call.argument<Double>("percent") ?: 100.0)
                    // ExoPlayer volume is 0..1; >100% boost is handled app-side
                    // via device volume, so clamp here.
                    player.volume = (pct / 100.0).coerceIn(0.0, 1.0).toFloat()
                    result.success(null)
                }
                "setRepeatMode" -> {
                    player.repeatMode = when (call.argument<Int>("mode")) {
                        1 -> Player.REPEAT_MODE_ONE
                        2 -> Player.REPEAT_MODE_ALL
                        else -> Player.REPEAT_MODE_OFF
                    }
                    result.success(null)
                }
                "selectAudioTrack" -> {
                    val aid = call.argument<String>("id")
                    if (aid == null) {
                        // Disable the audio track entirely (mute the stream, not
                        // just the volume — used by the "Disable" audio option).
                        player.trackSelectionParameters = player.trackSelectionParameters
                            .buildUpon()
                            .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, true)
                            .build()
                    } else {
                        player.trackSelectionParameters = player.trackSelectionParameters
                            .buildUpon()
                            .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, false)
                            .build()
                        selectTrack(aid, C.TRACK_TYPE_AUDIO)
                    }
                    result.success(null)
                }
                "selectSubtitleTrack" -> {
                    val tid = call.argument<String>("id")
                    if (tid == null) {
                        // Disable text tracks.
                        player.trackSelectionParameters = player.trackSelectionParameters
                            .buildUpon()
                            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                            .build()
                    } else {
                        player.trackSelectionParameters = player.trackSelectionParameters
                            .buildUpon()
                            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                            .build()
                        selectTrack(tid, C.TRACK_TYPE_TEXT)
                    }
                    result.success(null)
                }
                "addExternalSubtitle" -> {
                    result.success(addExternalSubtitle(call.argument<String>("path")))
                }
                "setSubtitleDelay" -> {
                    // ExoPlayer has no native subtitle delay; cue offset would be
                    // applied in the Flutter overlay. Accepted as a no-op for now.
                    result.success(null)
                }
                "dispose" -> {
                    release()
                    removePlayer(id)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        /// When playback has reached the end (STATE_ENDED), ExoPlayer.play() is a
        /// no-op because the position is already at the end. Rewind to the start
        /// so pressing play after a video finishes replays it.
        private fun playFromEndIfNeeded() {
            if (player.playbackState == Player.STATE_ENDED) {
                player.seekTo(0)
            }
        }

        private fun open(path: String, startMs: Long, play: Boolean) {
            currentUri = path
            val item = MediaItem.Builder()
                .setUri(Uri.parse(if (path.startsWith("/")) "file://$path" else path))
                .setSubtitleConfigurations(externalSubs)
                .build()
            player.setMediaItem(item, startMs)
            player.playWhenReady = play
            player.prepare()
        }

        private fun addExternalSubtitle(path: String?): String? {
            if (path.isNullOrEmpty()) return null
            val uri = Uri.parse(if (path.startsWith("/")) "file://$path" else path)
            val mime = when {
                path.endsWith(".srt", true) -> MimeTypes.APPLICATION_SUBRIP
                path.endsWith(".vtt", true) -> MimeTypes.TEXT_VTT
                path.endsWith(".ass", true) || path.endsWith(".ssa", true) ->
                    MimeTypes.TEXT_SSA
                path.endsWith(".ttml", true) -> MimeTypes.APPLICATION_TTML
                else -> MimeTypes.APPLICATION_SUBRIP
            }
            val cfg = MediaItem.SubtitleConfiguration.Builder(uri)
                .setMimeType(mime)
                .setSelectionFlags(C.SELECTION_FLAG_DEFAULT)
                .build()
            externalSubs.add(cfg)
            // Re-prepare keeping the current position so the new sub is picked up.
            val pos = player.currentPosition
            currentUri?.let { open(it, pos, player.isPlaying) }
            return "ext:${externalSubs.size - 1}"
        }

        private fun selectTrack(id: String?, type: Int) {
            id ?: return
            // id encodes "g<groupIndex>:t<trackIndex>".
            val parts = id.removePrefix("g").split(":t")
            val gi = parts.getOrNull(0)?.toIntOrNull() ?: return
            val ti = parts.getOrNull(1)?.toIntOrNull() ?: return
            val groups = player.currentTracks.groups.filter { it.type == type }
            val group = groups.getOrNull(gi) ?: return
            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .setOverrideForType(
                    TrackSelectionOverride(group.mediaTrackGroup, ti),
                )
                .build()
        }

        // Last reported "intends to play" value, so we only emit on real changes.
        private var lastIntent = false

        // ── Player.Listener ──────────────────────────────────────────────────
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            send(mapOf("event" to "playing", "value" to isPlaying))
            // Always push the current position on a play-state change (not only
            // when resuming) so the Flutter side stays accurate while paused.
            send(mapOf("event" to "position", "value" to player.currentPosition))
        }

        /// The user's playback INTENT — playWhenReady minus the ended/idle states.
        /// Drives the play/pause button so it doesn't flicker to "play" during the
        /// brief re-buffering of a seek (where isPlaying momentarily goes false).
        private fun reportIntent() {
            val intent = player.playWhenReady &&
                player.playbackState != Player.STATE_ENDED &&
                player.playbackState != Player.STATE_IDLE
            if (intent != lastIntent) {
                lastIntent = intent
                send(mapOf("event" to "intent", "value" to intent))
            }
        }

        override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
            reportIntent()
        }

        override fun onPlaybackStateChanged(state: Int) {
            if (state == Player.STATE_READY && player.duration > 0) {
                send(mapOf("event" to "duration", "value" to player.duration))
            }
            if (state == Player.STATE_ENDED) {
                send(mapOf("event" to "completed"))
            }
            reportIntent()
        }

        override fun onVideoSizeChanged(size: VideoSize) {
            send(mapOf("event" to "videoSize", "width" to size.width, "height" to size.height))
        }

        override fun onPlaybackParametersChanged(params: PlaybackParameters) {
            send(mapOf("event" to "rate", "value" to params.speed.toDouble()))
        }

        override fun onPlayerError(error: PlaybackException) {
            send(mapOf("event" to "error", "message" to (error.message ?: "Playback error")))
        }

        override fun onCues(cueGroup: CueGroup) {
            val text = cueGroup.cues.mapNotNull { it.text?.toString() }.joinToString("\n")
            send(mapOf("event" to "cues", "text" to text))
        }

        override fun onTracksChanged(tracks: Tracks) {
            send(buildTracksEvent(tracks))
        }

        private fun buildTracksEvent(tracks: Tracks): Map<String, Any?> {
            val audio = ArrayList<Map<String, Any?>>()
            val subtitle = ArrayList<Map<String, Any?>>()
            var activeAudio: String? = null
            var activeSubtitle: String? = null

            var audioGroupIndex = 0
            var textGroupIndex = 0
            for (group in tracks.groups) {
                val isAudio = group.type == C.TRACK_TYPE_AUDIO
                val isText = group.type == C.TRACK_TYPE_TEXT
                if (!isAudio && !isText) continue
                val gi = if (isAudio) audioGroupIndex++ else textGroupIndex++
                for (ti in 0 until group.length) {
                    val format = group.getTrackFormat(ti)
                    val tid = "g$gi:t$ti"
                    val entry = mapOf(
                        "id" to tid,
                        "title" to format.label,
                        "language" to format.language,
                    )
                    if (isAudio) {
                        audio.add(entry)
                        if (group.isTrackSelected(ti)) activeAudio = tid
                    } else {
                        subtitle.add(entry)
                        if (group.isTrackSelected(ti)) activeSubtitle = tid
                    }
                }
            }
            return mapOf(
                "event" to "tracks",
                "audio" to audio,
                "subtitle" to subtitle,
                "activeAudio" to activeAudio,
                "activeSubtitle" to activeSubtitle,
            )
        }

        private fun send(payload: Map<String, Any?>) {
            main.post { sink?.success(payload) }
        }

        fun release() {
            main.removeCallbacks(ticker)
            try { player.removeListener(this) } catch (_: Exception) {}
            try { player.release() } catch (_: Exception) {}
            try { surface.release() } catch (_: Exception) {}
            try { textureEntry.release() } catch (_: Exception) {}
            eventChannel.setStreamHandler(null)
            sink = null
        }
    }
}
