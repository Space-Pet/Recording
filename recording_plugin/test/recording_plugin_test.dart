import 'dart:developer';

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_plugin/recording_plugin.dart';
import 'package:recording_plugin/recording_plugin_platform_interface.dart';
import 'package:recording_plugin/recording_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:recording_plugin/widget/w_recording.dart';

class MockRecordingPluginPlatform
    with MockPlatformInterfaceMixin
    implements RecordingPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Widget createAudioRecorder(
          {required double width,
          required double height,
          required Function(String p1) onRecordingComplete}) =>
      AudioRecorderWidget(
          width: width,
          height: height,
          onRecordingComplete: onRecordingComplete);

  @override
  // TODO: implement onRecordingData
  Stream<RecordingData> get onRecordingData => throw UnimplementedError();

  @override
  Future<bool> startRecording() {
    // TODO: implement startRecording
    throw UnimplementedError();
  }

  @override
  Future<String?> stopRecording() {
    // TODO: implement stopRecording
    throw UnimplementedError();
  }
}

void main() {
  final RecordingPluginPlatform initialPlatform =
      RecordingPluginPlatform.instance;

  test('$MethodChannelRecordingPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRecordingPlugin>());
  });

  test('getPlatformVersion', () async {
    RecordingPlugin recordingPlugin = RecordingPlugin();
    MockRecordingPluginPlatform fakePlatform = MockRecordingPluginPlatform();
    RecordingPluginPlatform.instance = fakePlatform;

    expect(await recordingPlugin.getPlatformVersion(), '42');
  });

  test('createAudioRecorder', () {
    RecordingPlugin recordingPlugin = RecordingPlugin();
    MockRecordingPluginPlatform fakePlatform = MockRecordingPluginPlatform();
    RecordingPluginPlatform.instance = fakePlatform;

    expect(
      recordingPlugin.createAudioRecorder(
        width: 100,
        height: 100,
        onRecordingComplete: (String p1) {
          log(p1);
        },
      ),
      isInstanceOf<AudioRecorderWidget>(),
    );
  });
}
