import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderWidget extends StatefulWidget {
  final double width;
  final double height;
  final Function(String) onRecordingComplete;

  const AudioRecorderWidget({
    super.key,
    required this.width,
    required this.height,
    required this.onRecordingComplete,
  });

  @override
  AudioRecorderWidgetState createState() => AudioRecorderWidgetState();
}

class AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  late RecorderController _recorderController;
  late PlayerController _playerController;
  bool _isRecording = false;
  bool _isPausedRecodring = false;
  bool _isPlaying = false;
  String? _recordedPath;
  final List<File> _recordedFiles = [];
  String _timeCalculator = '00:00:00';

  bool _isChooseFile = false;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    _playerController = PlayerController();
    _initLoadAllFileRecord();
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _playerController.dispose();
    super.dispose();
  }

  void _startRecording() async {
    _recorderController.reset();

    await _recorderController.record();

    setState(() {
      _isPlaying = false;
      _isRecording = true;
      _isChooseFile = false;
      _isPausedRecodring = false;
      _timeCalculator = _recorderController.recordedDuration.toString();
      _recorderController.onCurrentDuration.asBroadcastStream().listen((event) {
        setState(() {
          _timeCalculator = event.toHHMMSS();
        });
      });
    });
  }

  void _stopRecording() async {
    _recordedPath = await _recorderController.stop();

    print(_recordedPath);
    if (_recordedPath != null) {
      widget.onRecordingComplete(_recordedPath!);
      File recordedFile = File(_recordedPath ?? "");
      if (Platform.isAndroid) {
        final document = await getExternalStorageDirectory();
        final path = document!.path;
        final file = File('$path/${recordedFile.path.split('/').last}');
        await recordedFile.copy(file.path);
      }
      _recordedFiles.add(recordedFile);
      _recorderController.reset();
    }
    setState(() {
      _isRecording = false;
    });
  }

  void _pauseRecording() async {
    await _recorderController.pause();
    setState(() {
      _isPausedRecodring = true;
      _isRecording = true;
    });
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _playerController.pausePlayer();
    } else {
      await _playerController.seekTo(Duration.zero.inSeconds);
      await _playerController.startPlayer();
      _playerController.onCompletion.asBroadcastStream().listen((value) {
        setState(() {
          _isPlaying = false;
        });
      });
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  _initLoadAllFileRecord() async {
    final Directory appDocDir = Platform.isAndroid
        ? await getExternalStorageDirectory() ?? Directory('')
        : await getApplicationDocumentsDirectory();
    final files = appDocDir.listSync();
    for (var file in files) {
      if (file is File) {
        _recordedFiles.add(file);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              AnimatedCrossFade(
                  firstChild: AudioWaveforms(
                    size: Size(widget.width, widget.height),
                    recorderController: _recorderController,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.red,
                      extendWaveform: true,
                      showMiddleLine: true,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                  ),
                  secondChild: AudioFileWaveforms(
                    size: Size(widget.width, widget.height),
                    playerController: _playerController,
                    playerWaveStyle: const PlayerWaveStyle(
                      liveWaveColor: Colors.red,
                      backgroundColor: Colors.black,
                      fixedWaveColor: Colors.black,
                      seekLineColor: Colors.black,
                    ),
                    enableSeekGesture: true,
                  ),
                  crossFadeState: _isChooseFile == false ||
                          _isChooseFile == false && _recordedFiles.isEmpty
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: Durations.medium2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                  ),
                  if (_recordedPath != null)
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlayPause,
                    ),
                  if (_isRecording == true)
                    IconButton(
                      icon: Icon(
                        _isPausedRecodring == true
                            ? Icons.play_arrow
                            : Icons.pause,
                        color: Colors.black,
                      ),
                      onPressed: _isPausedRecodring == false
                          ? _pauseRecording
                          : _startRecording,
                    ),
                ],
              ),
            ],
          ),
        ),
        Text(
          _timeCalculator,
          style: const TextStyle(color: Colors.black),
        ),
        Expanded(
            child: _recordedFiles.isEmpty
                ? const Center(
                    child: Text('No recordings yet'),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemBuilder: (ctx, index) {
                      return Slidable(
                        key: ValueKey<int>(index),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              // An action can be bigger than the others.

                              onPressed: (_) async {
                                final fileFound =
                                    await File(_recordedFiles[index].path)
                                        .delete();
                                if (fileFound.isAbsolute) {
                                  _recordedFiles.removeAt(index);

                                  print(_recordedFiles.length);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'File deleted ${_recordedFiles[index].path.split('/').last}'),
                                    ),
                                  );
                                }
                                setState(() {});
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                            SlidableAction(
                              onPressed: (_) {},
                              backgroundColor: const Color(0xFF0392CF),
                              foregroundColor: Colors.white,
                              icon: Icons.save,
                              label: 'Save',
                            ),
                            SlidableAction(
                              onPressed: (_) {
                                OpenFile.open(_recordedFiles[index].path);
                              },
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              icon: Icons.file_open,
                              label: 'Open',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title:
                              Text(_recordedFiles[index].path.split('/').last),
                          leading: Text("${index + 1}"),
                          onTap: () {
                            setState(() {
                              _recordedPath = _recordedFiles[index].path;
                              _playerController.setRefresh(true);
                              _playerController.preparePlayer(
                                  path: _recordedPath!);
                              _isChooseFile = true;
                            });
                          },
                        ),
                      );
                    },
                    itemCount: _recordedFiles.reversed.toList().length,
                  )),
      ],
    );
  }
}
