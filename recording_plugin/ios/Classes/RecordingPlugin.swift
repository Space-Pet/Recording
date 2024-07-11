import Flutter
import UIKit
import AVFoundation
import Foundation

public class RecordingPlugin: NSObject, FlutterPlugin {
  // Khai báo  thuộc tính của class
  private var audioRecorder: AVAudioRecorder?
  
  private var timer: Timer?
  private var eventSink: FlutterEventSink?
    


  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "recording_plugin", binaryMessenger: registrar.messenger())
    let instance = RecordingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "startRecording":
      startRecording(result: result)
    case "stopRecording":
      stopRecording(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }


  private func startRecording(result: @escaping FlutterResult) {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      // Cấu hình AVAudioSession cho phép ghi âm.
      try audioSession.setCategory(.playAndRecord, mode: .default)
      try audioSession.setActive(true)

      //Tạo đường dẫn file để lưu âm thanh.
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioFilename = documentsPath.appendingPathComponent(getAudioFileName())

      // Thiết lập các thông số ghi âm (format, sample rate, chất lượng).
      let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]

      // Khởi tạo và bắt đầu Ghi âm.
      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder?.isMeteringEnabled = true
      audioRecorder?.record()

      // bắt đầu đếm thời gian
      startMetering()
      // Trả về true nếu ghi âm thành công
      result(true)
    } catch {
      // Trả về lỗi nếu ghi âm thất bại.
      result(FlutterError(code: "RECORDING_ERROR", message: "Failed to start recording: \(error.localizedDescription)", details: nil))
    }
  }

  private func stopRecording(result: @escaping FlutterResult) {
    // Kiểm tra xem có đang ghi âm không
    guard let recorder = audioRecorder else {
      result(FlutterError(code: "RECORDING_ERROR", message: "No active recording to stop", details: nil))
      return
    }
    // Dừng ghi âm và ghi tệp.

    recorder.stop()

    // Tắt Ghi âm.
    audioRecorder = nil
    // Dừng đếm thời gian
    stopMetering()
    // Trả về đường dẫn file ghi âm nếu thành công, hoặc FlutterError nếu có lỗi
    do {
      try AVAudioSession.sharedInstance().setActive(false)
      result(recorder.url.path)
    } catch {
      result(FlutterError(code: "RECORDING_ERROR", message: "Failed to stop recording: \(error.localizedDescription)", details: nil))
    }
  }


   private func startMetering() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let time = recorder.currentTime
            let averagePower = recorder.averagePower(forChannel: 0)
            let peakPower = recorder.peakPower(forChannel: 0)

            // Tạo map data Event cho Recording data
            self.eventSink?(["time": time, "averagePower": averagePower, "peakPower": peakPower])
        }
    }
    
    private func stopMetering() {
        timer?.invalidate()
        timer = nil
    }

    private func getAudioFileName() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    let timestamp = dateFormatter.string(from: Date())
    return "recording_\(timestamp).m4a"
  }
}

extension RecordingPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
