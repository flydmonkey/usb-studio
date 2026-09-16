import AVFoundation
import AVKit
import Flutter
import Photos
import UIKit

public class UsbCapturePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var events: FlutterEventSink?
  private var controller: CaptureController?
  private var registrar: FlutterPluginRegistrar?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "usb_capture", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "usb_capture/events", binaryMessenger: registrar.messenger())
    let instance = UsbCapturePlugin()
    instance.registrar = registrar
    instance.controller = CaptureController { event in
      DispatchQueue.main.async { instance.events?(event) }
    }
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
    let factory = PreviewViewFactory(controller: instance.controller!)
    registrar.register(factory, withId: "usb_capture/preview")
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.events = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    events = nil
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "getPlatformProfile":
        result(platformProfile())
      case "getCaptureStatus":
        result(controller?.captureStatus() ?? [
          "sessionOpen": false,
          "recording": false,
        ])
      case "requestPermissions":
        requestPermissions(result: result)
      case "listDevices":
        try ensureSupported()
        result(controller?.listDevices() ?? [])
      case "listFormats":
        result(controller?.listFormats() ?? [])
      case "setFormat":
        try ensureSupported()
        let args = call.arguments as? [String: Any]
        guard let formatId = args?["formatId"] as? String else {
          throw CaptureError.uvcFailed
        }
        try controller?.setFormat(formatId: formatId)
        result(nil)
      case "setMonitorVolume":
        let args = call.arguments as? [String: Any]
        controller?.setMonitorVolume(doubleArg(args, "volume", 1))
        result(nil)
      case "setMonitorDelay":
        let args = call.arguments as? [String: Any]
        controller?.setMonitorDelay(intArg(args, "delayMs", 0))
        result(nil)
      case "listPictureControls":
        result(controller?.listPictureControls() ?? [])
      case "setPictureControl":
        let args = call.arguments as? [String: Any]
        controller?.setPictureControl(
          id: args?["id"] as? String ?? "",
          value: intArg(args, "value", 50)
        )
        result(nil)
      case "resetPictureControls":
        controller?.resetPictureControls()
        result(nil)
      case "takeSnapshot":
        try ensureSupported()
        controller?.takeSnapshot { error in
          if let error {
            result(flutterError(error))
          } else {
            result(nil)
          }
        }
      case "setRecordingQuality":
        let args = call.arguments as? [String: Any]
        try controller?.setRecordingQuality(args?["preset"] as? String ?? "standard")
        result(nil)
      case "open":
        try ensureSupported()
        let args = call.arguments as? [String: Any]
        guard let deviceId = args?["deviceId"] as? String else {
          throw CaptureError.uvcFailed
        }
        try controller?.open(deviceId: deviceId)
        result(nil)
      case "close":
        controller?.close()
        result(nil)
      case "setPreviewMuted":
        let args = call.arguments as? [String: Any]
        controller?.setPreviewMuted(args?["muted"] as? Bool ?? false)
        result(nil)
      case "startRecording":
        try ensureSupported()
        let args = call.arguments as? [String: Any]
        try controller?.startRecording(segmentMinutes: intArg(args, "segmentMinutes", 10))
        result(nil)
      case "stopRecording":
        controller?.stopRecording { payload, error in
          if let error {
            result(flutterError(error))
          } else {
            result(payload)
          }
        }
      case "listRecordings":
        result(controller?.listRecordings() ?? [])
      case "deleteRecording":
        let args = call.arguments as? [String: Any]
        guard let id = args?["id"] as? String else {
          result(flutterError(.uvcFailed))
          return
        }
        controller?.deleteRecording(id: id) { error in
          if let error {
            result(flutterError(error))
          } else {
            result(nil)
          }
        }
      case "shareRecording":
        let args = call.arguments as? [String: Any]
        guard let id = args?["id"] as? String else {
          result(flutterError(.uvcFailed))
          return
        }
        controller?.shareRecording(id: id, from: presenter()) { error in
          if let error {
            result(FlutterError(code: "unknown", message: "shareUnavailable", details: nil))
          } else {
            result(nil)
          }
        }
      case "openRecording":
        let args = call.arguments as? [String: Any]
        guard let id = args?["id"] as? String else {
          result(FlutterError(code: "unknown", message: "playFailed", details: nil))
          return
        }
        controller?.openRecording(id: id, from: presenter()) { error in
          if error != nil {
            result(FlutterError(code: "unknown", message: "playFailed", details: nil))
          } else {
            result(nil)
          }
        }
      case "renameRecording":
        result(FlutterError(code: "unknown", message: "renameUnsupported", details: nil))
      case "openBatterySettings":
        result(nil)
      case "setSaveLocation":
        result(nil)
      case "pickSaveFolder":
        result(nil)
      case "concatSession":
        result(flutterError(.recordingFailed, "concatUnsupported"))
      case "startStream":
        result(FlutterError(code: "streamFailed", message: "streamUnsupported", details: nil))
      case "stopStream":
        result(nil)
      case "startHttpServer":
        result(FlutterError(code: "streamFailed", message: "httpUnsupported", details: nil))
      case "stopHttpServer":
        result(nil)
      case "httpServerStatus":
        result(["running": false])
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as CaptureError {
      result(flutterError(error))
    } catch {
      result(FlutterError(code: "unknown", message: error.localizedDescription, details: nil))
    }
  }

  private func ensureSupported() throws {
    if UIDevice.current.userInterfaceIdiom != .pad {
      throw CaptureError.unsupportedPlatform
    }
  }

  private func platformProfile() -> [String: Any] {
    [
      "usbCaptureSupported": UIDevice.current.userInterfaceIdiom == .pad,
      "televisionUiMode": false,
      "hasUsbHost": UIDevice.current.userInterfaceIdiom == .pad,
      "hasTouchscreen": true,
      "rtmpStreamSupported": false,
      "httpLanSupported": false,
    ]
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    if UIDevice.current.userInterfaceIdiom != .pad {
      result(flutterError(.unsupportedPlatform))
      return
    }
    AVCaptureDevice.requestAccess(for: .video) { video in
      AVCaptureDevice.requestAccess(for: .audio) { audio in
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
          DispatchQueue.main.async {
            if video && audio && (status == .authorized || status == .limited) {
              result(nil)
            } else {
              result(flutterError(.permissionDenied))
            }
          }
        }
      }
    }
  }
}

enum CaptureError: String, Error {
  case permissionDenied
  case usbHostMissing
  case unsupportedPlatform
  case uvcFailed
  case powerIssue
  case disconnected
  case noAudioSource
  case recordingFailed
  case noPreview
}

func flutterError(_ error: CaptureError, _ message: String? = nil) -> FlutterError {
  FlutterError(code: error.rawValue, message: message ?? error.rawValue, details: nil)
}

private func presenter() -> UIViewController? {
  UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap(\.windows)
    .first(where: \.isKeyWindow)?
    .rootViewController
}

private func doubleArg(_ args: [String: Any]?, _ key: String, _ fallback: Double) -> Double {
  if let value = args?[key] as? Double { return value }
  if let value = args?[key] as? Int { return Double(value) }
  if let value = args?[key] as? NSNumber { return value.doubleValue }
  return fallback
}

private func intArg(_ args: [String: Any]?, _ key: String, _ fallback: Int) -> Int {
  if let value = args?[key] as? Int { return value }
  if let value = args?[key] as? Double { return Int(value) }
  if let value = args?[key] as? NSNumber { return value.intValue }
  return fallback
}
