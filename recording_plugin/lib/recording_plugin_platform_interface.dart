import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'recording_plugin_method_channel.dart';

abstract class RecordingPluginPlatform extends PlatformInterface {
  /// Constructs a RecordingPluginPlatform.
  RecordingPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static RecordingPluginPlatform _instance = MethodChannelRecordingPlugin();

  /// The default instance of [RecordingPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelRecordingPlugin].
  static RecordingPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RecordingPluginPlatform] when
  /// they register themselves.
  static set instance(RecordingPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Widget createAudioRecorder({
    required double width,
    required double height,
    required Function(String) onRecordingComplete,
  }) {
    throw UnimplementedError('createAudioRecorder() has not been implemented.');
  }

  Future<bool> startRecording();
  Future<String?> stopRecording();
  Stream<RecordingData> get onRecordingData;
}

class RecordingData {
  final num time;
  final num averagePower;
  final num peakPower;
  final num amplitude;

  RecordingData({
    required this.time,
    required this.averagePower,
    required this.peakPower,
    required this.amplitude,
  });

  factory RecordingData.fromMap(Map<dynamic, dynamic> map) {
    return RecordingData(
      time: map['time'],
      averagePower: map['averagePower'],
      peakPower: map['peakPower'],
      amplitude: map['amplitude'],
    );
  }
}
