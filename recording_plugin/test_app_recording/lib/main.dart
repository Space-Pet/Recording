import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recording_plugin/recording_plugin.dart';

void main() {
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (ctx) => const RecordingWithNativeIOS(),
                    ),
                  );
                },
                child: const Text('Recording with Native IOS'),
              ),
              ElevatedButton(
                onPressed: () async {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (ctx) => const RecodingWithAudioWaveForm(),
                    ),
                  );
                },
                child: const Text('Recording with Audio WaveForm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecodingWithAudioWaveForm extends StatefulWidget {
  const RecodingWithAudioWaveForm({super.key});

  @override
  State<RecodingWithAudioWaveForm> createState() =>
      _RecodingWithAudioWaveFormState();
}

class _RecodingWithAudioWaveFormState extends State<RecodingWithAudioWaveForm> {
  final _recordingPlugin = RecordingPlugin();

  String _recordingPath = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording with Audio WaveForm'),
        automaticallyImplyLeading: true,
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: _recordingPlugin.createAudioRecorder(
          width: size.width * 0.8,
          height: size.height * 0.5,
          onRecordingComplete: (value) {
            setState(() {
              _recordingPath = value;
            });
          },
        ),
      ),
    );
  }
}

class RecordingWithNativeIOS extends StatefulWidget {
  const RecordingWithNativeIOS({super.key});

  @override
  State<RecordingWithNativeIOS> createState() => _RecordingWithNativeIOSState();
}

class _RecordingWithNativeIOSState extends State<RecordingWithNativeIOS> {
  final _recordingPlugin = RecordingPlugin();

  String _recordingPath = '';

  bool isRecording = false;
  StreamSubscription? _recordingSubscription;
  List<double> waveformData = [];
  String _recordingTime = '';
  void startRecording() async {
    bool success = await _recordingPlugin.startRecording();
    if (success) {
      setState(() {
        isRecording = true;
        waveformData.clear();
      });
      _recordingSubscription = _recordingPlugin.onRecordingData.listen((data) {
        setState(() {
          _recordingTime = data.time.toString();
          waveformData.add(data.averagePower.toDouble());
          if (waveformData.length > 100) {
            waveformData.removeAt(0);
          }
        });
      });
    }
  }

  void stopRecording() async {
    String? path = await _recordingPlugin.stopRecording() ?? '';
    setState(() {
      isRecording = false;
    });
    _recordingSubscription?.cancel();
    print("Recording saved to: $path");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording with Native IOS'),
        automaticallyImplyLeading: true,
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                await _recordingPlugin.startRecording();
              },
              child: const Text('Start Recording'),
            ),
            const SizedBox(height: 20),
            Container(
              height: 100,
              color: Colors.grey,
              child: CustomPaint(
                painter: WaveformPainter(waveformData),
                size: Size(MediaQuery.of(context).size.width, 100),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _recordingTime,
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                _recordingPath = await _recordingPlugin.stopRecording() ?? "";
                setState(() {});
              },
              child: const Text('Stop Recording'),
            ),
            Text(
              _recordingPath,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;

  WaveformPainter(this.waveformData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (waveformData.isNotEmpty) {
      final width = size.width / (waveformData.length - 1);
      path.moveTo(0, size.height / 2);
      for (int i = 0; i < waveformData.length; i++) {
        final x = i * width;
        final y =
            size.height / 2 - (waveformData[i] + 160) / 160 * size.height / 2;
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
