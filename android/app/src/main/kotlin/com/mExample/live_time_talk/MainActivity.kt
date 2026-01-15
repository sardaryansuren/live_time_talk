package com.mExample.live_time_talk

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log


class MainActivity : FlutterActivity() {

    private val CHANNEL = "barge_in"
    private lateinit var engine: BargeInAudioEngine
    private val REQUEST_CODE = 123
    private val TAG = "BargeInAudioEngine"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Initialize engine
        engine = BargeInAudioEngine(this,channel)

        // Check microphone permission
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                REQUEST_CODE
            )
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {

                "start" -> {
                    engine.start()
                    result.success(null)
                }

                "stop" -> {
                    engine.stop()
                    result.success(null)
                }

                "play_chunk" -> {
                    Log.d(TAG, "play_chunk received")

                    val args = call.arguments as? Map<*, *>
                    val chunk = args?.get("chunk") as? ByteArray
                    val finalChunk = args?.get("final") as? Boolean ?: false

                    if (chunk != null) {
                        engine.playMp3Chunk(chunk, finalChunk)
                    } else {
                        Log.w(TAG, "play_chunk called with null chunk")
                    }

                    result.success(null)
                }

                else -> result.notImplemented()

        }

    }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "Microphone permission granted", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "Microphone permission is required", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onDestroy() {
        engine.stop()
        super.onDestroy()
    }
}
