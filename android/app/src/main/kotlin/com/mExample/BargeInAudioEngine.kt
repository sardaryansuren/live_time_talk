package com.mExample.live_time_talk

import android.content.Context
import android.media.*
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.NoiseSuppressor
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread
import kotlin.math.abs

class BargeInAudioEngine(
    private val context: Context,
    private val channel: MethodChannel
) {

    private val TAG = "BargeInAudioEngine"

    /* ================= CONFIG ================= */
    private val sampleRate = 16000
    private val amplitudeThreshold = 1200   // Adjust for sensitivity
    private val minSpeechFrames = 8
    private val useMic = true                 // REQUIRED for barge-in

    /* ================= STATE ================= */
    @Volatile private var running = false
    @Volatile private var engineActive = false
    @Volatile private var stopping = false
    private var speechCounter = 0
    private var micStarted = false
    private var bargeInTriggered = false

    /* ================= AUDIO ================= */
    private var audioRecord: AudioRecord? = null
    private var mediaPlayer: MediaPlayer? = null
    private val mp3File = File(context.cacheDir, "elevenlabs_tts.mp3")

    /* ================= PUBLIC API ================= */
    fun start() {
        if (engineActive) {
            Log.w(TAG, "Start ignored — engine already active")
            return
        }

        Log.d(TAG, "Engine start")
        engineActive = true
        stopping = false
        running = true
        bargeInTriggered = false
        speechCounter = 0
        micStarted = false

        mp3File.delete()
        if (useMic) startMicListening()
    }

    fun stop() {
        if (!engineActive || stopping) {
            Log.w(TAG, "Stop ignored — already stopping or inactive")
            return
        }

        stopping = true
        Log.d(TAG, "Engine stop")

        running = false
        bargeInTriggered = true

        stopPlayback()
        stopMic()

        engineActive = false
        stopping = false
    }

    /**
     * Receives MP3 chunks from Flutter (ElevenLabs free tier)
     */
    @Synchronized
    fun playMp3Chunk(chunk: ByteArray, finalChunk: Boolean) {
        if (!running) return

        mp3File.appendBytes(chunk)

        if (finalChunk) {
            startPlayback()
        }
    }

    /* ================= PLAYBACK ================= */
    private fun startPlayback() {
        stopPlayback()

        mediaPlayer = MediaPlayer().apply {
            setDataSource(mp3File.absolutePath)
            prepare()
            start()

            setOnCompletionListener {
                Log.d(TAG, "Playback finished")
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("playback_finished", null)
                }
                // Safe stop only if not already stopping
                if (!stopping) stop()
            }
        }
    }

    private fun stopPlayback() {
        mediaPlayer?.apply {
            stop()
            release()
        }
        mediaPlayer = null
    }

    /* ================= MIC + VAD ================= */
    private fun startMicListening() {
        if (!useMic || micStarted) return
        micStarted = true

        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            minBuffer
        )

        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            Log.e(TAG, "AudioRecord init failed")
            return
        }

        enableAudioEffects(audioRecord!!)
        audioRecord?.startRecording()

        thread(name = "BargeInVAD") {
            vadLoop(minBuffer)
        }

        Log.d(TAG, "Mic listening started")
    }

    private fun vadLoop(bufferSize: Int) {
        val buffer = ShortArray(bufferSize)

        while (engineActive && running && useMic && !bargeInTriggered) {
            val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
            if (read <= 0) continue

            val maxAmplitude = buffer.maxOf { abs(it.toInt()) }

            if (maxAmplitude > amplitudeThreshold) {
                speechCounter++
                if (speechCounter >= minSpeechFrames) {
                    bargeInTriggered = true
                    onBargeInDetected()
                    break
                }
            } else {
                speechCounter = 0
            }
        }
    }

    private fun stopMic() {
        audioRecord?.apply {
            stop()
            release()
        }
        audioRecord = null
        micStarted = false
        Log.d(TAG, "Mic stopped")
    }

    /* ================= AUDIO EFFECTS ================= */
    private fun enableAudioEffects(record: AudioRecord) {
        if (AcousticEchoCanceler.isAvailable()) {
            AcousticEchoCanceler.create(record.audioSessionId)?.enabled = true
        }
        if (NoiseSuppressor.isAvailable()) {
            NoiseSuppressor.create(record.audioSessionId)?.enabled = true
        }
    }

    /* ================= CALLBACK ================= */
    private fun onBargeInDetected() {
        if (!useMic) return

        Log.d(TAG, "Barge-in detected")

        // Stop engine safely
        stop()

        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("barge_in_detected", null)
        }
    }
}
