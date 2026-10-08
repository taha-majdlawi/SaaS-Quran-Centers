package com.bustanalquran.bustan_alquran_app

import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.system.Os
import android.system.OsConstants
import android.system.StructPollfd
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

/**
 * Live reciting with a recording for the teacher (Android 13+).
 *
 * Two users of the microphone at once are not possible on Android, so the app captures it
 * itself and does both with the same sound:
 *   - it is encoded to AAC as it comes (an .m4a, ~240 KB a minute - a WAV would be ~2 MB);
 *   - it is handed to the phone's speech recogniser (RecognizerIntent.EXTRA_AUDIO_SOURCE),
 *     one recognition session after another (each ends after a pause, the next starts at once),
 *     biased towards the passage's words (RecognizerIntent.EXTRA_BIASING_STRINGS): a general
 *     Arabic recogniser otherwise leans to everyday words.
 * A recogniser that does not take the sound this way never reads it: after a few seconds the
 * screen is told ("fallback") and goes back to the usual recognition, without a recording.
 *
 * Dart side: lib/features/quran/live_speech.dart.
 */
class LiveSpeech(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private companion object {
        const val RATE = 16000
        const val CHUNK = 3200 // 100 ms of 16-bit mono
        const val MAX_US = 30L * 60 * 1_000_000 // the recording stops growing after 30 minutes
        const val STALL_MS = 4000L // the recogniser has not read the sound for this long: it does not take it
    }

    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    // capture + recording (the capture thread)
    @Volatile private var capturing = false
    private var record: AudioRecord? = null
    private var captureThread: Thread? = null
    private var feedThread: Thread? = null
    private var encoder: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var track = -1
    private var samples = 0L
    private var file: File? = null
    @Volatile private var recordOk = false

    // recognition (main thread; the feed thread writes to the current pipe)
    private class Pipe(val read: ParcelFileDescriptor, val write: ParcelFileDescriptor) {
        val out = FileOutputStream(write.fileDescriptor)
        fun close() {
            try { read.close() } catch (_: Exception) {}
            try { write.close() } catch (_: Exception) {}
        }
    }
    private val queue = LinkedBlockingQueue<ByteArray>()
    @Volatile private var pipe: Pipe? = null
    @Volatile private var listening = false
    @Volatile private var fellBack = false
    private var recognizer: SpeechRecognizer? = null
    private var language = "ar-SA"
    private var bias = ArrayList<String>()
    private var ready = false // the current session got as far as listening
    private var failedStarts = 0 // sessions in a row that failed before listening
    private var session = 0

    init {
        MethodChannel(messenger, "bustan/live_speech").setMethodCallHandler(this)
        EventChannel(messenger, "bustan/live_speech/events").setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { sink = events }
    override fun onCancel(arguments: Any?) { sink = null }

    private fun emit(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "supported" -> result.success(
                Build.VERSION.SDK_INT >= 33 && SpeechRecognizer.isRecognitionAvailable(context)
            )
            "start" -> result.success(
                start(call.argument<String>("path")!!, call.argument<String>("language") ?: "ar-SA",
                    call.argument<List<String>>("bias") ?: emptyList())
            )
            "resume" -> { resume(); result.success(null) }
            "pause" -> { pause(); result.success(null) }
            "stop" -> result.success(stop(call.argument<Boolean>("discard") ?: false))
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- capture

    private fun start(path: String, lang: String, phrases: List<String>): Boolean {
        if (Build.VERSION.SDK_INT < 33) return false
        stop(true)
        language = lang
        bias = ArrayList(phrases)
        failedStarts = 0
        fellBack = false
        val min = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val rec = try {
            AudioRecord(MediaRecorder.AudioSource.VOICE_RECOGNITION, RATE, AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT, maxOf(min, CHUNK) * 4)
        } catch (e: SecurityException) {
            return false
        }
        if (rec.state != AudioRecord.STATE_INITIALIZED) {
            rec.release()
            return false
        }
        record = rec
        file = File(path).also { it.delete() }
        recordOk = openEncoder(path)
        samples = 0
        queue.clear()
        capturing = true
        rec.startRecording()
        captureThread = Thread({ captureLoop(rec) }, "live-capture").also { it.start() }
        feedThread = Thread({ feedLoop() }, "live-feed").also { it.start() }
        return true
    }

    private fun openEncoder(path: String): Boolean = try {
        val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, RATE, 1).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, 32000)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, CHUNK * 4)
        }
        encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC).apply {
            configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            start()
        }
        muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        track = -1
        true
    } catch (e: Exception) {
        closeEncoder(false)
        false
    }

    private fun captureLoop(rec: AudioRecord) {
        val buf = ByteArray(CHUNK)
        while (capturing) {
            val n = rec.read(buf, 0, buf.size)
            if (n <= 0) continue
            if (recordOk) encode(buf, n, false)
            if (listening && !fellBack) {
                queue.offer(buf.copyOf(n))
                while (queue.size > 50) queue.poll() // between sessions: up to 5 s kept for the next one
            }
        }
    }

    /** One chunk of sound into the AAC encoder, and what it has ready into the file. */
    private fun encode(data: ByteArray, length: Int, end: Boolean) {
        val codec = encoder ?: return
        try {
            if (!end && samples * 1_000_000 / RATE > MAX_US) return
            var off = 0
            do {
                val index = codec.dequeueInputBuffer(10_000)
                if (index < 0) break
                val input = codec.getInputBuffer(index)!!
                input.clear()
                val n = minOf(length - off, input.remaining())
                input.put(data, off, n)
                val us = samples * 1_000_000 / RATE
                samples += n / 2
                off += n
                codec.queueInputBuffer(index, 0, n, us, if (end && off >= length) MediaCodec.BUFFER_FLAG_END_OF_STREAM else 0)
            } while (off < length)
            drain(codec, end)
        } catch (e: Exception) {
            recordOk = false
        }
    }

    private fun drain(codec: MediaCodec, end: Boolean) {
        val info = MediaCodec.BufferInfo()
        val mux = muxer ?: return
        var waits = 0
        while (true) {
            val index = codec.dequeueOutputBuffer(info, if (end) 10_000 else 0)
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> if (!end || ++waits > 50) return // at the end: until its last frame (≤ 0.5 s)
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    track = mux.addTrack(codec.outputFormat)
                    mux.start()
                }
                index >= 0 -> {
                    val out = codec.getOutputBuffer(index)!!
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0 && track >= 0) {
                        out.position(info.offset)
                        out.limit(info.offset + info.size)
                        mux.writeSampleData(track, out, info)
                    }
                    codec.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
                }
                else -> {} // output buffers changed (old devices): nothing to do
            }
        }
    }

    private fun closeEncoder(finish: Boolean) {
        val codec = encoder
        if (finish && codec != null && recordOk) encode(ByteArray(0), 0, true)
        try { codec?.stop() } catch (_: Exception) {}
        try { codec?.release() } catch (_: Exception) {}
        try { if (track >= 0) muxer?.stop() } catch (_: Exception) { recordOk = false }
        try { muxer?.release() } catch (_: Exception) {}
        encoder = null
        muxer = null
        if (track < 0) recordOk = false
        track = -1
    }

    // ---------------------------------------------------------------- the recogniser

    /** Hands the captured sound to the current session's pipe, without ever blocking on it. */
    private fun feedLoop() {
        var stalledSince = 0L
        while (capturing) {
            val chunk = queue.poll(200, TimeUnit.MILLISECONDS) ?: continue
            var done = false
            while (capturing && listening && !fellBack && !done) {
                val p = pipe
                if (p == null) { // between two sessions: wait for the next one
                    Thread.sleep(20)
                    continue
                }
                try {
                    val fds = arrayOf(StructPollfd().apply {
                        fd = p.write.fileDescriptor
                        events = OsConstants.POLLOUT.toShort()
                    })
                    if (Os.poll(fds, 100) > 0) {
                        val r = fds[0].revents.toInt()
                        if (r and (OsConstants.POLLERR or OsConstants.POLLHUP) != 0) {
                            done = true // the session is over; the chunk is not needed
                        } else if (r and OsConstants.POLLOUT != 0) {
                            p.out.write(chunk)
                            stalledSince = 0
                            done = true
                        }
                    } else if (pipe === p) {
                        // the pipe stays full: the recogniser is not reading what we give it
                        val now = System.currentTimeMillis()
                        if (stalledSince == 0L) stalledSince = now
                        else if (now - stalledSince > STALL_MS) {
                            stalledSince = 0
                            main.post { fallback() }
                            done = true
                        }
                    }
                } catch (e: Exception) {
                    done = true // the pipe was closed under us (the session changed)
                }
            }
        }
    }

    private val listener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            ready = true
            failedStarts = 0
            emit(mapOf("type" to "listening", "on" to true))
        }
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {}
        override fun onEvent(eventType: Int, params: Bundle?) {}
        override fun onPartialResults(partialResults: Bundle?) = text(partialResults, false)
        override fun onResults(results: Bundle?) {
            text(results, true)
            next()
        }
        override fun onError(error: Int) {
            emit(mapOf("type" to "error", "code" to error, "session" to session))
            when (error) {
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS, SpeechRecognizer.ERROR_NETWORK,
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT, SpeechRecognizer.ERROR_SERVER -> {
                    listening = false
                    closePipe()
                }
                // the sound could not be taken from us, or not in Arabic this way: the usual recognition
                SpeechRecognizer.ERROR_AUDIO, SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
                SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> fallback()
                else -> {
                    // a recogniser that refuses the session itself (before listening) again and
                    // again may not take the bias list: the next sessions go without it
                    if (!ready && ++failedStarts >= 3 && bias.isNotEmpty()) bias = ArrayList()
                    next(300) // no match, silence, busy: the next session
                }
            }
        }
    }

    private fun text(bundle: Bundle?, final: Boolean) {
        val text = bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull() ?: return
        emit(mapOf("type" to if (final) "final" else "partial", "text" to text, "session" to session))
    }

    private fun next(delay: Long = 0) {
        closePipe()
        emit(mapOf("type" to "listening", "on" to false))
        main.postDelayed({ startSession() }, delay)
    }

    private fun startSession() {
        if (!listening || fellBack || !capturing || Build.VERSION.SDK_INT < 33) return
        closePipe()
        val ends = ParcelFileDescriptor.createPipe()
        val p = Pipe(ends[0], ends[1])
        val rec = recognizer ?: SpeechRecognizer.createSpeechRecognizer(context).also {
            it.setRecognitionListener(listener)
            recognizer = it
        }
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, p.read)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, RATE)
            if (bias.isNotEmpty()) putStringArrayListExtra(RecognizerIntent.EXTRA_BIASING_STRINGS, bias)
        }
        session++
        ready = false
        pipe = p
        try {
            rec.startListening(intent)
        } catch (e: Exception) {
            fallback()
        }
    }

    private fun closePipe() {
        val p = pipe
        pipe = null
        p?.close()
    }

    private fun fallback() {
        if (fellBack) return
        fellBack = true
        listening = false
        try { recognizer?.cancel() } catch (_: Exception) {}
        closePipe()
        emit(mapOf("type" to "fallback"))
    }

    private fun resume() {
        if (!capturing || fellBack) return
        queue.clear()
        listening = true
        startSession()
    }

    private fun pause() {
        listening = false
        queue.clear()
        try { recognizer?.cancel() } catch (_: Exception) {}
        closePipe()
        emit(mapOf("type" to "listening", "on" to false))
    }

    /** Ends everything; the recording ({path, seconds}) unless [discard] or there is none. */
    private fun stop(discard: Boolean): Map<String, Any>? {
        pause()
        try { recognizer?.destroy() } catch (_: Exception) {}
        recognizer = null
        if (!capturing && record == null) return null
        capturing = false
        try { captureThread?.join(1500) } catch (_: Exception) {}
        try { feedThread?.join(500) } catch (_: Exception) {}
        captureThread = null
        feedThread = null
        try { record?.stop() } catch (_: Exception) {}
        record?.release()
        record = null
        closeEncoder(true)
        val f = file
        file = null
        val seconds = (samples / RATE).toInt()
        if (discard || !recordOk || f == null || !f.exists() || f.length() == 0L || seconds < 1) {
            f?.delete()
            return null
        }
        return mapOf("path" to f.absolutePath, "seconds" to seconds)
    }
}
