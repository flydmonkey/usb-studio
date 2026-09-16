import AVFoundation
import Flutter
import UIKit

final class PreviewViewFactory: NSObject, FlutterPlatformViewFactory {
  private let controller: CaptureController

  init(controller: CaptureController) {
    self.controller = controller
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    PreviewPlatformView(frame: frame, controller: controller)
  }
}

final class PreviewPlatformView: NSObject, FlutterPlatformView {
  private let previewView: PreviewView

  init(frame: CGRect, controller: CaptureController) {
    previewView = PreviewView(frame: frame)
    previewView.isUserInteractionEnabled = false
    previewView.isAccessibilityElement = false
    super.init()
    controller.attachPreview(previewView.previewLayer)
  }

  func view() -> UIView {
    previewView
  }
}

final class PreviewView: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }
}
