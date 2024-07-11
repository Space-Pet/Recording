// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'package:flutter/widgets.dart';

import 'recording_plugin_platform_interface.dart';

class RecordingPlugin {
  Future<String?> getPlatformVersion() {
    return RecordingPluginPlatform.instance.getPlatformVersion();
  }

  Widget createAudioRecorder({
    required double width,
    required double height,
    required Function(String) onRecordingComplete,
  }) {
    return RecordingPluginPlatform.instance.createAudioRecorder(
      width: width,
      height: height,
      onRecordingComplete: onRecordingComplete,
    );
  }

  Future<bool> startRecording() {
    return RecordingPluginPlatform.instance.startRecording();
  }

  Future<String?> stopRecording() {
    return RecordingPluginPlatform.instance.stopRecording();
  }

  Stream<RecordingData> get onRecordingData {
    return RecordingPluginPlatform.instance.onRecordingData;
  }
}
