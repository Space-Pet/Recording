import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recording_plugin/widget/w_recording.dart';

import 'recording_plugin_platform_interface.dart';

/// An implementation of [RecordingPluginPlatform] that uses method channels.
class MethodChannelRecordingPlugin extends RecordingPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('recording_plugin');

  @visibleForTesting
  final EventChannel eventChannel =
      const EventChannel('recording_plugin_events');
  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Widget createAudioRecorder({
    required double width,
    required double height,
    required Function(String) onRecordingComplete,
  }) {
    return AudioRecorderWidget(
      width: width,
      height: height,
      onRecordingComplete: onRecordingComplete,
    );
  }

  @override
  Future<bool> startRecording() async {
    return await methodChannel.invokeMethod<bool>('startRecording') ?? false;
  }

  @override
  Future<String?> stopRecording() async {
    return await methodChannel.invokeMethod<String?>('stopRecording') ?? '';
  }

  @override
  Stream<RecordingData> get onRecordingData {
    return eventChannel
        .receiveBroadcastStream()
        .map((event) => RecordingData.fromMap(event));
  }
}
