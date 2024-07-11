package com.example.recording_plugin

import androidx.annotation.NonNull
import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

/** RecordingPlugin */
class RecordingPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var mediaRecorder: MediaRecorder? = null
  private var filePath: String? = null
  private var eventSink: EventChannel.EventSink? = null
  private val handler = Handler(Looper.getMainLooper())
  private var isRecording = false

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "recording_plugin")
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "recording_plugin_events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "startRecording" -> startRecording(result)
      "stopRecording" -> stopRecording(result)
      else -> result.notImplemented()
    }

  }
  private fun startRecording(result: Result) {
    if (isRecording) {
      result.error("ALREADY_RECORDING", "A recording is already in progress.", null)
      return
    }
    val externalFilesDir = context.getExternalFilesDir(null)
    filePath = "${externalFilesDir?.absolutePath}/recording_${getTimestamp()}.m4a"

    mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      MediaRecorder(context)
    } else {
      MediaRecorder()
    }
    try {
      mediaRecorder?.apply {
        setAudioSource(MediaRecorder.AudioSource.MIC)
        setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        setAudioEncodingBitRate(128000)
        setAudioSamplingRate(44100)
        setOutputFile(filePath)
        prepare()
        start()
      }
      isRecording = true
      startMetering()
      result.success(true)
    } catch (e: IOException) {
      result.error("RECORDING_ERROR", "Failed to start recording: ${e.message}", null)
    }
  }

  private fun stopRecording(result: Result) {
    if (!isRecording) {
      result.error("NOT_RECORDING", "No recording in progress.", null)
      return
    }

    try {
      mediaRecorder?.apply {
        stop()
        release()
      }
      mediaRecorder = null
      isRecording = false
      result.success(filePath)
    } catch (e: Exception) {
      result.error("RECORDING_ERROR", "Failed to stop recording: ${e.message}", null)
    }
  }

  private fun startMetering() {
    handler.post(object : Runnable {
      override fun run() {
        if (isRecording && mediaRecorder != null) {
          val amplitude = mediaRecorder?.maxAmplitude ?: 0
          eventSink?.success(mapOf(
            "amplitude" to amplitude,
            "time" to System.currentTimeMillis()
          ))
          handler.postDelayed(this, 100) // Update every 100ms
        }
      }
    })
  }

  private fun getTimestamp(): String {
    val sdf = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
    return sdf.format(Date())
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }


}
